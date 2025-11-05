# --- フェーズ2：完成したmainからworktreeを追加 ---
main_phase2() {
  set -euo pipefail

  branch_name="${1:-dev}"

  mkdir -p worktrees
  git pull origin main
  git worktree add -b "$branch_name" "worktrees/$branch_name"
  cd "worktrees/$branch_name"
  git push -u origin "$branch_name" || true

  echo "✅ フェーズ2完了：mainをベースに worktrees/$branch_name が生成されました。"
}

( main_phase2 "$@" ) || true