main() {
  set -euo pipefail

  readonly TARGET_BRANCH="main"
  readonly WORKTREE_ROOT="worktrees"
  readonly WORKTREE_PATH="${WORKTREE_ROOT}/${TARGET_BRANCH}"
  readonly SPEC_KIT_SOURCE="git+https://github.com/github/spec-kit.git"

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

  echo "# hub" > README.hub.md
  git checkout --detach
  mkdir -p "${WORKTREE_ROOT}"
  git worktree add "${WORKTREE_PATH}" "${TARGET_BRANCH}"
  find . -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    ! -name '.gitignore' \
    ! -name "${WORKTREE_ROOT}" \
    ! -name 'README.hub.md' \
    -exec rm -rf {} +
  cd "${WORKTREE_PATH}"
  uv tool install specify-cli --from "${SPEC_KIT_SOURCE}" --force
  yes | specify init . --ai codex
  git add . && \
  git commit -m "setup: git worktree & spec-kit" && \
  git push origin main

  shell_mode="${NEW_PROJECT_TYPE_SHELL_MODE:-child}"  # child|exec|none

  if [ "${NEW_PROJECT_TYPE_NO_SHELL:-0}" != "1" ] && [ "$shell_mode" != "none" ]; then
    # Prefer the current TTY, but fall back to /dev/tty so Codex CLIなどの疑似TTYでも継続操作できる
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
}

# Run inside a subshell so `set -euo pipefail` and any non-zero statuses never kill the parent interactive shell.
( main "$@" ) || true