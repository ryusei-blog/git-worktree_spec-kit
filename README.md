---
date_created: 2025-11-04
date_modified: 2025-11-04
version: 1.0.0
---
# git-worktree & spec-kit 導入手順

このリポジトリは、**既存または新規のプロジェクトを「git worktree」＋「spec-kit」構成で立ち上げるためのZshスクリプト集**です。

Codex CLIを中心に、Spec Driven Development（仕様駆動開発）環境を最短で構築できるよう設計されています。

## git worktreeとは

**git worktree** は、1つのリポジトリで複数のワークディレクトリを持つ仕組みです。

これにより「ブランチごとに別ディレクトリで作業」が可能となり、メインブランチと開発ブランチを同時にローカルで展開できます。

この構成では以下のような階層構造が作成されます：

```
ルート（デタッチドヘッド）
├── .git/
├── .gitignore
├── worktrees/
│   └── main/
│       ├── .specify/
│       ├── .codex/
│       └── README.md
└── README.hub.md
```

ルートは**ハブ（hub）**として機能し、`worktrees/main` が **mainブランチの本体**です。

## spec-kitとは（Spec Driven Development）

**spec-kit** は GitHub が提供する CLI ツールで、「仕様（Spec）」を中心に据えた開発手法 **Spec Driven Development (SDD)** を実現する環境を自動生成します。  

`specify init` コマンドを通じて、リポジトリに以下の構造を生成します：

```
.specify/
  ├── specs/
  ├── plans/
  ├── tasks/
  └── memory/
.codex/ # Codexの場合
  └── prompts/
```

これにより、AIコーディングエージェント（Codex CLIやClaude Codeなど）が「仕様→設計→実装」という一貫した開発サイクルを実現できます。

## Codex CLIを基準とした構築

本スクリプトは **OpenAI Codex CLI** を基準に構築されています。

spec-kit初期化時には以下の指定を行います：

```bash
yes | specify init . --ai codex
```

もし **Gemini CLI** や **Claude Code** を使用する場合は、上記の `--ai codex` 部分をそれぞれのCLI名に書き換えてください。

例：
```bash
yes | specify init . --ai gemini
```
または
```bash
yes | specify init . --ai claude
```

## 実行方法（必ずファイル経由で実行）

このスクリプトは直接ターミナルに貼り付けて実行すると、**デタッチドヘッド状態やシェルの継続処理が正しく機能しない恐れがあります。**

そのため、次の手順で実行してください：

1. 当リポジトリをクローン：  
   ```bash
   git clone https://github.com/yourname/git-worktree_spec-kit.git
   cd git-worktree_spec-kit
   ```

2. 実行対象のスクリプトを指定して実行：  
   ```bash
   zsh /Users/あなたのパス/Documents/GitHub/git-worktree_spec-kit/new-project-type.zsh
   ```
   または  
   ```bash
   zsh /Users/あなたのパス/Documents/GitHub/git-worktree_spec-kit/existing-project.zsh
   ```

※「直接貼り付け実行」は避け、**必ずファイルパスで指定**してください。

## new-project-type.zsh

新規プロジェクトを立ち上げるためのスクリプトです。

GitHubリポジトリを自動作成し、`git worktree` + `spec-kit`構成を初期化します。

主な処理フロー：
1. 新規リポジトリの作成（gh CLI経由）
2. .gitignore / README.hub.md の初期コミット
3. mainブランチをworktrees/mainへ移管
4. specify CLIでspec-kitを初期化
5. git add → commit → pushでリモートと同期
6. zsh対話モード継続（終了しない）

実行結果：
- GitHub上に新規リポジトリが作成される
- `worktrees/main` 配下にspec-kit環境が構築される
- ローカルではデタッチドヘッドのハブ構造が生成される

## existing-project.zsh

既存のローカルプロジェクトを **git worktree化 + spec-kit対応** させるスクリプトです。

既存ファイルをすべて `worktrees/main` に移管した上で、spec-kitを導入します。

主な処理フロー：
1. 既存プロジェクトのmainブランチをコミット
2. デタッチドヘッド化（ルートをハブに）
3. worktrees/mainとしてmainブランチを展開
4. specify CLIでspec-kitを導入
5. git add → commit → pushでリモート反映

実行結果：
- 既存の全ファイルが `worktrees/main` に移動
- `.specify`・`.codex` が追加され、リモートに完全反映
- ルート側には `.git/`, `.gitignore`, `worktrees/`, `README.hub.md` のみが残る

## 推奨開発構成

| レイヤー | 役割 | 追跡 |
| --- | --- | --- |
| ルート（detached HEAD） | hub管理層（ワークツリー統括） | 一部追跡外 |
| worktrees/main | mainブランチ実体（spec-kit開発環境） | Git管理対象 |
| GitHub | リモート同期（spec-kit成果共有） | 自動反映 |

## ライセンス

MIT License  
© 2025 FreedomBuild