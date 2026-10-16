#!/usr/bin/env bash
# Tests for install.sh. Each case runs this checkout's installer against a
# throwaway HOME and project directory. Menus are driven through a
# pseudo-terminal, because the installer reads its answers from /dev/tty.
#
#   tests/install_test.sh            every case
#   tests/install_test.sh scope      cases whose name contains "scope"
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
installer="$here/../install.sh"
skill_count="$(ls -d "$here"/../skills/*/ | wc -l | tr -d ' ')"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# A fresh HOME, project directory and PATH for one case. PATH holds the
# system tools plus $FAKEBIN, where a case puts fake agent binaries.
fresh() {
  CASE="$(mktemp -d "$scratch/case.XXXXXX")"
  HOME="$CASE/home"; PROJECT="$CASE/project"; FAKEBIN="$CASE/bin"; OUT="$CASE/out"
  mkdir -p "$HOME" "$PROJECT" "$FAKEBIN"
  export HOME PATH="$FAKEBIN:/usr/bin:/bin"
}

fake_agent() { printf '#!/bin/sh\n' > "$FAKEBIN/$1"; chmod +x "$FAKEBIN/$1"; }

on_tty() {
  if script --version >/dev/null 2>&1; then
    script -qec "$(printf '%q ' "$@")" /dev/null   # util-linux
  else
    script -q /dev/null "$@"                       # BSD / macOS
  fi
}

# Runs install.sh from $PROJECT on a pseudo-terminal and types $1 once it
# has started — the pty drops keys sent before that. Output to $OUT.
tty_run() {
  local keys="$1"; shift
  { sleep 0.5; printf '%b' "$keys"; sleep 1; } \
    | (cd "$PROJECT" && on_tty bash "$installer" "$@") 2>&1 | tr -d '\r' > "$OUT"
  STATUS="${PIPESTATUS[1]}"
}

# Runs install.sh from $PROJECT with no terminal at all.
plain_run() { (cd "$PROJECT" && bash "$installer" "$@" </dev/null) > "$OUT" 2>&1; STATUS=$?; }

fail()      { printf '  FAIL %s: %s\n' "$NAME" "$1"; FAILED=1; }
saw()       { grep -qF -- "$1" "$OUT" || fail "output lacks: $1"; }
not_saw()   { ! grep -qF -- "$1" "$OUT" || fail "output has: $1"; }
exists()    { [ -e "$1" ] || fail "missing: $1"; }
absent()    { [ ! -e "$1" ] || fail "should not exist: $1"; }
status_is() { [ "$STATUS" = "$1" ] || fail "exit status $STATUS, expected $1"; }

# --- scope menu -------------------------------------------------------------

test_scope_empty_answer_is_global() {
  tty_run '\n' --agents claude --yes
  saw "Choose 1 or 2, or type a project path [1]:"
  exists "$HOME/.claude/skills/dev-debug"
  absent "$PROJECT/.claude"
}

test_scope_p_is_project() {
  tty_run 'p\n' --agents claude --yes
  exists "$PROJECT/.claude/skills/dev-debug"
  absent "$HOME/.claude"
}

test_scope_invalid_answer_asks_again() {
  tty_run '3\n2\n' --agents claude --yes
  saw "not a choice or an existing directory: 3"
  exists "$PROJECT/.claude/skills/dev-debug"
}

test_scope_typed_path_is_project() {
  mkdir "$CASE/other"
  tty_run "$CASE/other\\n" --agents claude --yes
  exists "$CASE/other/.claude/skills/dev-debug"
}

test_scope_word_global_is_global() {
  tty_run 'global\n' --agents claude --yes
  exists "$HOME/.claude/skills/dev-debug"
}

test_scope_word_project_is_project() {
  tty_run 'project\n' --agents claude --yes
  exists "$PROJECT/.claude/skills/dev-debug"
}

test_scope_typed_file_asks_again() {
  touch "$CASE/file"
  tty_run "$CASE/file\\n2\\n" --agents claude --yes
  saw "not a choice or an existing directory: $CASE/file"
  exists "$PROJECT/.claude/skills/dev-debug"
}

test_scope_tilde_path_expands() {
  mkdir "$HOME/proj"
  tty_run '~/proj\n' --agents claude --yes
  exists "$HOME/proj/.claude/skills/dev-debug"
}

test_scope_home_refuses_project() {
  PROJECT="$HOME"
  tty_run '2\n\n' --agents claude --yes
  saw "2) Project — not offered from your home directory; type a project path"
  saw "Choose 1, or type a project path [1]:"
  saw "a project install needs a project directory"
  exists "$HOME/.claude/CLAUDE.md"
  absent "$HOME/CLAUDE.md"
}

test_scope_notes_repo_root() {
  git -C "$PROJECT" init -q
  tty_run '1\n' --agents claude --yes
  saw "(git repository)"
}

test_scope_notes_repo_subdir() {
  git -C "$PROJECT" init -q
  mkdir "$PROJECT/sub"; PROJECT="$PROJECT/sub"
  tty_run '1\n' --agents claude --yes
  saw "(inside git repository "
}

test_scope_notes_not_a_repo() {
  tty_run '1\n' --agents claude --yes
  saw "(! not a git repository)"
}

# --- runner -----------------------------------------------------------------

failures=0
for NAME in $(declare -F | awk '{print $3}' | grep '^test_' | grep -- "${1:-}"); do
  FAILED=0
  fresh
  "$NAME"
  if [ "$FAILED" = 1 ]; then
    failures=$((failures + 1))
    sed 's/^/    | /' "$OUT" 2>/dev/null
  else
    printf '  ok   %s\n' "$NAME"
  fi
done
if [ "$failures" = 0 ]; then echo "all passed"; else echo "$failures failed"; exit 1; fi
