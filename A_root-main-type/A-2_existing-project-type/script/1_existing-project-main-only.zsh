# フェーズ1：ルートmainにspec-kitを構築
main_phase1() {
  set -euo pipefail

  readonly TARGET_BRANCH="main"
  readonly SPEC_KIT_SOURCE="git+https://github.com/github/spec-kit.git"

  # --- Gitリポジトリ初期化または更新 ---
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init -b "${TARGET_BRANCH}"
    [ -f .gitignore ] || touch .gitignore
    git add .
    git commit -m "chore: init repository for spec-kit setup"
  else
    git add .
    git commit -m "chore: prepare for spec-kit setup" || echo "no changes to commit"

    # mainブランチ存在確認
    if ! git show-ref --verify --quiet "refs/heads/${TARGET_BRANCH}"; then
      if git show-ref --verify --quiet "refs/remotes/origin/${TARGET_BRANCH}"; then
        git branch "${TARGET_BRANCH}" "origin/${TARGET_BRANCH}"
      else
        git branch "${TARGET_BRANCH}"
      fi
    fi
  fi

  # --- spec-kitをルート(main)で構築 ---
  uv tool install specify-cli --from "${SPEC_KIT_SOURCE}" --force
  yes | specify init . --ai codex
  git add .
  git commit -m "chore: setup main (spec-kit initialized)"
  git push origin main

  echo "✅ フェーズ①完了：ルートmainにspec-kitを構築しました。"
}

( main_phase1 "$@" ) || true