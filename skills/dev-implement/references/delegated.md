# Delegated mode — there is a plan

Read this in full before setting up a plan's execution, and again after any context compaction, before touching the ledger.

You are the **coordinator**: you dispatch, verify, review and commit, and the implementers write the code.

## Contents
- Setup — worktree, ledger, resuming
- Per task — dispatch, verify, review, fix rounds, commit
- After the last task
- Slices
- Model selection
- Without sub-agents

## Setup

Tasks run **one at a time**, even in a worktree. The review between tasks is what catches a task that drifted from its `Interfaces` before the next one builds on it; parallel implementers skip that gate, collide on shared files, and need merges to rejoin. Parallelize the read-only work instead: fact-finding in `dev-explore`, and nothing else.

Read the plan once. Read the spec it names — that is the authority, and any conflict inside the plan resolves against it. Note the global constraints; they bind every task. Decisions settled in `dev-explore` already live in the spec — don't copy them; the ledger records the ones taken from here on.

Create the ledger at `.dev-runs/<slug>.md` in the tree the work runs in, first line `# ledger — plan: <path to plan> — branch: <branch> — worktree: <path or none>`, so a coordinator resuming from anywhere knows where the work is. If `.dev-runs/` isn't git-ignored, add it to the file `git rev-parse --git-path info/exclude` names, so the ledger never lands in a commit.

Before dispatching Task 1, run the project's full test command once on the work branch and log `Plan: baseline — <command> → <result>`. A red test it shows is pre-existing: implementers and reviewers are told so, and `dev-verify` reports it as such.

**Why the ledger exists:** conversation memory does not survive compaction. The single most expensive failure in this workflow is a coordinator that lost its place and re-ran tasks that were already done. After a compaction, the ledger and `git log` outrank your recollection.

One line per event, appended as it happens, never edited:

```
Task N: dispatched — <model>
Task N: report — <done | blocked>
Task N: waiting — <the surface or question put to the user> — stashed
Task N: unblocked — <the user's answer>
Task N: review — <n> findings
Task N: fix round <k> — <model>
Task N: ruling — <finding> — <ruling> — <why>
Task N: complete — <sha>
Plan: baseline — <command> → <result>
Plan: fix — <finding> — <sha>
Slice K: verified — <branch>
Plan: verified — <branch>
Decision: <what> — <why> — <cost if wrong>
```

Resuming, by the task's last line:

- `complete` — committed, never re-dispatch.
- `dispatched` — check `git status` for its uncommitted changes first; if they exist, verify them as if reported, and re-dispatch only if they don't.
- `report` — `done`: verify it (step 2), then dispatch the reviewer. `blocked` on an unlisted surface or dependency: ask the user and append `waiting`. Any other `blocked`: diagnose, decide, record, re-dispatch.
- `waiting` — still with the user; its diff is in `git stash list` under `task N`. Skip it and carry on with the tasks that don't consume its `Interfaces`.
- `unblocked` — pop its stash, then re-dispatch, with the user's answer added to what step 1 lists.
- `review` — 0 findings: commit and mark it `complete`. Otherwise start the next fix round, or rule if two rounds already ran.
- `fix round` — appended when the round is dispatched. If the working tree changed since the review, review that round's result; if not, re-dispatch the round.
- `ruling` — once every surviving finding has one, commit and mark it `complete`.

## Per task

**1. Dispatch a fresh implementer.**

It gets exactly this, constructed on purpose:

- the full text of its task
- the worktree path it works in
- its `Interfaces` block
- the global constraints
- the spec requirements its task serves
- the baseline's red tests, if any — pre-existing, not its to fix
- the instruction to follow `dev-testing`, and `dev-debug` for anything that breaks unexpectedly
- the instruction that a public surface its `Interfaces` block doesn't list, or a dependency the plan doesn't name, is not its to add: stop, report `blocked`, and name it
- the instruction to change only what its task lists — no refactors, renames or fixes outside it; anything it noticed goes under `Follow-ups`
- the instruction to report in the shape below

It gets **none of your session history**. That isolation is the whole reason delegation works — inherited context is how a sub-agent drifts onto work that isn't its own.

It implements and tests, **without committing**, and reports:

```
Status: done | blocked
Tests: <exact command> → <exact result>
Full suite: <exact command> → <exact result, naming any red test>
Mutants: <survivors on the new code, each explained — or none>
Interfaces produced: <what it actually built, signature by signature>
Decisions: <anything the task didn't answer and it had to settle>
Follow-ups: <things it noticed and deliberately left alone — or none>
```

**A blocked task:**

- **Blocked on an unlisted surface or dependency:** it goes to the user — it is not yours to settle either. Append `waiting`, and `unblocked` when they answer.
- **Any other block** — broken tooling, a task the plan made impossible: it is yours. Diagnose it per `dev-debug`, decide, record the `Decision:` line, and re-dispatch.

**While a task waits on the user,** keep executing the tasks that don't consume its `Interfaces`. Stop only when every remaining task does.

1. Before dispatching the next task, set the waiting task's uncommitted diff aside with `git stash push -u -m "task N"`, and log it as `Task N: waiting — <question> — stashed`. The next task's diff and commit then hold only its own work.
2. When you re-dispatch it, restore it with `git stash pop stash@{<n>}`, where `<n>` is the entry `git stash list` shows for `task N`. A bare `pop` takes the newest entry, which may be another task's.
3. If it doesn't apply cleanly, `git stash drop` that entry and re-dispatch the task from scratch.

**2. Verify the report before trusting it.** A self-report is a claim. Read the diff. If the report names a command, the claim is that command's output, not the sentence about it. An agent that reports success and changed nothing is a failure mode that occurs.

**3. Dispatch a fresh reviewer** on that task's diff: does it do what the task asked, and does the quality hold? Does the diff honor its `Interfaces` block and the global constraints? Does it contain anything the task didn't ask for? The reviewer gets the task text, its `Interfaces` block, the global constraints, the spec requirements it serves, the baseline's red tests, the implementer's `Decisions`, the worktree path and the diff — not your history.

**4. Two fix rounds, maximum.** A fix round is a fresh implementer given everything step 1 lists, plus the current diff and the reviewer's findings — still none of your history. It edits the same uncommitted diff, and a fresh reviewer checks the result. If findings survive the review after round two: rule on each one, record the ruling in the ledger, and move on. A plan does not stall on a minor finding. If a finding contradicts what the plan mandates, the spec decides — rule and record.

**5. Commit the task** — one commit, the message the plan gives it, per `dev-ship` — append `complete` with its SHA, and start the next task. No progress summaries to the user in between; they asked for the plan to be executed. Each implementer's `Decisions` go into the ledger as `Decision:` lines; `dev-ship` carries them to the PR body.

## After the last task

**A fix from any `dev-verify` gate is not yours to write.** Dispatch a fresh implementer with the finding, the spec requirements it touches and the diff, under the same rules as a fix round (*Per task*, step 4). Every task is already committed, so the fix is a commit of its own, logged `Plan: fix — <finding> — <sha>`.

Once every task is `complete`, run `dev-verify` over the whole branch — gate 2 against the whole spec is the only place a requirement split across tasks is checked — append `Plan: verified`, then `dev-ship` integrates it. Resuming: every task `complete` and no `Plan: verified` line means this step hasn't run. A sliced plan does this per slice instead, below.

## Slices

When the plan is cut into slices, each slice gets its own branch, created from the previous slice's branch. No stop between slices: the plan's go-ahead covered them.

1. After a slice's last task is `complete`, run `dev-verify` on that slice — its diff against the previous slice's branch. Land its fixes on that branch and append `Slice K: verified`.
2. Branch the next slice from it.
3. When the last slice is verified, run gate 2 of `dev-verify` once more, against the whole spec, over the whole stack. A requirement split across slices is checked nowhere else. The last slice's verification is the pre-PR `dev-verify`; don't run it twice.
4. `dev-ship` integrates the stack.

Resuming: a slice whose tasks are all `complete` but that has no `verified` line gets verified before anything else.

## Model selection

| Task shape | Model |
|---|---|
| Mechanical, isolated, clear spec, 1-2 files | fast |
| Integration, pattern matching, judgment | mid |
| Architecture, design, review | most capable available |
| Fix round after a failed review | one tier above the round before, up to the most capable |

Say which model you're dispatching with; an unspecified model is a silent default.

## Without sub-agents

Implement task by task yourself, but keep the ledger, and make each task's review a separate, explicit pass over the diff — reading it as a reviewer would, not leaning on the reasoning you used to write it. Say in the ledger that the review was self-run.
