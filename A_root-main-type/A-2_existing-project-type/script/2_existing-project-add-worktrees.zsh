# フェーズ2：spec-kit完成後にgit worktree導入
main_phase2() {
  set -euo pipefail

  readonly WORKTREE_ROOT="worktrees"

  # --- 派生ブランチ作成 ---
  mkdir -p "${WORKTREE_ROOT}"
  git pull origin main
  git worktree add -b dev "${WORKTREE_ROOT}/dev"
  cd "${WORKTREE_ROOT}/dev"
  git push -u origin dev || true

  echo "✅ フェーズ②完了：worktrees/dev を作成しました。mainのspec-kitをベースに開発を開始できます。"
}

( main_phase2 ) || true