---
name: dev-implement
description: Use when writing or changing code. With a plan, dispatches one fresh sub-agent per task, reviews each before the next starts, and tracks progress in a ledger that survives context compaction. Without a plan, implements directly under the same test discipline. Always paired with dev-testing.
---

# Implement

Two modes, one discipline. Both follow `dev-testing`.

## Before either mode

Work on a branch or a worktree, never on `main` or `master` without the user saying so explicitly.

## Direct mode — no plan

You implement. Test first, per `dev-testing`. Commit per unit of work, per `dev-ship`. No ledger, no sub-agents, no per-task review — `dev-verify` is the review.

This is the common case. Don't reach for delegated mode because the work feels important.

## Delegated mode — there is a plan

### Setup

Read the plan once. Read the spec it names — the spec is the authority, and any conflict inside the plan resolves against it. Note the global constraints; they bind every task.

Create the ledger at `.dev-runs/<slug>.md`, first line `# ledger — plan: <path to plan>`.

**Why the ledger exists:** conversation memory does not survive compaction. The single most expensive failure in this workflow is a coordinator that lost its place and re-ran tasks that were already done. After a compaction, the ledger and `git log` outrank your recollection. A task with a `Task N: complete` line is done — do not re-dispatch it. A task whose last line is a fix round is mid-loop; resume at the next round.

### Per task

**1. Dispatch a fresh implementer.**

It gets exactly this, constructed on purpose:

- the full text of its task
- its `Interfaces` block
- the global constraints
- the slice of the spec its task serves
- the instruction to follow `dev-testing`, and to report in the shape below

It gets **none of your session history**. That isolation is the whole reason delegation works — inherited context is how a sub-agent drifts onto work that isn't its own.

It implements, tests, commits, and reports:

```
Status: done | blocked
Commits: <shas>
Tests: <exact command> → <exact result>
Full suite: <exact command> → <exact result, naming any red test>
Interfaces produced: <what it actually built, signature by signature>
Decisions: <anything the task didn't answer and it had to settle>
```

**2. Verify the report before trusting it.** A self-report is a claim. Read the diff. If the report names a command, the claim is that command's output, not the sentence about it. An agent that reports success and changed nothing is a failure mode that occurs.

**3. Dispatch a fresh reviewer** on that task's diff: does it do what the task asked, and does the quality hold? The reviewer gets the task text and the diff, not your history.

**4. Two fix rounds, maximum.** If findings survive round two: rule on each one, record the ruling in the ledger, and move on. A plan does not stall on a minor finding. If a finding contradicts what the plan mandates, the spec decides — rule and record.

**5. Append to the ledger** and start the next task. No progress summaries to the user in between; they asked for the plan to be executed.

### Model selection

| Task shape | Model |
|---|---|
| Mechanical, isolated, clear spec, 1-2 files | fast |
| Integration, pattern matching, judgment | mid |
| Architecture, design, review | most capable available |
| Fix round after a failed review | one tier above the round before |

Say which model you're dispatching with; an unspecified model is a silent default.

## Without sub-agents

Implement task by task yourself, but keep the ledger, and make each task's review a separate, explicit pass over the diff — reading it as a reviewer would, not leaning on the reasoning you used to write it. Say in the ledger that the review was self-run.

## The fix that shrinks the system

When a task turns out to need a fix rather than an addition, prefer the fix that **deletes**. Ranked:

1. Remove the mechanism so the failure becomes impossible.
2. Add a guard that turns reintroduction into a test failure.
3. A localized fix behind a failing test that reproduces it.
4. New surface — a flag, a state, a verb, a parallel representation of something already true. Last resort.

If a fix adds a state, a flag, or a second way to express an existing truth, stop and look for the version that removes something instead.
