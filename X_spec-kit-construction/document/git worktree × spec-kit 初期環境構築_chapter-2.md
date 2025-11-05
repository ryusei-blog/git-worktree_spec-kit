---
date_created: 2025-10-31
date_modified: 2025-10-31
version: 1.0.0
---
# Codex向けspec-kit運用ガイド

このドキュメントは、既定のspec-kit環境セットアップ直後に、ユーザーがCodexへどのような指示を与えれば実プロジェクト仕様へ最適化できるかを整理したものです。

各コマンドは`.codex/prompts`および`.specify/scripts`に定義されたワークフローを前提としており、指示は常に安全性・セキュリティを最優先に行ってください。

## 基本方針

- 仕様資産（spec.md、plan.md、tasks.md等）はすべて`check-prerequisites.sh`で前提確認を行ってから更新する。
- 憲法（`.specify/memory/constitution.md`）を必ず実プロジェクト向けに先に埋め、後続コマンドが評価できる状態にする。
- 各フェーズで「未実装」「近日追加」などのMVPラベルを明示し、事前検死として想定失敗パターンを必ず列挙する。
- MarkdownやテンプレートはYAMLフロントマターと各種命名規約を厳守し、i18nやアクセシビリティ要件を早期に洗い出す。

## 指示フロー

1. **初期整備（手動）**
   - 必要なプロジェクト原則を憲法ファイルに反映し、バージョン・発効日をセット。
   - テンプレートに欠けている研究・データモデルなどの骨子を事前に用意する場合は、Codexへ補完作業を依頼。

2. **仕様生成 `/speckit.specify`**
   - ユーザー: 機能要件や背景を自然言語で提示し、Codexに`/speckit.specify "<機能説明>"`実行を指示。
   - Codex: フロントマターを含めたspec.mdを作成し、最大3件までの`[NEEDS CLARIFICATION]`を残す場合は論点を明示。
   - ユーザー: 出力されたspec.mdをレビューし、未明確な点を回答または追記依頼。

3. **チェックリスト生成 `/speckit.checklist`（任意推奨）**
   - ユーザー: 要件品質確認の観点を伝え、Codexにチェックリスト生成を指示。
   - Codex: 要件の抜け／曖昧さを検出するチェック項目を作成し、gap表示で事前検死材料を提供。

4. **不明点解消 `/speckit.clarify`**
   - ユーザー: Clarify用の回答を用意し、Codexへ`/speckit.clarify`でspecを最新化するよう依頼。
   - Codex: 指定回答をspec.mdへ反映し、チェックリストを再評価して整合性を報告。

5. **計画立案 `/speckit.plan`**
   - ユーザー: 実装技術スタックの制約や優先度を指示しつつ、Codexにプラン生成を依頼。
   - Codex: `setup-plan.sh --json`を経由し、research.md・data-model.md・contracts/・quickstart.mdを生成。技術選定理由と未解決事項を明確化し、事前検死としてリスク一覧を記載。
   - ユーザー: 研究結果やモデルの妥当性を点検し、追加調査が必要な場合は再度Codexへ調整指示。

6. **タスク分解 `/speckit.tasks`**
   - ユーザー: 優先ユーザーストーリーや並列化可否などを伝え、Codexにタスク分解を実施させる。
   - Codex: User Storyごとに独立検証可能なタスク群を列挙し、未実装要素は「近日追加」「準備中」で明示。
   - ユーザー: タスクカバレッジを確認し、抜けている要求に対しspecやplanの更新をフィードバック。

7. **整合性検査 `/speckit.analyze`**
   - ユーザー: spec/plan/tasksの整合性診断を指示。
   - Codex: 重複・曖昧さ・憲法違反を報告し、クリティカル項目がある場合は実装前に是正指針を提示。

8. **事前検死の深化**
   - ユーザー: 重要機能ごとに想定失敗シナリオを列挙し、Codexにタスクまたはspecへ反映させる。
   - Codex: チェックリストやタスクリストにフォールバックや監視要件を追記し、失敗検知と回復手順を明文化。

9. **実装フェーズへの引き継ぎ**
   - ユーザー: Codexへ実装MVPの範囲・未実装の表現方法（例: バッジ表示）を再確認させる。
   - Codex: 実装開始前に最新spec/plan/tasksのバージョンを告知し、必要なテスト戦略（Vitest/Playwrightなど）を提案。

10. **変更管理と更新**
    - 各コマンドの実行後、Codexへ`git status`確認・差分レビューを依頼し、必要なコミットメッセージ案を受け取る。
    - Markdown・YAMLは最新日付で`date_modified`を更新し、テンプレート違反や未定義ラベルがあれば即修正を指示。

### テンプレートプロンプト

テンプレートプロンプト生成ツール：[spec-kit-prompt-create.html](spec-kit-prompt-create.html)

````markdown
# {{PROJECT_NAME}} spec-kit最終化リクエスト

## コンテキスト

- 既にベースspec-kitは初期構築済みである。
- 作業対象ワークツリー: {{WORKTREE_PATH}}
- プロジェクト概要: {{PROJECT_OBJECTIVE}}
- 関係者/ステークホルダー: {{STAKEHOLDERS}}

## 参照資料

- 憲法: `.specify/memory/constitution.md`（{{CONSTITUTION_STATUS}}）
- 仕様: `specs/{{FEATURE_KEY}}/spec.md`
- 計画: `specs/{{FEATURE_KEY}}/plan.md`
- タスク: `specs/{{FEATURE_KEY}}/tasks.md`
- 追加ドキュメント: {{ADDITIONAL_DOCS}}

## 期待成果

- ガバナンス・リスク・事前検死を反映した最新spec/plan/tasks。
- 未実装領域を「近日追加」「準備中」等で明示。
- 更新ファイルの`date_modified`と推奨コミットメッセージ案。

## 実行シナリオ

1. `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` を実行し、解析結果を共有。
2. 憲法の未入力箇所を {{CONSTITUTION_UPDATES}} で更新。
3. `/speckit.specify "{{FEATURE_DESCRIPTION}}"` を再実行して仕様を確定。
4. 必要に応じて `/speckit.checklist "{{CHECKLIST_FOCUS}}"` で要件品質を検証。
5. `/speckit.clarify` で `[NEEDS CLARIFICATION]` を解消。
6. `/speckit.plan "{{PLAN_CONTEXT}}"` で research/data-model/contracts/quickstart を更新。
7. `/speckit.tasks "{{TASKS_CONTEXT}}"` でMVP・予定機能タスクを再編。
8. `/speckit.analyze` で整合性レポートを取得し、クリティカル対応策を提示。
9. `git status` と主要差分、推奨テストコマンド、コミットメッセージ案を報告。

## レポート必須項目

- 各ステップの変更ファイルと`date_modified`更新状況。
- 事前検死で判明した失敗パターンと回避策の箇条書き。
- 未対応事項の次アクションまたは期限提案。

## 技術・要件パラメータ

- 使用スタック: {{STACK_DECISIONS}}
- 非機能要件: {{NFR_REQUIREMENTS}}
- セキュリティ/コンプライアンス: {{SECURITY_REQUIREMENTS}}
- UX・アクセシビリティ: {{UX_A11Y_REQUIREMENTS}}
- カスタム指示: {{CUSTOM_NOTES}}

## 基本コマンド

```bash
.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks

# 必要に応じて手動編集を宣言する際の例:
# 「specs/{{FEATURE_KEY}}/spec.mdの<セクション>を明示的に修正」
```

## 成果物サマリテンプレート

```text
### 実装済み機能

- ...

### 予定機能（近日追加）

- ...

### 事前検死ログ

- 失敗パターン: ...
- 回避策: ...

### 推奨コミット

- メッセージ案: ...
```
````

> プレースホルダー`{{...}}`に具体値を代入してからCodexへ送信してください。

## まとめ

- 憲法とテンプレートを先に実プロジェクト仕様へ整備することで、後続コマンドの自動判定が有効に働きます。
- `/speckit.specify → checklist → clarify → plan → tasks → analyze`の順に段階指示すると、要求→設計→実装準備を安全に収束できます。
- 各フェーズで事前検死を明文化し、未実装領域は必ず「近日追加」などで可視化することで、MVPの境界が明確になります。