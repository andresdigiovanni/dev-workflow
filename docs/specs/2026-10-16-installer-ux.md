# Installer UX

## Goal

Make `install.sh` harder to misuse and quicker in the common case: detect agents, take several choices per line, validate the scope answer, show what will be written before writing it, and recognise an existing install.

## Constraints

- bash 3.2 (macOS `/bin/bash`): indexed arrays only, no `${var,,}`, no `mapfile`, no `read -a` tricks beyond 3.2.
- Still runs as `curl … | bash`: every prompt reads `/dev/tty` through `prompt_read`.
- No new dependency. `git` is used only when present, and only to annotate the project line.
- Prompts and messages stay in English, like the rest of the script.
- Flag names and meanings stay as they are, except `--yes` (see C1).

## Decisions

| # | Decision | Rejected | Why |
|---|---|---|---|
| D1 | Install shows the plan and asks `Proceed? [Y/n]` whenever a terminal is available, even with every flag given; `--yes` skips it. Without a terminal, install proceeds after printing the plan, as today. | Confirm only when a menu was used | User's choice (Q1-B) |
| D2 | No `--dry-run`. Answering `n` shows the plan without writing. | `--dry-run` flag | User's choice (Q2-A) |
| D3 | Project scope keeps the current directory (or `--dir`). Inside a git repo the menu shows the repo root as information only. | Install at the repo root | User's choice (Q3-B) |
| D4 | When the project directory is `$HOME`, option 2 is not offered; a typed path is still accepted. When it isn't a git repo, option 2 is offered with a warning. | Always offer with a warning | User's choice (Q4-B) |
| D5 | When neither `--agents` nor `--scope` is given and installs are found, *Update* and *Uninstall* act on every install found, after the plan and confirmation. `--uninstall` with neither flag does the same; finding nothing, it says so and exits 0. | Pick which installs from a checklist | User's choice (Q5-A) |
| D6 | Tests live in `tests/install_test.sh`, run against a temporary `HOME`, driving the menus through a pseudo-terminal (`script`). | Throwaway checks outside the repo | User's choice (Q6-A) |
| D7 | An agent is *detected* when its binary is on `PATH` or its home config directory exists: `claude` / `~/.claude`, `codex` / `~/.codex`, `opencode` / `~/.config/opencode`. Detected agents start selected. | Binary only | Proposal the user accepted (item 2) |
| D8 | A non-empty answer to the agent menu **replaces** the selection with exactly the agents it lists; Enter on an empty line confirms. | Each number toggles, as today | User's choice (Q7-A): "1 3" reads as "these two"; with pre-selected agents, toggling turns it into a surprise |
| D9 | An install is *found* at (agent, scope) when that agent's skills directory for that scope holds at least one dev-workflow skill (`is_ours`). The router block alone does not count. | Marker in the instruction file | Codex and OpenCode share the project `AGENTS.md`, so the marker can't tell them apart. Cost if wrong: a block left without skills is not offered for update; flags still reach it |
| D10 | Detection checks global and the project directory (current directory or `--dir`). The project is skipped when it is `$HOME`. | Searching other directories | Nothing else is knowable without a path. From `$HOME`, Claude's and Codex's project skills directories are the global ones, so the same install would be found twice and *Update* would write a stray `~/CLAUDE.md` |

## Contracts

### C1 — `--yes, -y` (changed meaning)

`Don't ask for confirmation before writing or removing files.` Applies to install and uninstall. `evals/setup.sh` needs no change: it sends stdout to `/dev/null`, and the installer only prompts when stdout is a terminal (`can_prompt`).

### C2 — Agent menu

```
Select target agent(s):
  [x] 1) Claude Code  (detected)
  [ ] 2) Codex CLI
  [ ] 3) OpenCode
Type the numbers or names to select (e.g. "1 3" or "claude,codex"), 'a' for all, Enter to confirm.
> 
```

- Tokens are separated by spaces and/or commas. Each is `1`–`3` or `claude`, `codex`, `opencode`. `a` or `all` (alone on the line) selects every agent.
- Any invalid token: warn naming it, keep the previous selection, show the menu again.
- Valid line: the selection becomes exactly those agents; show the menu again.
- Empty line with nothing selected: warn `select at least one agent`.

### C3 — Scope menu

```
Install scope:
  1) Global  — your home directory, applies to every project
  2) Project — /work/repo/src  (inside git repository /work/repo)
Choose 1 or 2, or type a project path [1]:
> 
```

The annotation after the project path is one of:

- `(git repository)` — the directory is the repo root;
- `(inside git repository <root>)` — a subdirectory of a repo;
- `(! not a git repository)` — `git` is present and the directory isn't in a repo;
- nothing — `git` isn't installed.

When the project directory is `$HOME`, line 2 reads `2) Project — not offered from your home directory; type a project path` and the prompt reads `Choose 1, or type a project path [1]:`.

Answers: empty, `1`, `g`, `global` → global. `2`, `p`, `project` → project (refused from `$HOME`: warn, ask again). Anything else is a path: a leading `~` expands to `$HOME`; an existing directory → project with that directory; otherwise warn `not a choice or an existing directory: <input>` and ask again.

### C4 — Plan

Printed before every install and uninstall, then confirmed per D1 (install, `[Y/n]`, default yes) or as today (uninstall, `[y/N]`, `--yes` or a terminal required).

```
Plan:
  Claude Code (global)
    skills  /Users/me/.claude/skills       update 10 skills
    router  /Users/me/.claude/CLAUDE.md    replace block
  Codex CLI (project)
    skills  /work/repo/.agents/skills      install 10 skills
    router  /work/repo/AGENTS.md           create file
Proceed? [Y/n]
```

- Skills, install: `install N skills` when none of ours is in the directory, else `update N skills`. Uninstall: `remove N skills` (N = ours present), or `nothing to remove`.
- Router, install: `create file` / `add block` / `replace block`. Uninstall: `remove block` / `nothing to remove`. A file already listed for an earlier agent shows `same file as <label>`.
- Declining prints `aborted` and exits 1.

### C5 — Existing-install menu

Shown only when neither `--agents` nor `--scope` is given, a terminal is available, mode is install, and D9 finds at least one install:

```
dev-workflow is already installed:
  Claude Code (global)  /Users/me/.claude/skills
  1) Update   2) Install somewhere else   3) Uninstall
Choose [1]:
> 
```

- `1`/empty → the plan for re-installing every found (agent, scope), then C4.
- `2` → the agent menu (C2), then the scope menu (C3), as when nothing is found.
- `3` → the uninstall plan for every found install, then C4's uninstall confirmation.
- Anything else → warn and ask again.

`--uninstall` with neither `--agents` nor `--scope`: no menu. Found installs → uninstall plan and confirmation. None → `Nothing to uninstall: no dev-workflow skills globally or in <project dir>. Pass --dir for another project.`, exit 0.

### Internal shape (not a surface)

The run works on a list of targets `agent:scope`, so one run can update installs in both scopes. `skills_dir_for` and `instruction_file_for` take the scope as an argument. The `SCOPE` header line becomes per-target labels in the plan.

## Out of scope

- An arrow-key selector.
- Different scopes per agent chosen in one interactive run (only *Update* spans scopes, because it repeats what exists).
- `--dry-run`, a "select none" key, `~` abbreviation in printed paths.
- Changing where skills or router blocks go.

## Done

- `tests/install_test.sh` passes on macOS bash 3.2 and covers C1–C5 and D7–D10.
- `evals/setup.sh` still builds a scenario without prompting.
- README's *Install* and *Uninstall* sections describe the new flow.
- Running `./install.sh` in a terminal with Claude Code installed and no dev-workflow install yet: one Enter at the agent menu, one at the scope menu, one at `Proceed?`.
