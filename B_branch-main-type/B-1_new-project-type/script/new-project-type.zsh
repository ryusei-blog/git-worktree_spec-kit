main() {
  set -euo pipefail

  repo="${1:-my-new-repo}" && mkdir "$repo" && cd "$repo"
  git init -b main
  touch .gitignore
  git add .gitignore
  git commit -m "chore: init repository with .gitignore"
  git branch -M main
  gh repo create "$repo" --private --source=. --remote=origin
  git checkout --detach
  echo "# hub" > README.hub.md
  mkdir -p worktrees
  git worktree add worktrees/main main
  find . -mindepth 1 -maxdepth 1 \
    ! -name '.git' \
    ! -name '.gitignore' \
    ! -name 'worktrees' \
    ! -name 'README.hub.md' \
    -exec rm -rf {} +
  cd worktrees/main
  echo "# ${repo}" > README.md
  uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --force
  yes | specify init . --ai codex
  git add . && \
  git commit -m "chore: initialize spec-kit environment" && \
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
}  # end of main

# Run inside a subshell so `set -euo pipefail` and any non-zero statuses never kill the parent interactive shell.
( main "$@" ) || true