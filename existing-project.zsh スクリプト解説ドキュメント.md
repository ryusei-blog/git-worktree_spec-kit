---
date_created: 2025-11-04
date_modified: 2025-11-04
version: 1.0.0
---
# `existing-project.zsh` スクリプト解説ドキュメント

このドキュメントは、既存プロジェクト用スクリプト `existing-project.zsh` の役割と処理の流れを整理したものです。

目的は「**既存ディレクトリ（既にあるプロジェクト）を git worktree + spec-kit 構造へ安全に移行する**」ことです。

## スクリプトの前提とゴール

### 前提

- 実行時点でのカレントディレクトリ（`pwd`）が「対象の既存プロジェクトのルート」であること。
- そのディレクトリは **git 管理されていても、いなくても良い**。

### ゴール

最終的なディレクトリツリーは、新規プロジェクト版と同じ構造になります。

```text
project-root/   # ここで existing-project.zsh を実行
  .git/
  .gitignore
  worktrees/
    main/
      .git
      .gitignore
      .codex/
      .specify/
      ...（既存プロジェクトの中身 + spec-kit一式）
  README.hub.md
```

- 元々のプロジェクトの中身は `worktrees/main` 配下に完全移行。
- ルートは `.git/` と `worktrees/`、`README.hub.md` を持つ「ハブ」になる。

## サンドボックス構造

新規版と同様に、全体は `main()` で包まれ、サブシェルから実行されます。

```zsh
main() {
    set -euo pipefail
    # 本処理…
}

( main ) || true
```

- `set -euo pipefail` による厳しめのエラーハンドリングは `main()` 内だけ。
- `( main )` によって、親 zsh には影響しない子プロセス内で完結。
- エラーが起きても `|| true` により、親の対話シェルは終了しない。

## 処理フロー詳細

### 1. 定数定義

```zsh
readonly TARGET_BRANCH="main"
readonly WORKTREE_ROOT="worktrees"
readonly WORKTREE_PATH="${WORKTREE_ROOT}/${TARGET_BRANCH}"
readonly SPEC_KIT_SOURCE="git+https://github.com/github/spec-kit.git"
```

- `TARGET_BRANCH` は永続的に運用するブランチ名（ここでは `main`）。
- `WORKTREE_ROOT` は worktree を格納するトップディレクトリ名。
- `WORKTREE_PATH` は最終的な作業ブランチのパス（例：`worktrees/main`）。
- `SPEC_KIT_SOURCE` は specify CLI の取得元リポジトリ。

### 2. Git 管理状態に応じた初期処理

```zsh
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Not a git repository yet: initialize and capture the current project state
    git init -b "${TARGET_BRANCH}"

    # Ensure there is at least an empty .gitignore so the final hub structure matches expectations
    if [ ! -f .gitignore ]; then
        touch .gitignore
    fi

    git add .
    git commit -m "chore: init repository before introducing git worktree"
else
    # Already inside a git repository: record a snapshot before restructuring
    git add .
    git commit -m "chore: before introducing git worktree" || echo "no changes to commit"

    # Ensure the target branch exists; prefer origin/${TARGET_BRANCH} when available
    if ! git show-ref --verify --quiet "refs/heads/${TARGET_BRANCH}"; then
        if git show-ref --verify --quiet "refs/remotes/origin/${TARGET_BRANCH}"; then
            git branch "${TARGET_BRANCH}" "origin/${TARGET_BRANCH}"
        else
            git branch "${TARGET_BRANCH}"
        fi
    fi
fi
```

#### ケースA：まだ git 管理されていない既存プロジェクト

- `git rev-parse` がエラーになるので「非 git」と判定。
- `git init -b main` でカレントディレクトリを git 化。
- `.gitignore` がなければ作成。
- `git add .` → `git commit` で、現在のディレクトリ状態を 1 コミットとして保存。

#### ケースB：既に git 管理されている既存プロジェクト

- `git add .` → `git commit -m "chore: before introducing git worktree"` で、移行前スナップショットを残す。
- `main` ブランチが存在しない場合は作成。
  - `origin/main` があればそこからブランチを切る。
  - 無ければ現在の HEAD から `main` を作る。

こうして「既存プロジェクトの現在状態を main ブランチに記録した上で、worktree 化」に移行する。

### 3. ハブ構造の導入と worktree 追加

```zsh
echo "# hub" > README.hub.md
git checkout --detach
mkdir -p "${WORKTREE_ROOT}"
git worktree add "${WORKTREE_PATH}" "${TARGET_BRANCH}"
```

- ルートに `README.hub.md` を作成。
- `git checkout --detach` で、ルート側の HEAD をブランチから切り離す。
- `git worktree add worktrees/main main` により `worktrees/main` に main ブランチを展開。

ここで実装ブランチの実体は `worktrees/main` 側へ移動することになる。

### 4. ルートからのファイル移行（実質的な「完全移動」）

```zsh
find . -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    ! -name '.gitignore' \
    ! -name "${WORKTREE_ROOT}" \
    ! -name 'README.hub.md' \
    -exec rm -rf {} +
```

- ルート直下の
  - `.git/`
  - `.gitignore`
  - `worktrees/`
  - `README.hub.md`  
  以外のものをすべて削除。

重要なのは、この削除が行われる前に

- もともとのプロジェクト内容は `git init` と `git commit` で main に記録されており、
- `git worktree add worktrees/main main` によって **`worktrees/main` 側に完全復元されている**

という点。

結果として、「ルートからファイルを消しても worktrees/main 側にその完全コピーが残る」構造になる。

### 5. spec-kit 環境構築

```zsh
cd "${WORKTREE_PATH}"
uv tool install specify-cli --from "${SPEC_KIT_SOURCE}" --force
yes | specify init . --ai codex
```

- `cd worktrees/main` で main ワークツリーに移動。
- `uv tool install` で specify CLI を最新の spec-kit リポジトリから取得。
- `yes | specify init . --ai codex` で spec-kit テンプレートを一括初期化。

これにより `worktrees/main` には

- `.codex/`
- `.specify/`
- 各種 spec / 設定ファイル

が自動生成される。

## 対話シェル起動ロジック

`existing-project.zsh` でも、新規版と同じ対話シェル制御ロジックを採用している。

```zsh
shell_mode="${NEW_PROJECT_TYPE_SHELL_MODE:-child}"  # child|exec|none

if [ "${NEW_PROJECT_TYPE_NO_SHELL:-0}" != "1" ] && [ "$shell_mode" != "none" ]; then
    if [ -t 0 ] && [ -t 1 ]; then
        if [ "$shell_mode" = "exec" ]; then
            exec "${SHELL:-/bin/zsh}" -il
        else
            "${SHELL:-/bin/zsh}" -il || true
        fi
    elif [ -e /dev/tty ]; then
        if [ "$shell_mode" = "exec" ]; then
            exec "${SHELL:-/bin/zsh}" -il </dev/tty >/dev/tty 2>/dev/tty
        else
            "${SHELL:-/bin/zsh}" -il </dev/tty >/dev/tty 2>/dev/tty || true
        fi
    else
        echo "TTYが検出できないため対話シェルをスキップします。" >&2
    fi
fi
```

- 環境変数の意味は新規版と共通。
- 既存プロジェクト用でも、
  - スクリプト実行後にそのまま対話シェルで作業を続ける
  - あるいは一切対話シェルを開かない  
  といった制御が可能。

## 想定される実行パターン

### 既存プロジェクトへの適用（標準パターン）

```zsh
cd /path/to/existing/project
zsh /path/to/existing-project.zsh
```

- git 未管理なら `git init -b main` から自動で始まる。
- git 管理済みなら、作業前の状態を 1 コミット残してから worktree 化。
- 最終的に、ルートはハブ、`worktrees/main` は実作業＋spec-kit という構造に再編される。

### 対話シェルを開きたくない場合

```zsh
NEW_PROJECT_TYPE_NO_SHELL=1 zsh /path/to/existing-project.zsh
```