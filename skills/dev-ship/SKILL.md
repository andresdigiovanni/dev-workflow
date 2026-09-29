---
name: dev-ship
description: Decides what goes in each commit and how finished work is integrated. Use when about to commit, when a change is heading past a reviewable size, and when implementation is complete and needs to be pushed, turned into a PR, merged or discarded.
---

# Ship

## One task, one commit

A task is done when its tests pass and its review, if it has one, is through — then it gets its commit. In direct mode the last task's review is `dev-verify`. One task, one commit; several tasks, one commit each, in order. Review fixes are edits before the commit, so nothing ever needs to be amended, rebased or force-pushed. A fix found after its task was committed is a commit of its own.

A task is a deliverable — a behavior, a fix, a migration, a rename — never a file type. `add models`, then `add services`, then `add tests` produces three commits of which none works alone and none can be reviewed or reverted on its own. **Tests go in the same commit as the behavior they verify.** Docs go with the change they explain — the docs that already describe what changed; new docs only when the request asks for them.

| Weak | One task |
|---|---|
| `add models` | `feat(auth): add token validation model` |
| `add services` | `feat(auth): wire token validation into the login flow` |
| `add tests` | — tests ship with the behavior |
| `update docs` | — docs ship with the change they explain |

Follow the repo's commit convention — its log shows it; the prefixes above are only an example. The subject says what changed for a user of the code. A body only when the why isn't obvious from the diff — a few lines. The request, the decisions and the progress live in the ledger and the PR body, not in commits.

Stage by path, never `git add -A` or `git commit -a`: the tree may hold work that isn't part of this task. Commit on the work branch, never on the default branch unless the user says so (router, *Git*).

## Size

Past roughly **400 changed lines**, review quality drops off a cliff. When a change is heading there, slice it into chained PRs before asking anyone to read it — each slice reviewable, testable and revertible by itself, stacked on the one before. Forecast this **before** implementing: with a plan, `dev-plan` already cut the slices; without one, forecast before the first commit.

## Integrating

Never merge to `main` or `master` without the user's explicit say-so. When the work is done and `dev-verify` is clean, present the options with your recommendation and do the one chosen:

- **Open a PR** — the default when anyone else will read this. A sliced plan opens one PR per slice, each based on the slice before it.
- **Merge directly** — only with explicit say-so.
- **Keep the branch** — the work continues.
- **Discard** — the experiment answered its question.

The PR body says what changed and why, the decisions taken and their trade-offs, what a reviewer should look at first, and how it was verified — the actual commands and their results, not "tests pass".

A plan that ran in a worktree: once its branch is merged or discarded, remove the worktree (`git worktree remove <path>`), and its ledger with it.
