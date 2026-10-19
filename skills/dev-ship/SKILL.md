---
name: dev-ship
description: Commits and integrates a change, and runs the Trivial lane. Use for a typo, docs, comment or copy edit, when about to commit, and when implementation is complete and needs to be pushed, turned into a PR, merged or discarded, or its PR conflicts with the branch it targets.
---

# Ship

Branching, and what a task is, are in the router.

## Trivial lane

The router's *Trivial* lane runs from here.

1. Branch, per the router.
2. Edit.
3. Run the suite and the linter. Skip both for docs that nothing builds or tests.
4. Trace every hunk to the request. Revert what traces to nothing.
5. Search the instruction files for every path, command or name the diff changes. A hit loads `dev-verify` and follows only its *First — the instruction-file triage*.
6. Commit once, per *One task, one commit*.
7. Report in three lines: `Checks:` each command → result, or `not run — docs only`; `Scope:` every hunk traced, reverted hunks listed; `Agent file:` no update, updated, or the proposal. There is no baseline on this lane, so a red test is reported red, not attributed.
8. Integrate, per *Integrating*, then *Cleanup*.

## One task, one commit

A task is done when its tests pass and its review, if it has one, is through — then it gets its commit. In direct mode the last task's review is `dev-verify`. One task, one commit; several tasks, one commit each, in order. Review fixes are edits before the commit. A fix found after its task was committed is a commit of its own.

A task is never a file type: `add models`, then `add services`, then `add tests` produces three commits of which none works alone and none can be reviewed or reverted on its own. **Tests go in the same commit as the behavior they verify.** Docs go with the change they explain — the docs that already describe what changed; new docs only when the request asks for them.

| Weak | One task |
|---|---|
| `add models` | `feat(auth): add token validation model` |
| `add services` | `feat(auth): wire token validation into the login flow` |
| `add tests` | — tests ship with the behavior |
| `update docs` | — docs ship with the change they explain |

Follow the repo's commit convention — its log shows it; the prefixes above are only an example. The subject says what changed for a user of the code. A body only when the why isn't obvious from the diff — a few lines. The request, the decisions and the progress live in the ledger and the PR body, not in commits.

Stage by path, never `git add -A` or `git commit -a`: the tree may hold work that isn't part of this task.

## Integrating

Never merge into the default branch without the user's explicit say-so. When the work is done and `dev-verify` is clean — or, on the *Trivial* lane, its steps are — present the options with your recommendation and do the one chosen:

- **Open a PR** — the default when anyone else will read this. A plan opens one PR per slice, each based on the slice before it.
- **Merge directly** — only with explicit say-so. Fast-forward the target to its remote, merge, then run the full suite and gate 1's other checks on the merged result before deleting anything. Push the merged target only if the user said to push. Red: stop, keep the branch and worktree, and report it; nothing has been pushed.
- **Keep the branch** — the work continues.
- **Discard** — the experiment answered its question.

A preference the user declared in an instruction file settles it without the question; a declared preference for merging directly is their say-so.

The PR body says what changed and why, the decisions taken and their trade-offs, how reversible it is — a two-way door a revert undoes, or a one-way door such as a migration, a deletion or a published contract — and its blast radius, what else it can break; then what a reviewer should look at first, and how it was verified — the actual commands and their results, not "tests pass".

## When the target moved

Merge the target branch into the work branch only when the PR shows conflicts, the forge requires the branch to be up to date, or a direct merge would conflict.

- Resolve each conflict from why each side exists — the commit messages, the PR, the ledger — not from the text alone. Keep both intents wherever they're compatible: taking one side wholesale (`--ours`, `--theirs`) drops a change somebody made on purpose.
- Where both can't hold, which one wins is the user's decision: ask it.
- The merge is a commit of its own. Before pushing it, run gates 1 and 2 of `dev-verify` again over the whole branch: a merge is the easiest place to write code that passes neither side's tests.

## Cleanup

Once the work is merged or discarded, remove what the workflow created: the work branch, its worktree and its ledger. Run it from the default branch or the main tree, never from inside the worktree being removed. Remove the worktree first: git won't delete a branch a worktree still has checked out.

| Outcome | Branch | Worktree and ledger |
|---|---|---|
| Merged directly | `git branch -d` — it refuses an unmerged branch, which is the check | remove |
| PR open | keep | keep — review feedback is fixed there |
| PR merged — the user says so, or the forge reports it | `git branch -d`; if it refuses, stop and ask (below) | remove |
| Discarded | `git branch -D`, only after the user confirms the discard | remove |

- **Run `git branch -d` first, always. `-D` needs the user's answer to a question you asked** — "finish up" or "it's merged" is not that answer. After a squash or rebase merge git sees the branch's commits as unmerged, so `-d` refuses although the work landed. Then stop: name the merged PR, say git sees unmerged commits, and ask whether to force-delete. A refusal you override is the only way this cleanup destroys work.
- **A plan** deletes its branches only once every slice is integrated.
- **Never touch a remote branch** — no `git push --delete`, whatever the outcome.
- **Remove a worktree with `git worktree remove <path>`, never `--force`.** If git refuses, the worktree holds files that exist nowhere else: show `git status --short` there and ask.
- **Only what the workflow created:** a branch it made, and a worktree the ledger's header marks `created` — read it before removing anything. The default branch, anything it adopted, and every other branch or worktree are not yours. With no ledger header — direct mode or the Trivial lane — a branch is yours only if this conversation created it; for any other, ask.

A PR open at the end of a session leaves nobody to clean up. When the user later says it merged, run this.
