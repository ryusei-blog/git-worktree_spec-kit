---
date_created: 2025-11-04
date_modified: 2025-11-04
version: 1.0.0
---
# `new-project-type.zsh` スクリプト解説ドキュメント

このドキュメントは、新規プロジェクト用スクリプト `new-project-type.zsh` の役割と処理の流れを整理したものです。

目的は「**まっさらな新規リポジトリを作り、git worktree + spec-kit 環境を一発構築する**」ことです。

## スクリプトのゴール

このスクリプトを実行すると、以下のような GitHub 連携済みの新規リポジトリが完成します。

- GitHub 上に新規リポジトリ作成
- ローカルに `hub`（ルート）＋ `worktrees/main`（実開発用）という 2 層構造
- `worktrees/main` 配下に以下を含む spec-kit 環境が構築される。
  - `.codex/`
  - `.specify/`
  - `.git`（worktree 用メタデータ）
  - `.gitignore` など

ルートディレクトリの最終構造イメージは次のとおり。

```text
repo-root/
  .git/
  .gitignore
  worktrees/
    main/
      .git
      .gitignore
      .codex/
      .specify/
      ...（spec-kit が生成したファイル群）
  README.hub.md
```

## 全体構造とサンドボックス設計

スクリプトは `main()` 関数に閉じ込められ、最後にサブシェルから実行されます。

```zsh
main() {
    set -euo pipefail
    # 本処理…
}

( main ) || true  # サブシェル内で処理完結し、エラーがあっても親シェルは終了しないようにする
```

- `set -euo pipefail` は **`main()` の中だけで有効**。
- `( main )` によって **サブシェル（子プロセス）内で処理**が完結。
- `|| true` により、途中でエラーが出ても呼び出し元の対話シェル（親 zsh）は終了しない。

これにより、ターミナルに貼り付けて実行したり、`zsh ./new-project-type.zsh` で実行しても、**「終わったあとにプロンプトが生きている」ことが保証されます。**

## 処理フロー詳細

### 1. 作業ベースディレクトリへの移動

```zsh
cd ~/Documents/GitHub
repo="{{repo-name}}" && mkdir "$repo" && cd "$repo"
```

- 新規リポジトリは `~/Documents/GitHub` 配下に作成する前提。
- `repo` 変数にリポジトリ名を格納し、その名前でディレクトリを作成した上で移動。

※ 実際に利用する際は `repo="{{repo-name}}"` 部分を任意のリポジトリ名に変更することを想定。

### 2. ローカル git リポジトリ初期化

```zsh
git init -b main
touch .gitignore
git add .gitignore
git commit -m "chore: init repository with .gitignore"
git branch -M main
```

- `git init -b main` で main ブランチをルートとした Git リポジトリを作成。
- ひとまず空の `.gitignore` を作成し、初期コミットとして記録。
- `git branch -M main` でブランチ名を `main` に強制統一。

ここまでで、ローカルには単純な Git リポジトリが存在する状態になる。

### 3. GitHub リポジトリ作成と接続

```zsh
gh repo create "$repo" --private --source=. --remote=origin
```

- GitHub CLI（`gh`）を利用して、GitHub 上に新規リポジトリを作成。
- `--source=.` により、カレントディレクトリの内容が GitHub リポジトリの初期内容になる。
- `--remote=origin` でリモート名 `origin` を自動設定。

この時点で「ローカルと GitHub が main ブランチで接続された初期状態」が完成する。

### 4. hub 構造の準備

```zsh
echo "# hub" > README.hub.md
git checkout --detach
mkdir -p worktrees
git worktree add worktrees/main main
```

- ルートに `README.hub.md` を作成。ここは「ハブ」としての説明やリンク集を置く想定。
- `git checkout --detach` によってルートはブランチから切り離された状態になる。
- `git worktree add worktrees/main main` により、`worktrees/main` に main ブランチをチェックアウト。
  - 実際の開発は `worktrees/main` 側で行う。
  - ルート側は `.git/`＋`README.hub.md`＋`worktrees/` のみを持つハブ的な存在になる。

### 5. ルートの整理（main の完全移行）

```zsh
find . -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    ! -name '.gitignore' \
    ! -name 'worktrees' \
    ! -name 'README.hub.md' \
    -exec rm -rf {} +
```

- ルート直下に存在する
  - `.git/`
  - `.gitignore`
  - `worktrees/`
  - `README.hub.md`  
  以外のものをすべて削除。
- 結果として、ルートには「ハブとして必要な最小構成」だけが残り、**アプリ本体は `worktrees/main` に完全移行**する。

### 6. spec-kit（specify）環境構築と初期プッシュ

```zsh
cd worktrees/main
echo "# ${repo}" > README.md
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --force
yes | specify init . --ai codex
git add .
git commit -m "chore: init specify environment"
git push origin main
```

- `cd worktrees/main` で実開発側のワークツリーに移動。
- `echo "# ${repo}" > README.md` でリポジトリ名をタイトルにした README.md を作成。
- `uv tool install` により、`specify-cli`（spec-kit）を GitHub の公式リポジトリから取得。
- `yes | specify init . --ai codex` で対話質問をすべて肯定し、`codex` 前提の spec-kit テンプレートを一括構築。
  - `.specify/`
  - `.codex/`
  - 各種 config / spec ファイル群  
  が `worktrees/main` 配下に生成される。
- その後、変更をコミットし、`git push origin main` で初回プッシュを行う。

## 対話シェル起動ロジック

```zsh
shell_mode="${NEW_PROJECT_TYPE_SHELL_MODE:-child}"  # child|exec|none

if [ "${NEW_PROJECT_TYPE_NO_SHELL:-0}" != "1" ] && [ "$shell_mode" != "none" ]; then
    # まず標準入力・出力が TTY かを判定し、対話シェルを起動
    if [ -t 0 ] && [ -t 1 ]; then
        if [ "$shell_mode" = "exec" ]; then
            exec "${SHELL:-/bin/zsh}" -il
        else
            "${SHELL:-/bin/zsh}" -il || true
        fi
    # 標準入出力が TTY でない場合は /dev/tty にフォールバックして対話シェルを起動
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

### 環境変数によるモード制御

- `NEW_PROJECT_TYPE_NO_SHELL`
  - `1` なら対話シェル起動をスキップ。
- `NEW_PROJECT_TYPE_SHELL_MODE`
  - `child`（デフォルト）
    - 子シェルとして `zsh -il` を起動し、`exit` すると親に戻る。
  - `exec`
    - `exec zsh -il` でプロセスを置き換える。
    - Finder や Automator から起動した場合など「このウィンドウを対話 zsh にしたい」ケースで使う想定。
  - `none`
    - どのケースでもシェルを起動しない。

### TTY 判定とフォールバックのポイント

- 標準入力・出力が TTY ならそれを使って対話シェルを起動。
- そうでない場合でも `/dev/tty` が存在すれば、そこを使って対話シェルを起動。
- これにより、Codex CLI などの疑似 TTY 環境でも対話シェルを維持しやすい設計。

基本運用としては、何も指定せずに `child` モードで使うのが安全。

## 想定される実行パターンまとめ

### 通常の新規プロジェクト作成

```zsh
zsh /path/to/new-project-type.zsh
```

- `~/Documents/GitHub` に新しいリポジトリができ、
- GitHub 作成、worktree 化、spec-kit 構築、初回プッシュまで自動で完了。

### スクリプト後に対話シェルを開きたくない場合

```zsh
NEW_PROJECT_TYPE_NO_SHELL=1 zsh /path/to/new-project-type.zsh
```