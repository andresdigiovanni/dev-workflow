# Development workflow

For any request that changes repository files. A question, an explanation or a review follows only rules 1 and 2.

## Lanes — the first row that fits

| Lane | When | Path |
|---|---|---|
| **Trivial** | No logic and nothing to decide: a typo, docs, comments, copy, a config value the request states exactly | `dev-ship`, *Trivial lane* |
| **Bug** | A bug report, an unexpected failure, behavior that differs from what was expected | `dev-debug`, which picks the fix's lane |
| **Fast** | ≤400 changed lines, code a search finds, and everything open fits in one round of questions, none of which changes the approach | `dev-implement` → `dev-verify` → `dev-ship` |
| **Explored** | ≤400 changed lines, and an ambiguous request, a design choice with two defensible answers, open surfaces that need more than one round, or code a search doesn't find | `dev-explore` → `dev-implement` → `dev-verify` → `dev-ship` |
| **Planned** | Past 400 changed lines | `dev-explore` → `dev-plan` → `dev-implement` → `dev-verify` → `dev-ship` |

Changed lines include tests. Never *Trivial*: a logic fix, a rename or refactor, a config value that adds a key or that a test asserts on, a count with two readings ("retry 3 times": 3 calls or 4?).

**Say the lane** before starting, in one line with the fact that picked it — `Lane: Fast — one function, the request names it` — and again when a phase shows it no longer fits and you switch. A lane the user names wins.

**Load each skill when its phase starts, and follow it**: run from memory, its gates get dropped. Load `dev-testing` before any test or code, and `dev-debug` on any unexpected behavior.

**Branch before the first edit**, without asking — except where a plan runs, which the user chooses at `dev-plan`, *Handoff*. Already on a branch other than the default: work there when it has no commits ahead of the default branch; with commits ahead, ask whether they belong to this work, and branch from the default branch if they don't. Name it by the repo's convention — its branch names, its contributing guide — else by the work's slug. Never commit to the default branch unless the user says so. Never amend, rebase or force-push, and never skip the repo's hooks or checks — no `--no-verify`, no overriding the hooks path.

## Terms

A **new surface** is anything outside the change will depend on: an exported function or type, an endpoint, a response field or header, a CLI command or flag, a config key, an environment variable, an event, a schema, a file format. A request **pins it down** when it gives the exact shape — name, parameters and types, output fields and types, not just "as JSON". Anything less leaves it **open**.

A **task** is one deliverable — a behavior, a fix, a migration, a rename — that can be tested, reviewed and reverted alone, never a file type. It gets one commit, with its tests, per `dev-ship`.

The **ledger** is `.dev-runs/<slug>.md`, kept on *Explored* and *Planned* and from the first fix that didn't hold: one line per fact, appended as it happens and never edited — `Request:` the request as the user wrote it, or as settled once an answer changed the scope; `Decision: <what> — <why> — <cost if wrong>`; `Tried: <hypothesis> — <what the reproduction showed>`. After a compaction it outranks your memory. Before its first write, unless the repo already ignores `.dev-runs/`, add it to the file `git rev-parse --git-path info/exclude` names, and carry over the request, the user's answers and the `Decision:` lines settled so far. Without one, they stay in the conversation, and `dev-verify` reads them there.

## Four rules that apply everywhere

1. **Evidence before claims.** Nothing passes, works or is done until you ran the command in this turn and read its output. A self-report, yours or a sub-agent's, is a claim. Never end a turn waiting on a sub-agent you dispatched.
2. **Facts are yours to find, decisions are the user's.** Never ask what the repo, the history or the network can answer.
3. **Stop only for what the user must answer:** an open new surface; a dependency the request doesn't name; a fact only the user holds — a reproduction, a log, which feature they mean; a caller-observable behavior the request leaves open — two readings count; the go-ahead on a spec and plan, or on a request an answer changed; two failed fixes for one bug; how to integrate; where a plan runs. Open with the facts they rest on, one line each with the path that proves it. Ask each with options, what each costs and buys, and your recommendation — through the host's question tool when it has one, else as `A — <option>: <cost> / <gain>` lines and a closing `➡️ <pick> — <why>`. Decide the rest and record `Decision: <what> — <why> — <cost if wrong>`; a cost a caller would see means it was a stop.
4. **Build only what was asked.** Every changed line traces to the request or the spec. No drive-by refactors, renames or reformatting, no speculative helpers or options, no unrelated fixes, no handling for inputs no caller sends, no comments that narrate the change — list them as follow-ups.
