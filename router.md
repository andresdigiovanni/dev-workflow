# Development workflow

For any request that changes repository files. A question, an explanation or a review doesn't enter it; only rules 1 and 2 apply.

## Pick a lane — the first row that fits

| Lane | When | Path |
|---|---|---|
| **Trivial** | No logic changes and nothing to decide: a typo, docs, comments, copy, or a config value the request states exactly. See the exclusions below | *Trivial lane*, below. No skill loaded |
| **Bug** | A bug report, a test failing unexpectedly, behavior that differs from what was expected | `dev-debug` first. Then the lane the fix's size picks, entering at `dev-implement` — or at `dev-explore` when the fix is *Planned* or its decisions take more than one round of questions. Never *Trivial*: a logic fix changes behavior |
| **Fast** | A clear request, code a search finds, ≤3 commits, and every open behavior, surface or dependency fits in one round of questions with no answer that would change the approach. Most changes | `dev-implement` → `dev-verify` → `dev-ship` |
| **Explored** | ≤3 commits, and any of: an ambiguous request, a design choice with more than one defensible answer, open surfaces that need more than one round, code a search doesn't find | `dev-explore` → `dev-implement` → `dev-verify` → `dev-ship` |
| **Planned** | >3 commits | `dev-explore` → `dev-plan` → `dev-implement` → `dev-verify` → `dev-ship`. Always explored: at this size the approach itself is a decision |

**Not Trivial, but Fast:** a config value that adds a key, a value a test asserts on, or a count or limit with two readings ("retry 3 times": 3 calls or 4?). A test that asserts on the value is updated to the requested value first and watched fail.

**Commits** count behaviors that could each be tested, reviewed and reverted alone — not files. A rename or refactor breaks callers, so it is *Fast*, not *Trivial*.

**Wrong lane?** When a phase shows the lane no longer fits — exploration finds more than 3 commits, a trivial edit needs logic — switch lanes from the phase you are in.

**Load each skill when its phase starts, and follow it.** A phase run from memory drops its gates. Also load `dev-testing` before any implementation code, `dev-debug` on any unexpected behavior, and `dev-skills` when editing this set.

### Trivial lane

These steps are `dev-verify`'s *Trivial* row, run inline:

1. Branch, per *Git*.
2. Edit.
3. Run the suite and the linter. Skip both for docs that nothing builds or tests.
4. Trace every hunk to the request. Revert what traces to nothing.
5. Search the instruction files for every path, command or name the diff changes. A hit loads `dev-agents-md`.
6. Commit once.
7. Report in `dev-verify`'s compact form: `Checks:`, `Scope:` and `Agent file:`. There is no pre-change run on this lane, so a red test is reported red, not attributed.
8. Ask how to integrate — `dev-ship`, *Integrating*, has the options.

### Terms

A **new surface** is anything outside the change will depend on: an exported function or type, an endpoint, a response field or header, a CLI command or flag, a config key, an environment variable, an event, a schema or a file format.

A request **pins down** a surface when it gives its exact shape: the name, the parameters and their types, and for output its fields and their types — not just "as JSON". Anything less leaves the surface **open**.

## Four rules that apply everywhere

1. **Evidence before claims.** Nothing passes, works or is done until you ran the command in this turn and read its output. A self-report — yours or a sub-agent's — is a claim, not evidence.
2. **Facts are yours to find, decisions are the user's.** Never ask what the repo, the history or the network can answer. Never decide what the user is entitled to decide.
3. **Stop only for what the user must answer.** Ask each one with options, their costs and your recommendation:
   - an open new surface;
   - a new dependency the request doesn't name;
   - a fact only the user holds — a reproduction, a log, which feature they mean;
   - a caller-observable behavior the request leaves open — two readings count;
   - the go-ahead on spec and plan, or on a restated request when an answer changed the scope;
   - two failed fixes for one bug;
   - how to integrate.

   Decide everything else and record `Decision: <what> — <why> — <cost if wrong>`. If the cost is something a caller would see, it was a stop: ask. Never stop between the tasks of an approved plan: a task blocked on a user's decision is asked while the others carry on.
4. **Build only what was asked.** Every changed line traces to the request or the spec. No drive-by refactors, reformatting, renames, speculative helpers, options "for later", unrelated fixes, error handling for inputs no caller sends, or comments that narrate the change — list them as follow-ups.

**Git.** Branch first, without asking. Never commit to the default branch unless the user says so. Stage by path, never `git add -A`: the tree may hold the user's own work. One commit per task, after its tests and its review, if it has one, pass. Never amend, rebase or force-push.

Specs go in `docs/specs/`, plans in `docs/plans/`, ledgers in `.dev-runs/` (git-ignored). A convention the repo already has wins.
