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
skill_count="$(ls "$here"/../skills/*/SKILL.md | wc -l | tr -d ' ')"
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
  # Feed one line at a time: a burst can outrun the pty's canonical buffer
  # on macOS and drop keys mid-menu.
  {
    sleep 0.5
    printf '%b' "$keys" | while IFS= read -r line; do
      printf '%s\n' "$line"
      sleep 0.3
    done
    sleep 5
  } \
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
# grep an installed file's content as a test: a bare `grep -q` under the
# runner sets no FAILED flag, so a false assertion would pass silently.
content()   { grep -qE -- "$2" "$1" || fail "$1: lacks /$2/"; }
no_content() { ! grep -qE -- "$2" "$1" || fail "$1: has /$2/"; }

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

test_pi_without_omp_installs_to_agents_dir_and_pi_agent_md() {
  tty_run '\n' --agents pi --scope global --yes
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.agents/skills/dev-review"
  exists "$HOME/.pi/agent/AGENTS.md"
  not_saw "error"
}

test_pi_omp_fork_installs_into_the_omp_agent_dir() {
  mkdir -p "$HOME/.omp"
  tty_run '\n' --agents pi --scope global --yes
  saw "Pi (global)"
  saw "$HOME/.omp/agent/AGENTS.md"
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.omp/agent/AGENTS.md"
  absent "$HOME/.pi"
}

test_pi_detected_by_binary() {
  fake_agent pi
  tty_run '\n' --scope global --yes
  saw "[x] 4) Pi  (detected)"
  exists "$HOME/.agents/skills/dev-debug"
}

test_pi_detected_by_omp_dir() {
  mkdir -p "$HOME/.omp"
  tty_run '\n' --scope global --yes
  saw "[x] 4) Pi  (detected)"
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.omp/agent/AGENTS.md"
}

test_pi_project_installs_to_agents_dir_and_standalone_agents_md() {
  tty_run '\n' --agents pi --scope project --yes
  exists "$PROJECT/.agents/skills/dev-debug"
  exists "$PROJECT/AGENTS.md"
}

test_pi_uninstall_removes_the_omp_block_and_the_agents_skills() {
  mkdir -p "$HOME/.omp"
  plain_run --agents pi --scope global --yes
  plain_run --uninstall --agents pi --scope global --yes
  absent "$HOME/.agents/skills/dev-debug"
  absent "$HOME/.omp/agent/AGENTS.md"
}

# Pi shares ~/.agents/skills with Codex CLI. The router block, not the
# skills, says which agent is installed; a bare re-run must not process
# codex, whose instruction file was never written.
test_shared_skills_dir_is_attributed_by_the_router_block() {
  mkdir -p "$HOME/.omp"
  plain_run --agents pi --scope global --yes
  tty_run '\n\n' --yes
  not_saw "Codex CLI (global)"
  absent "$HOME/.codex"
  exists "$HOME/.agents/skills/dev-debug"
}

# Uninstalling one of two agents that share a skills directory leaves the
# skills for the other; uninstalling both removes them whichever goes first.
test_uninstall_of_one_sharer_leaves_the_shared_skills() {
  plain_run --agents pi,codex --scope global --yes
  plain_run --uninstall --agents pi --scope global --yes
  absent "$HOME/.omp/agent/AGENTS.md"
  exists "$HOME/.agents/skills/dev-debug"
  exists "$HOME/.codex/AGENTS.md"
}

test_uninstall_of_both_sharers_removes_the_skills() {
  plain_run --agents pi,codex --scope global --yes
  plain_run --uninstall --agents codex --scope global --yes
  exists "$HOME/.agents/skills/dev-debug"
  plain_run --uninstall --agents pi --scope global --yes
  absent "$HOME/.agents/skills/dev-debug"
}

# --- plan and confirmation --------------------------------------------------

test_plan_lists_paths_and_actions() {
  tty_run '\n\n\n\n\n\n\n\n\n\n\n\n' --agents claude --scope global
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
  # confirm, then Enter through claude-code's model and effort questions,
  # then opencode's (a plain Enter keeps the plan's "same file" behavior going).
  tty_run 'y\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n' --agents codex,opencode --scope project
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

# --- what a skill carries ---------------------------------------------------

test_skill_reference_files_are_installed() {
  plain_run --agents claude --scope global
  exists "$HOME/.claude/skills/dev-review/references/report.md"
  exists "$HOME/.claude/skills/dev-testing/references/property-based.md"
}

# --- retired skills ---------------------------------------------------------

# A skill an earlier version installed: a folder whose SKILL.md carries its name.
retired_skill() {
  mkdir -p "$1/dev-verify"
  printf -- '---\nname: dev-verify\ndescription: old\n---\n' > "$1/dev-verify/SKILL.md"
}

test_retired_update_names_and_removes_it() {
  plain_run --agents claude --scope global
  retired_skill "$HOME/.claude/skills"
  # confirm, then Enter through claude-code's model and effort questions.
  tty_run 'y\n\n\n\n\n\n\n\n\n\n\n\n' --agents claude --scope global
  saw "update $skill_count skills, remove retired dev-verify"
  absent "$HOME/.claude/skills/dev-verify"
  exists "$HOME/.claude/skills/dev-review"
}

test_retired_folder_that_is_not_ours_is_left() {
  plain_run --agents claude --scope global
  mkdir -p "$HOME/.claude/skills/dev-verify"
  echo mine > "$HOME/.claude/skills/dev-verify/notes.txt"
  plain_run --agents claude --scope global
  not_saw "retired"
  saw "left in place"
  exists "$HOME/.claude/skills/dev-verify/notes.txt"
}

test_retired_uninstall_removes_it() {
  plain_run --agents claude --scope global
  retired_skill "$HOME/.claude/skills"
  plain_run --uninstall --agents claude --scope global --yes
  saw "remove $skill_count skills, remove retired dev-verify"
  absent "$HOME/.claude/skills"
}

# A source that still ships the skill, such as an older ref, does not retire it.
test_retired_skill_the_source_still_ships_is_installed() {
  mkdir -p "$CASE/src"
  cp -R "$here/../install.sh" "$here/../router.md" "$here/../skills" "$CASE/src/"
  retired_skill "$CASE/src/skills"
  (cd "$PROJECT" && bash "$CASE/src/install.sh" --agents claude --scope global </dev/null) > "$OUT" 2>&1
  saw "install $((skill_count + 1)) skills"
  not_saw "retired"
  exists "$HOME/.claude/skills/dev-verify/SKILL.md"
  (cd "$PROJECT" && bash "$CASE/src/install.sh" --agents claude --scope global </dev/null) > "$OUT" 2>&1
  saw "update $((skill_count + 1)) skills"
  not_saw "retired"
  exists "$HOME/.claude/skills/dev-verify/SKILL.md"
}

test_retired_alone_is_found_by_a_bare_uninstall() {
  retired_skill "$HOME/.claude/skills"
  plain_run --uninstall --yes
  saw "$(printf '    skills  %-40s %s' "$HOME/.claude/skills" "remove retired dev-verify")"
  absent "$HOME/.claude/skills"
}

test_retired_absent_is_not_mentioned() {
  tty_run '\n' --agents claude --scope global
  not_saw "retired"
}

# --- existing installs ------------------------------------------------------

test_existing_update_refreshes_everything_found() {
  plain_run --agents claude --scope global
  plain_run --agents codex --scope project
  echo "stale" >> "$HOME/.claude/skills/dev-debug/SKILL.md"
  # update, confirm, then Enter through the model and effort questions of
  # every selected harness (claude-code, codex and omp — eleven each).
  tty_run '\ny\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
  saw "dev-workflow is already installed:"
  saw "Claude Code (global)"
  saw "Codex CLI (project)"
  cmp -s "$HOME/.claude/skills/dev-debug/SKILL.md" "$here/../skills/dev-debug/SKILL.md" \
    || fail "global skill not refreshed"
  absent "$PROJECT/.claude"
}

test_existing_install_elsewhere_goes_to_the_menus() {
  plain_run --agents claude --scope global
  # "install somewhere else", reselect Claude Code in the agent menu,
  # project scope, plan confirmation, then the model and effort questions.
  tty_run '2\n1\n\n2\ny\n\n\n\n\n\n\n\n\n\n\n\n'
  exists "$PROJECT/.claude/skills/dev-debug"
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
  # "1" selects Claude Code in the agent menu, Enter confirms it, Enter
  # picks global scope, y confirms the plan, then the model and effort questions.
  tty_run '1\n\n\ny\n\n\n\n\n\n\n\n\n\n\n\n'
  not_saw "already installed"
  exists "$HOME/.claude/skills/dev-debug"
}

# --- agents -----------------------------------------------------------------

test_models_prompt_overrides_one_model() {
  mkdir -p "$HOME/.omp"
  # confirmation, then the omp questions, interleaved per agent: Enter
  # through default, dev-fact-finder, dev-builder-check, dev-implementer,
  # type the dev-reviewer override, Enter its effort and through
  # dev-verifier's model and effort.
  tty_run 'y\n\n\n\n\n\n\n\nopenai/gpt-6-luna\n\n\n\n\n' --agents pi --scope global
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^model: openai/gpt-6-luna$"
  content "$HOME/.omp/agent/agents/dev-implementer.md" "^model: openai/gpt-6.2-sol$"
  content "$HOME/.omp/agent/agents/dev-fact-finder.md" "^model: openai/gpt-6.1-terra$"
}

test_effort_prompt_overrides_one_effort() {
  mkdir -p "$HOME/.omp"
  # confirmation, the omp questions interleaved per agent: Enter through
  # default, dev-fact-finder's model and effort, dev-builder-check's,
  # dev-implementer's, dev-reviewer's model, type its effort override,
  # dev-verifier's model, type its effort override — two, so a first
  # override must survive the second.
  tty_run 'y\n\n\n\n\n\n\n\n\nxhigh\n\nmax\n' --agents pi --scope global
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^thinking-level: xhigh$"
  content "$HOME/.omp/agent/agents/dev-verifier.md" "^thinking-level: max$"
  content "$HOME/.omp/agent/agents/dev-implementer.md" "^thinking-level: high$"
  content "$HOME/.omp/agent/agents/dev-fact-finder.md" "^thinking-level: low$"
}

test_models_file_sets_effort() {
  printf '[claude-code]\ndefault = "m"\n\n[claude-code.effort]\ndev-reviewer = "max"\n' > "$CASE/models.toml"
  plain_run --agents claude --scope global --models "$CASE/models.toml" --yes
  content "$HOME/.claude/agents/dev-reviewer.md" "^effort: max$"
  no_content "$HOME/.claude/agents/dev-implementer.md" "^effort:"
}

test_omp_agents_install_global_and_uninstall_clean() {
  mkdir -p "$HOME/.omp"
  plain_run --agents pi --scope global --yes
  exists "$HOME/.omp/agent/agents/dev-reviewer.md"
  exists "$HOME/.omp/agent/agents/dev-fact-finder.md"
  exists "$HOME/.omp/agent/agents/dev-builder-check.md"
  exists "$HOME/.omp/agent/agents/dev-implementer.md"
  exists "$HOME/.omp/agent/agents/dev-verifier.md"
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^name: dev-reviewer$"
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^model: openai/gpt-6.2-astra$"
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^thinking-level: high"
  content "$HOME/.omp/agent/agents/dev-reviewer.md" "^tools: \[read, grep, glob, bash\]"
  plain_run --uninstall --agents pi --scope global --yes
  absent "$HOME/.omp/agent/agents/dev-reviewer.md"
}

test_omp_agents_project_scope() {
  mkdir -p "$HOME/.omp"
  plain_run --agents pi --scope project --yes
  exists "$PROJECT/.omp/agents/dev-reviewer.md"
}

test_claude_agents_install_global() {
  plain_run --agents claude --scope global --yes
  exists "$HOME/.claude/agents/dev-reviewer.md"
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: claude-fable-5-2$"
  content "$HOME/.claude/agents/dev-reviewer.md" "^effort: medium"
  no_content "$HOME/.claude/agents/dev-reviewer.md" "^alias:"
  no_content "$HOME/.claude/agents/dev-reviewer.md" "thinking-level"
  content "$HOME/.claude/agents/dev-reviewer.md" "^tools: Read, Grep, Glob, Bash"
  plain_run --uninstall --agents claude --scope global --yes
  absent "$HOME/.claude/agents/dev-reviewer.md"
}

test_opencode_agents_install_project() {
  plain_run --agents opencode --scope project --yes
  exists "$PROJECT/.opencode/agents/dev-reviewer.md"
  content "$PROJECT/.opencode/agents/dev-reviewer.md" "^mode: subagent"
  content "$PROJECT/.opencode/agents/dev-reviewer.md" "^model: openai/gpt-6.2-astra#high"
  no_content "$PROJECT/.opencode/agents/dev-reviewer.md" "thinking-level"
  no_content "$PROJECT/.opencode/agents/dev-reviewer.md" "^effort:"
  plain_run --uninstall --agents opencode --scope project --yes
  absent "$PROJECT/.opencode/agents/dev-reviewer.md"
}

test_codex_agents_install_global_toml() {
  plain_run --agents codex --scope global --yes
  exists "$HOME/.codex/agents/dev-reviewer.toml"
  content "$HOME/.codex/agents/dev-reviewer.toml" '^name = "dev-reviewer"$'
  content "$HOME/.codex/agents/dev-reviewer.toml" '^model = "gpt-6\.2-astra"$'
  content "$HOME/.codex/agents/dev-reviewer.toml" '^model_reasoning_effort = "high"$'
  content "$HOME/.codex/agents/dev-reviewer.toml" '^developer_instructions = """$'
  no_content "$HOME/.codex/agents/dev-reviewer.toml" "^model:"
  no_content "$HOME/.codex/agents/dev-reviewer.toml" "^mode:"
  no_content "$HOME/.codex/agents/dev-reviewer.toml" "^tools"
  plain_run --uninstall --agents codex --scope global --yes
  absent "$HOME/.codex/agents/dev-reviewer.toml"
}

test_codex_models_prompt_overrides_one_model() {
  mkdir -p "$HOME/.codex"
  # confirmation, then codex's questions, interleaved per agent: Enter
  # through default, dev-fact-finder, dev-builder-check, dev-implementer,
  # type the dev-reviewer override, Enter its effort and through
  # dev-verifier's model and effort.
  tty_run 'y\n\n\n\n\n\n\n\nopenai/gpt-6-luna\n\n\n\n\n' --agents codex --scope global
  content "$HOME/.codex/agents/dev-reviewer.toml" '^model = "openai/gpt-6-luna"$'
  content "$HOME/.codex/agents/dev-implementer.toml" '^model = "gpt-6\.2-sol"$'
}

test_codex_still_installs_no_markdown_agents() {
  plain_run --agents codex --scope global --yes
  absent "$HOME/.codex/agents/dev-reviewer.md"
  plain_run --uninstall --agents codex --scope global --yes
  absent "$HOME/.codex/agents"
}

test_agents_dir_with_foreign_content_left_alone() {
  mkdir -p "$HOME/.omp"
  mkdir -p "$HOME/.omp/agent/agents"
  echo "not ours" > "$HOME/.omp/agent/agents/dev-reviewer.md"
  plain_run --agents pi --scope global --yes
  grep -q "not ours" "$HOME/.omp/agent/agents/dev-reviewer.md"
  saw "isn't a dev-workflow agent"
  [ ! -f "$HOME/.omp/agent/agents/dev-fact-finder.md" ] && fail "other agents not installed alongside a foreign one"
}

test_users_own_agent_with_a_plain_role_name_is_untouched() {
  mkdir -p "$HOME/.claude/agents"
  printf -- '---\nname: reviewer\ndescription: mine\n---\nmy own reviewer\n' > "$HOME/.claude/agents/reviewer.md"
  plain_run --agents claude --scope global --yes
  not_saw "isn't a dev-workflow agent"
  content "$HOME/.claude/agents/reviewer.md" "^my own reviewer$"
  exists "$HOME/.claude/agents/dev-reviewer.md"
  plain_run --uninstall --agents claude --scope global --yes
  content "$HOME/.claude/agents/reviewer.md" "^my own reviewer$"
  absent "$HOME/.claude/agents/dev-reviewer.md"
}

test_agent_we_installed_is_refreshed_on_a_second_install() {
  printf '[claude-code]\ndefault = "first"\n' > "$CASE/one.toml"
  printf '[claude-code]\ndefault = "second"\n' > "$CASE/two.toml"
  plain_run --agents claude --scope global --models "$CASE/one.toml" --yes
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: first$"
  plain_run --agents claude --scope global --models "$CASE/two.toml" --yes
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: second$"
  not_saw "isn't a dev-workflow agent"
}

test_models_file_with_comments_installs_the_agents() {
  printf '# mine\n[claude-code]  # pinned\ndefault = "m"  # everywhere\n' > "$CASE/models.toml"
  plain_run --agents claude --scope global --models "$CASE/models.toml" --yes
  status_is 0
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: m$"
  content "$HOME/.claude/agents/dev-verifier.md" "^model: m$"
}

test_agents_that_cannot_be_built_fail_the_install() {
  printf '[claude-code]\ndefault = unquoted\n' > "$CASE/models.toml"
  plain_run --agents claude --scope global --models "$CASE/models.toml" --yes
  status_is 1
  saw "5 dispatch agents could not be built"
  not_saw "0 agents"
  absent "$HOME/.claude/agents/dev-reviewer.md"
  exists "$HOME/.claude/skills/dev-debug"
  saw "router block"
}

test_models_file_skips_the_model_questions() {
  printf '[claude-code]\ndefault = "m"\n' > "$CASE/models.toml"
  tty_run 'y\n' --agents claude --scope global --models "$CASE/models.toml"
  not_saw "Models for claude-code"
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: m$"
}

test_models_file_that_does_not_exist_is_refused() {
  plain_run --agents claude --scope global --models "$CASE/missing.toml" --yes
  status_is 1
  saw "no such file"
  absent "$HOME/.claude/agents"
}

# A PATH that holds every tool of /usr/bin and /bin except python3.
no_python3() {
  local dir="$CASE/nopython" tool
  mkdir -p "$dir"
  for tool in /usr/bin/* /bin/*; do
    [ "${tool##*/}" = python3 ] || ln -sf "$tool" "$dir/${tool##*/}"
  done
  PATH="$dir"
}

test_failed_rebuild_keeps_the_agents_already_installed() {
  plain_run --agents claude --scope global --yes
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: claude-fable-5-2$"
  printf '[claude-code]\ndefault = unquoted\n' > "$CASE/models.toml"
  plain_run --agents claude --scope global --models "$CASE/models.toml" --yes
  status_is 1
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: claude-fable-5-2$"
  [ "$(ls -A "$HOME/.claude/agents" | wc -l | tr -d ' ')" = 5 ] || fail "agents dir holds more or fewer than the 5 agents"
}

test_a_model_answer_with_spaces_is_asked_again() {
  # confirmation, Enter through default, "gpt 5" for dev-fact-finder (refused),
  # then g5, then Enter through the four other models and the five efforts.
  tty_run 'y\n\ngpt 5\ng5\n\n\n\n\n\n\n\n\n\n' --agents claude --scope global
  saw "no spaces"
  status_is 0
  content "$HOME/.claude/agents/dev-fact-finder.md" "^model: g5$"
  content "$HOME/.claude/agents/dev-reviewer.md" "^model: claude-fable-5-2$"
}

test_a_model_answer_is_not_expanded_as_a_glob() {
  : > "$PROJECT/claude-code:dev-fact-finder=g5"
  tty_run 'y\n\ng*\n\n\n\n\n\n\n\n\n\n' --agents claude --scope global
  content "$HOME/.claude/agents/dev-fact-finder.md" '^model: g\*$'
}

test_missing_python3_stops_the_install_before_anything_is_written() {
  no_python3
  plain_run --agents claude --scope global --yes
  status_is 1
  saw "python3 is required"
  absent "$HOME/.claude"
}

test_unreadable_models_table_stops_the_model_questions() {
  mkdir -p "$CASE/src/tests"
  cp -R "$here/../install.sh" "$here/../router.md" "$here/../skills" "$here/../agents" "$CASE/src/"
  cp "$here/frontmatter.py" "$CASE/src/tests/"
  printf '[claude-code]\ndefault = unquoted\n' > "$CASE/src/agents/models.toml"
  local saved="$installer"
  installer="$CASE/src/install.sh"
  tty_run 'y\n' --agents claude --scope global
  installer="$saved"
  status_is 1
  saw "couldn't read"
  absent "$HOME/.claude/agents"
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
