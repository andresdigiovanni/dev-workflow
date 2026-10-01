---
name: dev-plan
description: Turns a spec into a task-by-task implementation plan with exact interfaces between tasks. Use when work spans more than three commits — the tasks will be handed to sub-agents that cannot see each other's context. Skip for three commits or fewer, however many files they touch.
---

# Plan

Write the plan for someone skilled who knows nothing about this codebase, will read the tasks out of order, and cannot ask you questions. That constraint is what makes the plan worth writing.

## Skip this skill at three commits or fewer

However many files they touch, and even when one task consumes another's function. Below that bar one agent writes every task in direct mode, so the plan costs more than it saves: `dev-implement` works straight from the request, or from the ledger `dev-explore` wrote.

## Questions first

The plan starts from `dev-explore`'s spec. Mapping the tasks can uncover an open surface, a dependency or a caller-observable behavior the spec leaves unsettled. Ask those before writing the plan, in one round, per `dev-explore`, *Single round*.

Only what the self-review turns up is asked at the handoff, each as its own question above the go-ahead — never folded into it.

## Header

```markdown
# <Feature> — implementation plan

**Goal:** <one sentence>
**Spec:** <path> — the spec is the authority; this plan argues from it
**Approach:** <2-3 sentences>

## Global constraints
<project-wide requirements from the spec: version floors, dependency
limits, naming and copy rules. One line each, exact values copied
verbatim. Every task's requirements implicitly include this section.>
```

## Map the files first

Before defining any task, list what gets created and modified, and what each file is responsible for. Decomposition decisions get locked in here, not inside the tasks.

- One clear responsibility per file. Files that change together live together: split by responsibility, not by technical layer.
- Prefer focused files. You reason better about code you can hold in context at once, and your edits are more reliable when the file is small.
- In an existing codebase, follow its patterns. Don't restructure unilaterally. Splitting a file you're already modifying, and that has grown unwieldy, is fair.

**Then forecast the size.** Past roughly 400 changed lines, cut the plan into slices that each ship as their own chained PR, per `dev-ship`. Mark where each slice starts with a `## Slice K: <name>` heading above its first task. Slicing now is cheap; re-cutting commits afterwards is not.

## Task structure

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate.

- Fold setup, config and docs into the task whose deliverable needs them.
- Split only where a reviewer could reject one task and approve its neighbor.
- Every task ends in something independently testable.

````markdown
### Task N: <name>

**Files:**
- Create: `exact/path/new.py`
- Modify: `exact/path/existing.py` — `<function or class>` (a symbol, not
  line numbers: earlier tasks shift the lines)
- Test: `tests/exact/path/test_new.py`

**Interfaces:**
- Consumes: <exact signatures produced by earlier tasks>
- Produces: <exact function names, parameter and return types that later
  tasks rely on — and every public surface from the spec's contracts that
  this task creates, in the contract's exact shape>

**Step 1 — write the failing test**
<the actual test code>

**Step 2 — run it, confirm it fails**
Run: `<exact command>`
Expected: FAIL, <the specific message>

**Step 3 — minimal implementation**
<the actual code for anything another task consumes or that takes a
judgment call; for mechanical code, the exact behavior in a line or two —
the test in Step 1 already pins it>

**Step 4 — run it, confirm it passes**
Run: `<exact command>` and then the project's full suite
Expected: PASS, suite green

**Step 5 — commit message**
`<subject>` — the coordinator commits once the task's review is through
````

**A refactor task** has no failing test to write. Step 1 pins the current behavior instead, and Step 2 confirms the test is connected by breaking the code once and watching it fail, per `dev-testing`.

**The `Interfaces` block is the load-bearing part.** An implementer sees only their own task, so this block is the only way they learn the names and types their neighbors use. Tasks sent to sub-agents without it produce code that doesn't connect.

**Each step is one action.** A Step 3 too large for a reviewer to read in one pass means the task is two tasks.

**The plan is not edited during execution.** Progress lives in the ledger and `git log`, so the plan never needs a commit of its own mid-run.

## No placeholders

These are plan failures, not shortcuts:

- "TBD", "implement later", "fill in details"
- "Add appropriate error handling" / "handle edge cases" / "add validation"
- "Write tests for the above" without the test code
- "Same as Task N" without repeating the code — tasks get read out of order
- A step that says what to do without showing how. A mechanical implementation described exactly, with its test written out, counts as shown
- A reference to a type, function or method that no task defines

## Self-review

Run this yourself once the plan is written, with the spec open — not a sub-agent.

1. **Spec coverage.** Walk each requirement in the spec and point at the task that implements it. List the gaps and close them.
2. **Placeholders.** Search for every pattern above. Fix what you find.
3. **Name and type consistency.** Does Task 7 call it `clear_layers` where Task 3 defined `clear_full_layers`? That is a bug, found now instead of in round three of a fix loop.
4. **Task agreement.** For every pair of tasks sharing a file or an interface: does what one produces match what the other consumes? For every task on its own: do the tests it specifies match the code it specifies?
5. **The input nobody tests.** What input does the spec imply but no task's tests exercise? The spec's silence about an input is not permission for that input to crash. Name the most likely ones.
   - **The codebase has a convention for it** — how it reports a bad argument, what it returns on empty: the expected result is a fact. Add the test to the task that owns the code.
   - **It doesn't:** what should happen is the user's decision, not extra handling to add on your own. Ask it at the handoff, per *Questions first*.
6. **Surfaces.** Every public surface a task produces appears under the spec's contracts with the same shape, and in that task's `Produces`. The implementer treats anything missing from its `Interfaces` block as not its to add. A task that exports more than the contracts is adding scope: make the extra private or cut it.
7. **Nothing beyond the spec.** Every task, and every file in its `Files`, serves a requirement you can point at. A task that serves none — a cleanup, a refactor "while we're there", a helper no requirement needs — is scope the user didn't ask for. Cut it, or move it to the spec's out-of-scope list as a follow-up.

Fix inline and move on. No second pass.

## Handoff

1. Save to `docs/plans/YYYY-MM-DD-<slug>.md`.
2. Link it, and the spec when `dev-explore` wrote one this session and it isn't approved yet.
3. Wait for the user's go-ahead before implementation starts. One go-ahead covers both.

A change they ask for in the spec reaches the plan too: update both, re-run the self-review, and hand them back.

**Once approved**, spec and plan go in together as the first commit on the work branch — `docs: spec and plan for <slug>`, in the repo's commit convention — so every task commit after it argues from a committed authority. Settle where the plan runs per `dev-implement`, *Before either mode*, and create that branch or worktree first. Move the two files there if they were written elsewhere, and stage them by path.
