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

test_scope_typed_path_ignores_cdpath() {
  mkdir -p "$PROJECT/proj" "$CASE/elsewhere/proj"
  CDPATH="$CASE/elsewhere" tty_run 'proj\n' --agents claude --yes
  exists "$PROJECT/proj/.claude/skills/dev-debug"
  absent "$CASE/elsewhere/proj/.claude"
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

# --- agent menu -------------------------------------------------------------

test_agents_detected_binary_is_selected() {
  fake_agent claude
  tty_run '\n' --scope global --yes
  saw "[x] 1) Claude Code  (detected)"
  exists "$HOME/.claude/skills/dev-debug"
}

test_agents_detected_config_dir_is_selected() {
  mkdir -p "$HOME/.codex"
  tty_run '\n' --scope global --yes
  saw "[x] 2) Codex CLI  (detected)"
  exists "$HOME/.agents/skills/dev-debug"
}

test_agents_line_replaces_selection() {
  fake_agent claude
  tty_run '2 3\n\n' --scope global --yes
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.config/opencode/skills/dev-debug"
  absent "$HOME/.claude"
}

test_agents_names_and_commas() {
  tty_run 'claude,opencode\n\n' --scope global --yes
  exists "$HOME/.claude/skills/dev-debug"
  exists "$HOME/.config/opencode/skills/dev-debug"
  absent "$HOME/.agents"
}

test_agents_invalid_token_keeps_selection() {
  fake_agent claude
  tty_run '2 9\n\n' --scope global --yes
  saw "not an agent: 9"
  exists "$HOME/.claude/skills/dev-debug"
  absent "$HOME/.agents"
}

test_agents_doubled_comma_is_one_separator() {
  tty_run 'claude,,opencode\n\n' --scope global --yes
  not_saw "not an agent"
  exists "$HOME/.claude/skills/dev-debug"
  exists "$HOME/.config/opencode/skills/dev-debug"
}

test_agents_empty_selection_warns() {
  tty_run '\n1\n\n' --scope global --yes
  saw "select at least one agent"
  exists "$HOME/.claude/skills/dev-debug"
}

test_agents_a_selects_all() {
  tty_run 'a\n\n' --scope global --yes
  exists "$HOME/.claude/skills/dev-debug"
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.config/opencode/skills/dev-debug"
}

# --- plan and confirmation --------------------------------------------------

test_plan_lists_paths_and_actions() {
  tty_run '\n' --agents claude --scope global
  saw "Plan:"
  saw "Claude Code (global)"
  saw "$HOME/.claude/skills"
  saw "install $skill_count skills"
  saw "create file"
  saw "Proceed? [Y/n]"
  exists "$HOME/.claude/skills/dev-debug"
}

test_plan_reinstall_updates_and_replaces() {
  plain_run --agents claude --scope global
  tty_run '\n' --agents claude --scope global
  saw "update $skill_count skills"
  saw "replace block"
}

test_plan_existing_file_gets_block_added() {
  mkdir -p "$HOME/.claude"; echo "# mine" > "$HOME/.claude/CLAUDE.md"
  tty_run '\n' --agents claude --scope global
  saw "add block"
}

test_plan_declined_writes_nothing() {
  tty_run 'n\n' --agents claude --scope global
  status_is 1
  saw "aborted"
  absent "$HOME/.claude"
}

test_plan_end_of_input_aborts() {
  tty_run '\004' --agents claude --scope global
  status_is 1
  saw "aborted"
  absent "$HOME/.claude"
}

test_plan_yes_skips_the_question() {
  tty_run '' --agents claude --scope global --yes
  saw "Plan:"
  not_saw "Proceed?"
  exists "$HOME/.claude/skills/dev-debug"
}

test_plan_without_terminal_proceeds() {
  plain_run --agents claude --scope global
  status_is 0
  saw "Plan:"
  exists "$HOME/.claude/skills/dev-debug"
}

test_plan_shared_agents_md_listed_once() {
  tty_run '\n' --agents codex,opencode --scope project
  saw "same file as Codex CLI"
  exists "$PROJECT/AGENTS.md"
}

test_plan_uninstall() {
  plain_run --agents claude --scope global
  tty_run 'y\n' --uninstall --agents claude --scope global
  saw "remove $skill_count skills"
  saw "remove block"
  saw "Proceed? [y/N]"
  absent "$HOME/.claude/skills/dev-debug"
}

test_plan_uninstall_enter_means_no() {
  plain_run --agents claude --scope global
  tty_run '\n' --uninstall --agents claude --scope global
  status_is 1
  saw "aborted"
  exists "$HOME/.claude/skills/dev-debug"
}

test_plan_uninstall_of_nothing_says_so() {
  tty_run 'n\n' --uninstall --agents claude --scope global
  saw "$(printf '    skills  %-40s %s' "$HOME/.claude/skills" "nothing to remove")"
  saw "$(printf '    router  %-40s %s' "$HOME/.claude/CLAUDE.md" "nothing to remove")"
}

test_plan_uninstall_yes_without_terminal() {
  plain_run --agents claude --scope global
  plain_run --uninstall --agents claude --scope global --yes
  status_is 0
  absent "$HOME/.claude/skills/dev-debug"
}

test_plan_uninstall_without_terminal_needs_yes() {
  plain_run --agents claude --scope global
  plain_run --uninstall --agents claude --scope global
  status_is 1
  saw "pass --yes"
  exists "$HOME/.claude/skills/dev-debug"
}

# --- existing installs ------------------------------------------------------

test_existing_update_refreshes_everything_found() {
  plain_run --agents claude --scope global
  plain_run --agents codex --scope project
  echo "stale" >> "$HOME/.claude/skills/dev-debug/SKILL.md"
  tty_run '\n\n'
  saw "dev-workflow is already installed:"
  saw "Claude Code (global)"
  saw "Codex CLI (project)"
  cmp -s "$HOME/.claude/skills/dev-debug/SKILL.md" "$here/../skills/dev-debug/SKILL.md" \
    || fail "global skill not refreshed"
  absent "$PROJECT/.claude"
}

test_existing_install_elsewhere_goes_to_the_menus() {
  plain_run --agents claude --scope global
  tty_run '2\n2\n\n2\n\n'
  exists "$PROJECT/.agents/skills/dev-debug"
}

test_existing_menu_uninstall() {
  plain_run --agents claude --scope global
  tty_run '3\ny\n'
  saw "remove $skill_count skills"
  absent "$HOME/.claude/skills/dev-debug"
  absent "$HOME/.claude/CLAUDE.md"
}

test_existing_invalid_choice_asks_again() {
  plain_run --agents claude --scope global
  tty_run '9\n3\ny\n'
  saw "type 1, 2 or 3"
  absent "$HOME/.claude/skills/dev-debug"
}

test_existing_uninstall_flag_removes_what_is_found() {
  plain_run --agents claude --scope global
  tty_run 'y\n' --uninstall
  not_saw "Select target"
  absent "$HOME/.claude/skills/dev-debug"
}

test_existing_uninstall_flag_with_nothing_found() {
  tty_run '' --uninstall
  status_is 0
  saw "Nothing to uninstall: no dev-workflow skills globally or in"
}

test_existing_flags_skip_the_menu() {
  plain_run --agents claude --scope global
  tty_run '\n' --agents claude --scope global
  not_saw "already installed"
}

test_existing_scope_flag_alone_skips_the_menu() {
  plain_run --agents claude --scope global
  tty_run '\n\n' --scope global
  not_saw "already installed"
  saw "Select target agent(s):"
}

test_existing_home_not_counted_twice() {
  PROJECT="$HOME"
  plain_run --agents claude --scope global
  tty_run '\n\n'
  not_saw "Claude Code (project)"
  absent "$HOME/CLAUDE.md"
}

test_existing_none_goes_to_the_menus() {
  tty_run '1\n\n\n\n'
  not_saw "already installed"
  exists "$HOME/.claude/skills/dev-debug"
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
