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

**Where the plan runs is settled before anything is created** — asked at `dev-plan`, *Handoff*, with these options. Ask it here, in the router's question format (rule 3), only when that answer is missing:

- **A worktree for the whole plan, on its own branch** — recommended: sub-agents and the user never write to the same files. It costs a setup and a cleanup.
- **A branch in the current tree** — nothing to set up. It costs the tree: the user can't edit files while the plan runs, and uncommitted work of theirs stays in the way.

A preference the user declared in an instruction file settles it without the question. Already inside a linked worktree (`git rev-parse --git-dir` differs from `--git-common-dir`, and `git rev-parse --show-superproject-working-tree` prints nothing)? Work there; don't create another.

Create a worktree with the host's native worktree mechanism when it has one, else `git worktree add .worktrees/<slug> -b <branch>` with `.worktrees/` added to the file `git rev-parse --git-path info/exclude` names. A new worktree has no installed dependencies and none of the main tree's untracked files: before the baseline, run the setup command the repo documents — its README, contributing guide, Makefile or task runner. None documented, or the baseline needs an untracked file the worktree lacks, such as `.env`: ask. Never copy one over unasked.

Create no branch, worktree or ledger without that answer; the ledger lives in the tree the work runs in.

Tasks run **one at a time**, even in a worktree. The review between tasks is what catches a task that drifted from its `Interfaces` before the next one builds on it; parallel implementers skip that gate, collide on shared files, and need merges to rejoin. Parallelize the read-only work instead: fact-finding in `dev-explore`, and nothing else.

Read the plan once. Read the spec it names — that is the authority, and any conflict inside the plan resolves against it. Note the global constraints; they bind every task. Decisions settled in `dev-explore` already live in the spec — don't copy them; the ledger records the ones taken from here on.

Create the ledger (router, *Terms*) in the tree the work runs in, first line `# ledger — plan: <path to plan> — branch: <branch> (created | adopted) — worktree: <path> (created | adopted), or none`, so a coordinator resuming from anywhere knows where the work is.

A task's other artifacts are files in `.dev-runs/<slug>/`, beside the ledger:

- `task-N-brief.md` — what the implementer gets;
- `task-N-report.md` — its full report;
- `task-N-diff.md` — the task's diff and untracked files, written for the reviewer;
- `task-N-review.md` — the review.

Hand them over by path: whatever you paste into a dispatch, and whatever comes back, stays in your context for the rest of the plan.

Before dispatching Task 1, run the project's full test command once on the work branch and log `Plan: baseline — <command> → <result>`. A red test it shows is pre-existing: implementers and reviewers are told so, and `dev-verify` reports it as such.

**Why the ledger exists:** conversation memory does not survive compaction. The single most expensive failure in this workflow is a coordinator that lost its place and re-ran tasks that were already done. After a compaction, the ledger and `git log` outrank your recollection.

One line per event, appended as it happens, never edited:

```
Task N: dispatched — <model>
Task N: report — <done | done_with_concerns | needs_context | blocked>
Task N: asked — <step 1 | step 4> — <the question put to the user>
Task N: answered — <the user's answer>
Task N: review — <n> critical or important, <m> minor
Task N: fix round <k> — <model> — <resumed | fresh>
Task N: ruling — <finding> — <ruling> — <why>
Task N: complete — <sha>
Slice K: branch — <branch>
Plan: baseline — <command> → <result>
Plan: fix — <finding> — <sha>
Slice K: verified — <branch>
Plan: verified — <branch>
Decision: <what> — <why> — <cost if wrong>
Tried: <hypothesis> — <what the reproduction showed>
```

Resuming, by the task's last line:

- `complete` — committed, never re-dispatch.
- `dispatched` — check `git status` for its uncommitted changes first; if they exist, verify them as if reported, and re-dispatch only if they don't.
- `report` — act on its status, per *Per task*, step 1, *On its status*.
- `asked` — the question is still with the user: ask it again and dispatch nothing until they answer.
- `answered` — from step 4: compare the tree with `task-N-diff.md` first; if the reviewed diff is gone or changed, tell the user and wait for them; otherwise continue step 4 with the answer. From step 1: re-dispatch, with the answer added to what step 1 lists.
- `review` — rule on it first, per *Per task*, step 4. Nothing left to fix: commit and mark it `complete`. Otherwise start the next fix round, or rule if two rounds already ran.
- `fix round` — appended when the round is dispatched. If the working tree changed since the review, review that round's result; if not, re-dispatch the round, fresh: a resumed implementer may be gone.
- `ruling` — once every surviving finding has one, commit and mark it `complete`.

## Per task

**1. Dispatch a fresh implementer.**

Write its brief to `task-N-brief.md` — exactly this, constructed on purpose — and dispatch it with that path:

- the full text of its task
- the worktree path it works in
- its `Interfaces` block
- its `Mirror` line
- the global constraints
- the spec requirements its task serves
- the baseline's red tests, if any — pre-existing, not its to fix
- the instruction to follow `dev-testing`, and `dev-debug` for anything that breaks unexpectedly
- the instruction that a public surface its `Interfaces` block doesn't list, or a dependency the plan doesn't name, is not its to add: stop, report `blocked`, and name it
- the instruction to dispatch no sub-agents — no helpers and no reviewer: the review comes from you, after its report
- the instruction to change only what its task lists — no refactors, renames or fixes outside it; anything it noticed goes under `Follow-ups`
- the instruction to report in the shape below, to `task-N-report.md`

It gets **none of your session history**. That isolation is the whole reason delegation works — inherited context is how a sub-agent drifts onto work that isn't its own.

It implements and tests, **without committing**, writes its full report to `task-N-report.md` in this shape, and returns only its status, a one-line test summary and its concerns:

```
Status: done | done_with_concerns | needs_context | blocked
Tests: <exact command> → <exact result>
Full suite: <exact command> → <exact result, naming any red test>
Interfaces produced: <what it actually built, signature by signature>
Decisions: <anything the task didn't answer and it had to settle>
Follow-ups: <things it noticed and deliberately left alone — or none>
Concerns: <doubts about the work's correctness or scope — or none>
```

**On its status:**

- **`done`** — verify it, step 2.
- **`done_with_concerns`** — read the concerns first. One about correctness or scope is named to the reviewer as something to check; an observation goes under `Follow-ups`. Then step 2.
- **`needs_context`** — what is missing is in the spec, the plan or the repo: add it to the brief and re-dispatch. Only the user has it: ask it, below.
- **`blocked` on an unlisted surface or dependency:** it goes to the user — it is not yours to settle either. Ask it, below.
- **Any other `blocked`** — broken tooling, a task the plan made impossible: it is yours. Diagnose it per `dev-debug`, decide, record the `Decision:` line, and re-dispatch.

Never stop between tasks to check in: the plan's go-ahead covered them. **A block on the user stops the plan.** Ask it at once, in the router's question format (rule 3), append `Task N: asked` with the step it came from, and dispatch nothing until they answer; the task's diff stays uncommitted in the tree. When they answer, append `Task N: answered` and go on as the `answered` rule in *Setup* says.

**2. Verify the report before trusting it.** A self-report is a claim. Read the diff. If the report names a command, the claim is that command's output, not the sentence about it. An agent that reports success and changed nothing is a failure mode that occurs.

**3. Dispatch a fresh reviewer** on that task's diff: does it do what the task asked, and does the quality hold? Does the diff honor its `Interfaces` block and the global constraints? Does it contain anything the task didn't ask for? Write the task's diff and untracked files to `task-N-diff.md`. The reviewer gets the paths of `task-N-brief.md`, `task-N-report.md` and `task-N-diff.md`, and the worktree path — not your history. It returns its review, and you write it to `task-N-review.md`. Brief it per `dev-verify`'s `references/review.md`, *The brief* and *Severity*: a minor finding is recorded, not a fix round.

**4. Two fix rounds, maximum.** Rule on the review first, per `dev-verify`'s `references/review.md`, *Besides the findings*. Then:

- **What a round gets:** only the findings to fix — the critical and important ones, and any listed item you confirmed as one. A fix whose expected result only the user can give is a block on the user, asked before any round.
- **Round 1** resumes the task's implementer with those findings when the host can message a live sub-agent: it knows the task and its own choices. Otherwise a fresh implementer gets the brief, the report and the findings.
- **Round 2** is always a fresh implementer one model tier above round 1, with the brief, the report and the findings: a fix that didn't hold once suggests it can't see its own problem.
- **Each round** edits the same uncommitted diff, appends its fix report to `task-N-report.md`, and gets a fresh reviewer — still none of your history.
- **After round 2**, rule on each surviving finding, record the ruling in the ledger, and move on: a plan does not stall on a minor finding.
- **A finding that contradicts what the plan mandates**, in any round: the spec decides — rule and record.

**5. Commit the task** — one commit, the message the plan gives it, per `dev-ship` — append `complete` with its SHA, and start the next task. No progress summaries to the user in between; they asked for the plan to be executed. Each implementer's `Decisions` go into the ledger as `Decision:` lines; `dev-ship` carries them to the PR body.

## After the last task

**A fix from any `dev-verify` gate is not yours to write.** Dispatch a fresh implementer with the finding, the spec requirements it touches and the diff, under a fix round's limits (*Per task*, step 4), but always fresh: no task implementer is left to resume. Every task is already committed, so the fix is a commit of its own, logged `Plan: fix — <finding> — <sha>`.

## Slices

Every plan is cut into slices. Slice 1 runs on the plan's branch, the one the ledger's header names. Each next slice gets its own branch, created from the previous slice's branch in the same tree and logged `Slice K: branch — <branch>`. No stop between slices: the plan's go-ahead covered them.

1. After a slice's last task is `complete`, run `dev-verify` on that slice — its diff against the branch it was cut from. Land its fixes on that branch and append `Slice K: verified — <branch>`.
2. Branch the next slice from it.
3. When the last slice is verified, run gate 2 of `dev-verify` once more, against the whole spec, over the whole stack — a requirement split across slices is checked nowhere else — and append `Plan: verified — <branch>`. The last slice's verification is the pre-PR `dev-verify`; don't run it twice.
4. `dev-ship` integrates the stack.

Resuming: a slice whose tasks are all `complete` but that has no `verified` line gets verified before anything else; every slice verified and no `Plan: verified` line means step 3 hasn't run.

## Model selection

| Task shape | Model |
|---|---|
| Mechanical, isolated, clear spec, 1-2 files | fast |
| Integration, pattern matching, judgment | mid |
| Review | most capable available |
| Fix round 1 | the implementer's own — resumed, or fresh at the same tier |
| Fix round 2 | one tier above round 1, up to the most capable |

Say which model you're dispatching with; an unspecified model is a silent default.

## Without sub-agents

Implement task by task yourself, but keep the ledger, and make each task's review a separate, explicit pass over the diff — reading it as a reviewer would, not leaning on the reasoning you used to write it. Say in the ledger that the review was self-run.
