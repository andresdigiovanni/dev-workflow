---
name: dev-ship
description: Use when deciding what goes into each commit, and when implementation is complete and needs to be integrated. Commits by unit of work rather than by file type, keeps tests with the code they verify, slices oversized changes into chained PRs, and presents the integration options.
---

# Ship

## A commit is a unit of work

One commit = one deliverable: a behavior, a fix, a migration, a rename. Never a commit per file type — `add models`, then `add services`, then `add tests` produces three commits of which none works alone and none can be reviewed or reverted on its own.

**Tests go in the same commit as the behavior they verify.** Docs go with the user-visible change they explain.

Before committing, check:

- [ ] One clear purpose, stateable in the subject line.
- [ ] The repo still makes sense with only this commit applied.
- [ ] It can be reverted without touching unrelated work.
- [ ] The message says what changed for a user of the code, not which files moved.
- [ ] Tests and docs for this unit are in it.

| Weak | Work-unit |
|---|---|
| `add models` | `feat(auth): add token validation model and its tests` |
| `add services` | `feat(auth): wire token validation into the login flow` |
| `add tests` | — tests ship with the behavior |
| `update docs` | — docs ship with the change they explain |

## Size

Past roughly **400 changed lines**, review quality drops off a cliff. When a change is heading there, slice it into chained PRs before asking anyone to read it:

1. Build the smallest independent unit that stands on its own.
2. Stack the next on top of it.
3. Each slice is reviewable, testable and revertible by itself.

Forecast this **before** implementing, not after — restructuring commits afterwards is expensive and usually done badly.

## Integrating

Never merge to `main` or `master` without saying so. When the work is done and `dev-verify` is clean, present the options and do the one chosen:

- **Open a PR** — the default when anyone else will read this.
- **Merge directly** — only with explicit say-so.
- **Keep the branch** — the work continues.
- **Discard** — the experiment answered its question.

Before a PR, run `dev-agents-md`.

The PR body says what changed and why, what a reviewer should look at first, and how it was verified — the actual commands and their results, not "tests pass".
