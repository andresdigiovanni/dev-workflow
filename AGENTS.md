# Development workflow

Five phases, each with a written skip criterion. Route by the size of the change, not by ceremony.

| Skill | Use it when | Skip it when |
|---|---|---|
| `dev-explore` | The request is ambiguous, spans code you don't know, or carries a design decision with more than one defensible answer | The request names the what and the where, and you already know the affected code |
| `dev-plan` | More than ~3 tasks, or more than ~2 files, or a new interface another task will consume | Fewer than that — `dev-implement` works straight from the request or the spec |
| `dev-implement` | Any time code gets written | Never skipped |
| `dev-verify` | Before claiming the work is done, and before a PR or a merge | Never skipped |
| `dev-ship` | Deciding what goes in each commit, and integrating finished work | Never skipped |

**Fast lane.** A change confined to one or two files, with no new interface and nothing ambiguous, goes `dev-testing` → `dev-verify` → `dev-ship`. No spec, no plan, no sub-agents. Most changes are this.

Support skills, invoked from inside the phases: `dev-testing` (before any implementation code), `dev-debug` (any bug or unexpected behavior), `dev-agents-md` (repo files changed and work is wrapping up), `dev-skills` (editing this set).

## Three rules that apply everywhere

1. **Evidence before claims.** Never say something passes, works, or is done without having run the command in this turn and read its output. A self-report — yours or a sub-agent's — is a claim, not evidence.
2. **Facts are yours to find, decisions are the user's.** Never ask for something you could look up in the repo, the history, or the network. Never decide something the user is entitled to decide.
3. **Don't stop between tasks to ask permission.** Executing a plan means executing it. On a conflict or an ambiguity, decide, record `Decision: <what> — <why> — <cost if wrong>` in the ledger, and keep going.

## Artifacts

| What | Where | Git |
|---|---|---|
| Spec | `docs/specs/YYYY-MM-DD-<slug>.md` | committed |
| Plan | `docs/plans/YYYY-MM-DD-<slug>.md` | committed |
| Ledger | `.dev-runs/<slug>.md` | git-ignored |

A convention already established in the target repo wins over these defaults.
