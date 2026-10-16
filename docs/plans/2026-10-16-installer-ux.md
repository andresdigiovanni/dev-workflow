# Installer UX — implementation plan

**Goal:** make `install.sh` validate the scope answer, pre-select detected agents, take several agents per line, show a plan before writing, and recognise an existing install.
**Spec:** `docs/specs/2026-10-16-installer-ux.md` — the spec is the authority; this plan argues from it
**Approach:** Everything stays in `install.sh`, in bash 3.2. A new `tests/install_test.sh` drives the installer against a throwaway `HOME`, using `script` as a pseudo-terminal so the menus read real keystrokes from `/dev/tty`. The run is reshaped around a list of `agent:scope` targets so one *Update* can span both scopes.

## Global constraints

- bash 3.2: indexed arrays only; an empty array is never expanded bare under `set -u` (use `${a[@]+"${a[@]}"}` or guard with `${#a[@]}`).
- Prompts read through `prompt_read` (`/dev/tty`); output helpers are `info`, `step`, `ok`, `warn`, `die`.
- No new dependency. `git` only annotates the project line, and only when installed.
- Messages in English. Copy is exactly as in the spec's contracts C2–C5.
- Commit subjects: lowercase sentence, no prefix (see `git log`).

## Files

| File | Responsibility |
|---|---|
| `install.sh` (modify) | all behavior |
| `tests/install_test.sh` (create) | the installer's test suite: harness + one `test_*` function per case |
| `README.md` (modify) | *Install* / *Uninstall* sections describe the flow |

Size forecast: ~200 lines in `install.sh`, ~300 in tests, ~15 in README — past 400, so two slices.

---

## Slice 1: menus

### Task 1: scope menu — validated answer, project annotations, typed path

**Files:**
- Create: `tests/install_test.sh` (executable)
- Modify: `install.sh` — `select_scope_interactive`, new `same_dir`, `project_note`; move the `PROJECT_DIR=… || die` line above the selection block
- Modify: `README.md` — *Install*, first paragraph

**Interfaces:**
- Produces (install.sh): `same_dir <a> <b>` → status 0 when both resolve to the same physical directory. `project_note <dir>` → prints the annotation with two leading spaces, or nothing. `select_scope_interactive` sets `SCOPE` (`global`|`project`) and may set `PROJECT_DIR` (absolute).
- Produces (tests): variables `here`, `installer`, `skill_count`, `CASE`, `HOME`, `PROJECT`, `FAKEBIN`, `OUT`, `STATUS`, `NAME`; functions `fresh`, `fake_agent <id>`, `tty_run <keys> [args…]`, `plain_run [args…]`, `on_tty <cmd…>`, `fail <msg>`, `saw <text>`, `not_saw <text>`, `exists <path>`, `absent <path>`, `status_is <n>`. `<keys>` goes through `printf '%b'`, so `\n` is Enter.
- Produces (surface): C3 exactly.

**Mirror:** `install.sh` — `select_agents_interactive` (loop, `prompt_read … || die`, `warn` and re-ask). Tests: none — no precedent; header and shell options follow `evals/setup.sh`.

**Step 1 — write the failing test**

`tests/install_test.sh`:

```bash
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
```

Later tasks add their `test_*` functions above the `# --- runner` line.

**Step 2 — run it, confirm it fails**
Run: `tests/install_test.sh scope`
Expected: FAIL on every case: `p`, `3`, a path and `~/proj` all install globally today; from `$HOME`, `2` writes `$HOME/CLAUDE.md`; no annotation or new prompt line is printed.

**Step 3 — minimal implementation**

In `install.sh`, move `PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || die "--dir does not exist: $PROJECT_DIR"` up so it runs before `if [ -n "$AGENTS_ARG" ]`. Add above `select_scope_interactive` and replace it:

```bash
same_dir() { [ "$(cd "$1" 2>/dev/null && pwd -P)" = "$(cd "$2" 2>/dev/null && pwd -P)" ]; }

# What the scope menu says after the project path. git reports the
# physical path, so the comparison is against pwd -P, not $1 as given.
project_note() {
  command -v git >/dev/null 2>&1 || return 0
  local root
  if root="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)"; then
    if [ "$root" = "$(cd "$1" && pwd -P)" ]; then
      echo "  (git repository)"
    else
      echo "  (inside git repository $root)"
    fi
  else
    echo "  (! not a git repository)"
  fi
}

select_scope_interactive() {
  local input dir from_home=0
  same_dir "$PROJECT_DIR" "$HOME" && from_home=1

  while true; do
    echo
    echo "Install scope:"
    echo "  1) Global  — your home directory, applies to every project"
    if [ "$from_home" = 1 ]; then
      echo "  2) Project — not offered from your home directory; type a project path"
      printf 'Choose 1, or type a project path [1]:\n> '
    else
      echo "  2) Project — $PROJECT_DIR$(project_note "$PROJECT_DIR")"
      printf 'Choose 1 or 2, or type a project path [1]:\n> '
    fi
    prompt_read input || die "no input available — pass --scope instead"

    case "$input" in
      ""|1|g|global) SCOPE="global"; return 0 ;;
      2|p|project)
        if [ "$from_home" = 1 ]; then
          warn "a project install needs a project directory — type its path"
          continue
        fi
        SCOPE="project"; return 0 ;;
    esac

    case "$input" in
      "~")    dir="$HOME" ;;
      "~/"*)  dir="$HOME/${input#\~/}" ;;
      *)      dir="$input" ;;
    esac
    if [ -d "$dir" ]; then
      PROJECT_DIR="$(cd "$dir" && pwd)"
      SCOPE="project"
      return 0
    fi
    warn "not a choice or an existing directory: $input"
  done
}
```

README, *Install*, first paragraph: "whether to install globally (your home directory) or into the current project" → "whether to install globally (your home directory) or into a project — the current directory, or a path you type. From your home directory only a typed path counts as a project".

**Step 4 — run it, confirm it passes**
Run: `tests/install_test.sh scope`, then `tests/install_test.sh`
Expected: PASS, suite green

**Step 5 — commit message**
`validate the scope answer, describe the project directory, and take a typed project path`

---

### Task 2: agent menu — detected agents pre-selected, several per line

**Files:**
- Modify: `install.sh` — new `agent_detected`, `agent_index`; replace the body of `select_agents_interactive` up to the loop's end (the final `SELECTED_AGENTS+=` loop stays)
- Modify: `tests/install_test.sh` — add the `agents` cases
- Modify: `README.md` — *Install*, first paragraph

**Interfaces:**
- Consumes: the test harness from Task 1.
- Produces: `agent_detected <id>` → status 0 when detected (D7). `agent_index <token>` → prints the 0-based index for `1`–`3` or an id, status 1 otherwise. `select_agents_interactive` still fills `SELECTED_AGENTS`. Surface: C2 exactly.

**Mirror:** `install.sh` — `select_agents_interactive` (current shape, `picked` array, `warn` and re-show).

**Step 1 — write the failing test**

```bash
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
  tty_run '1 9\n\n' --scope global --yes
  saw "not an agent: 9"
  exists "$HOME/.claude/skills/dev-debug"
  absent "$HOME/.agents"
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
```

**Step 2 — run it, confirm it fails**
Run: `tests/install_test.sh agents`
Expected: FAIL on the four detection / replace / names / invalid-token cases (no `(detected)`, nothing pre-selected, `2 3` and `claude,opencode` rejected). `empty_selection_warns` and `a_selects_all` pass today: they guard behavior the rewrite must keep.

**Step 3 — minimal implementation**

```bash
agent_detected() {
  case "$1" in
    claude)   command -v claude   >/dev/null 2>&1 || [ -d "$HOME/.claude" ] ;;
    codex)    command -v codex    >/dev/null 2>&1 || [ -d "$HOME/.codex" ] ;;
    opencode) command -v opencode >/dev/null 2>&1 || [ -d "$HOME/.config/opencode" ] ;;
    *) return 1 ;;
  esac
}

# The AGENT_IDS index for a menu token: its number or its id.
agent_index() {
  local i
  for i in "${!AGENT_IDS[@]}"; do
    if [ "$1" = "$((i + 1))" ] || [ "$1" = "${AGENT_IDS[$i]}" ]; then
      echo "$i"
      return 0
    fi
  done
  return 1
}
```

`select_agents_interactive`: `picked` starts from `agent_detected` per agent. Each row prints `  [%s] %d) %s%s` with `  (detected)` as the last field for a detected agent. The hint line is C2's. Then:

```bash
    if [ -z "$input" ]; then
      any=0
      for i in "${!picked[@]}"; do [ "${picked[$i]}" = "1" ] && any=1; done
      [ "$any" = "1" ] && break
      warn "select at least one agent"
      continue
    fi
    if [ "$input" = a ] || [ "$input" = all ]; then
      for i in "${!picked[@]}"; do picked[$i]=1; done
      continue
    fi

    IFS=', ' read -r -a tokens <<< "$input"
    for i in "${!AGENT_IDS[@]}"; do next[$i]=0; done
    bad=""
    for token in ${tokens[@]+"${tokens[@]}"}; do
      [ -n "$token" ] || continue
      if idx="$(agent_index "$token")"; then next[$idx]=1; else bad="$token"; break; fi
    done
    if [ -n "$bad" ]; then
      warn "not an agent: $bad"
      continue
    fi
    picked=("${next[@]}")
```

(`read -a` into an array keeps `*` from globbing; empty tokens come from `1,,3`.)

README, same paragraph: "which agent(s) to configure — Claude Code, Codex CLI, OpenCode, multiple choice —" → "which agent(s) to configure — Claude Code, Codex CLI, OpenCode; the ones installed on your machine start selected, and you can type several at once (`1 3`, `claude,codex`) —".

**Step 4 — run it, confirm it passes**
Run: `tests/install_test.sh agents`, then `tests/install_test.sh`
Expected: PASS, suite green

**Step 5 — commit message**
`pre-select the agents found on the machine and take several per line`

---

## Slice 2: plan and existing installs

### Task 3: targets, plan and confirmation

**Files:**
- Modify: `install.sh` — `skills_dir_for`, `instruction_file_for` (take the scope), new `skills_present`, `skills_action`, `router_action`, `print_plan`; `confirm` (default argument); move the agent/scope selection block into *Main*; *Main* loops over `TARGETS`; `usage` (`--yes` line)
- Modify: `tests/install_test.sh` — add the `plan` cases
- Modify: `README.md` — *Install*

**Interfaces:**
- Consumes: `SELECTED_AGENTS`, `SCOPE`, `PROJECT_DIR` from Tasks 1–2.
- Produces: `skills_dir_for <agent> <scope>` and `instruction_file_for <agent> <scope>` → path (same paths as today). `skills_present <dir>` → prints how many dev-workflow skills (`is_ours`) are in `dir`. `TARGETS` — array of `agent:scope`, filled before *Main* prints the plan; when non-empty on reaching the selection block, the menus are skipped (Task 4 relies on this). `print_plan` → prints C4 for `TARGETS` and `MODE`. `confirm <question> <y|n>` → status 0 on yes; `y` makes Enter mean yes. Surface: C1 and C4 exactly.

**Mirror:** `install.sh` — `confirm` and the `already_processed` / `PROCESSED_FILES` de-duplication.

**Step 1 — write the failing test**

```bash
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

test_plan_uninstall_without_terminal_needs_yes() {
  plain_run --agents claude --scope global
  plain_run --uninstall --agents claude --scope global
  status_is 1
  saw "pass --yes"
  exists "$HOME/.claude/skills/dev-debug"
}
```

**Step 2 — run it, confirm it fails**
Run: `tests/install_test.sh plan`
Expected: FAIL — no `Plan:` anywhere, no `Proceed?`, `n` doesn't abort an install. `uninstall_without_terminal_needs_yes` passes today and guards it.

**Step 3 — minimal implementation**

Path functions take the scope:

```bash
skills_dir_for() {
  case "$1:$2" in
    claude:global)    echo "$HOME/.claude/skills" ;;
    claude:project)   echo "$PROJECT_DIR/.claude/skills" ;;
    codex:global)     echo "$HOME/.agents/skills" ;;
    codex:project)    echo "$PROJECT_DIR/.agents/skills" ;;
    opencode:global)  echo "$HOME/.config/opencode/skills" ;;
    opencode:project) echo "$PROJECT_DIR/.opencode/skills" ;;
  esac
}
```

`instruction_file_for` the same way, with today's six paths.

Plan helpers, after `remove_block`:

```bash
# How many dev-workflow skills are already in $1.
skills_present() {
  local n=0 name
  for name in "${SKILL_NAMES[@]}"; do
    [ -e "$1/$name" ] && is_ours "$1/$name" "$name" && n=$((n + 1))
  done
  echo "$n"
}

skills_action() {
  local n
  n="$(skills_present "$1")"
  if [ "$MODE" = install ]; then
    if [ "$n" -gt 0 ]; then echo "update ${#SKILL_NAMES[@]} skills"; else echo "install ${#SKILL_NAMES[@]} skills"; fi
  else
    if [ "$n" -gt 0 ]; then echo "remove $n skills"; else echo "nothing to remove"; fi
  fi
}

router_action() {
  local has_block=0
  [ -f "$1" ] && grep -qxF "$MARKER_START" "$1" && has_block=1
  if [ "$MODE" = install ]; then
    if [ ! -f "$1" ]; then echo "create file"
    elif [ "$has_block" = 1 ]; then echo "replace block"
    else echo "add block"; fi
  else
    if [ "$has_block" = 1 ]; then echo "remove block"; else echo "nothing to remove"; fi
  fi
}

print_plan() {
  local target agent scope label skills_dir instr_file action i
  local -a files=() labels=()
  echo
  echo "Plan:"
  for target in "${TARGETS[@]}"; do
    agent="${target%%:*}"; scope="${target#*:}"
    label="$(label_for "$agent")"
    skills_dir="$(skills_dir_for "$agent" "$scope")"
    instr_file="$(instruction_file_for "$agent" "$scope")"

    action="$(router_action "$instr_file")"
    i=0
    while [ "$i" -lt "${#files[@]}" ]; do
      [ "${files[$i]}" = "$instr_file" ] && action="same file as ${labels[$i]}"
      i=$((i + 1))
    done
    files+=("$instr_file"); labels+=("$label")

    printf '  %s (%s)\n' "$label" "$scope"
    printf '    skills  %-40s %s\n' "$skills_dir" "$(skills_action "$skills_dir")"
    printf '    router  %-40s %s\n' "$instr_file" "$action"
  done
}
```

`confirm`:

```bash
# confirm <question> <y|n> — the second argument is what Enter means.
confirm() {
  [ "$ASSUME_YES" = "1" ] && return 0
  local reply hint="[y/N]"
  [ "$2" = y ] && hint="[Y/n]"
  printf '%s %s ' "$1" "$hint"
  prompt_read reply || true
  case "$reply" in
    y|Y|yes|YES) return 0 ;;
    "") [ "$2" = y ] ;;
    *) return 1 ;;
  esac
}
```

*Main* begins with `TARGETS=()`, then the agent/scope selection block moved down from above (the `PROJECT_DIR=… || die` line Task 1 placed stays where it is, above every use), wrapped in `if [ "${#TARGETS[@]}" -eq 0 ]; then … fi` and ending with `for agent in "${SELECTED_AGENTS[@]}"; do TARGETS+=("$agent:$SCOPE"); done`. Then:

```bash
echo
info "${BOLD}dev-workflow${RESET} — ${MODE}"
print_plan
echo
if [ "$MODE" = install ]; then
  if can_prompt && ! confirm "Proceed?" y; then info "aborted"; exit 1; fi
else
  [ "$ASSUME_YES" = 1 ] || can_prompt || die "no terminal to confirm on — pass --yes"
  confirm "Proceed?" n || { info "aborted"; exit 1; }
fi
```

The install and uninstall loops iterate `for target in "${TARGETS[@]}"`, split `agent`/`scope` as in `print_plan`, print `step "$label ($scope)"`, and pass `"$scope"` to both path functions; the uninstall `rmdir` of the parent tests `"$scope" = project`. The old uninstall question is gone (the plan's `Proceed?` replaces it).

`usage`: `--yes, -y          Don't ask for confirmation before writing or removing files.`

README, *Install*, after the first paragraph: "Before writing anything it lists every directory and file it will touch, and what it will do to each, and asks to proceed. `--yes` skips the question; without a terminal the install proceeds after printing the list."

**Step 4 — run it, confirm it passes**
Run: `tests/install_test.sh plan`, then `tests/install_test.sh`
Expected: PASS, suite green

**Step 5 — commit message**
`show what install and uninstall will touch, and ask before touching it`

---

### Task 4: existing installs — update, install elsewhere, uninstall

**Files:**
- Modify: `install.sh` — new `find_installs`, `choose_existing_action`; *Main*, before the selection block; `usage`
- Modify: `tests/install_test.sh` — add the `existing` cases
- Modify: `README.md` — re-run paragraph and *Uninstall*

**Interfaces:**
- Consumes: `same_dir` (Task 1), `skills_dir_for`, `skills_present`, `TARGETS`, `print_plan`, `confirm` (Task 3), `label_for`.
- Produces: `find_installs` → fills `FOUND`, an array of `agent:scope`, global first, project skipped when `same_dir "$PROJECT_DIR" "$HOME"` (D9, D10). `choose_existing_action` → sets `TARGETS=("${FOUND[@]}")` for 1 and 3, `MODE=uninstall` for 3, leaves `TARGETS` empty for 2. Surface: C5 exactly.

**Mirror:** `install.sh` — `select_scope_interactive` (Task 1's loop: prompt, `case`, `warn` and re-ask).

**Step 1 — write the failing test**

```bash
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
```

**Step 2 — run it, confirm it fails**
Run: `tests/install_test.sh existing`
Expected: FAIL — no `already installed` menu; `--uninstall` alone opens the agent menu. `flags_skip_the_menu` and `none_goes_to_the_menus` pass today and guard the paths that must not change.

**Step 3 — minimal implementation**

```bash
# Every agent:scope whose skills directory already holds a dev-workflow
# skill. From $HOME the project paths are the global ones, so only global.
find_installs() {
  local scope agent
  FOUND=()
  for scope in global project; do
    [ "$scope" = project ] && same_dir "$PROJECT_DIR" "$HOME" && continue
    for agent in "${AGENT_IDS[@]}"; do
      if [ "$(skills_present "$(skills_dir_for "$agent" "$scope")")" -gt 0 ]; then
        FOUND+=("$agent:$scope")
      fi
    done
  done
  return 0
}

choose_existing_action() {
  local input target
  echo
  echo "dev-workflow is already installed:"
  for target in "${FOUND[@]}"; do
    printf '  %s (%s)  %s\n' "$(label_for "${target%%:*}")" "${target#*:}" \
      "$(skills_dir_for "${target%%:*}" "${target#*:}")"
  done
  while true; do
    printf '  1) Update   2) Install somewhere else   3) Uninstall\nChoose [1]:\n> '
    prompt_read input || die "no input available — pass --agents and --scope instead"
    case "$input" in
      ""|1) TARGETS=("${FOUND[@]}"); return 0 ;;
      2)    return 0 ;;
      3)    MODE="uninstall"; TARGETS=("${FOUND[@]}"); return 0 ;;
      *)    warn "type 1, 2 or 3" ;;
    esac
  done
}
```

*Main*, right after `TARGETS=()`:

```bash
if [ -z "$AGENTS_ARG" ] && [ -z "$SCOPE" ]; then
  find_installs
  if [ "$MODE" = uninstall ]; then
    if [ "${#FOUND[@]}" -eq 0 ]; then
      info "Nothing to uninstall: no dev-workflow skills globally or in $PROJECT_DIR. Pass --dir for another project."
      exit 0
    fi
    TARGETS=("${FOUND[@]}")
  elif [ "${#FOUND[@]}" -gt 0 ] && can_prompt; then
    choose_existing_action
  fi
fi
```

`usage`, last paragraph: "With no options, both agents and scope are chosen from an interactive menu — unless dev-workflow is already installed globally or in the current directory, in which case it offers to update it, install somewhere else, or uninstall. `--uninstall` with neither `--agents` nor `--scope` removes every install it finds."

README: the re-run paragraph gains "With no options, it lists the installs it finds — globally and in the current directory — and offers to update them, install somewhere else, or uninstall." *Uninstall*: after the first command, "With no other options this removes every install found globally and in the current directory, after showing what it will remove."

**Step 4 — run it, confirm it passes**
Run: `tests/install_test.sh existing`, then `tests/install_test.sh`
Expected: PASS, suite green

**Step 5 — commit message**
`offer to update or uninstall the installs the script finds`
