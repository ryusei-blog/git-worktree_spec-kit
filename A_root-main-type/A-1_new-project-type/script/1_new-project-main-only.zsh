# --- フェーズ1：ルートmainとspec-kit構築まで ---
main_phase1() {
  set -euo pipefail

  cd ~/Documents/GitHub
  repo="${1:-my-new-repo}" && mkdir "$repo" && cd "$repo"

  # --- initialize repo on main at root (no detached HEAD) ---
  git init -b main
  : > .gitignore
  git add .gitignore
  git commit -m "chore: init repository with .gitignore"
  git branch -M main
  gh repo create "$repo" --private --source=. --remote=origin

  # --- build spec-kit on root main ---
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --force
  yes | specify init . --ai codex
  git add .
  git commit -m "chore: setup main (spec-kit initialized)"
  git push origin main

  echo "✅ フェーズ1完了：spec-kit構築済みのmainが作成されました。次にフェーズ2でworktreeを追加します。"
}

main_phase1 "$@"