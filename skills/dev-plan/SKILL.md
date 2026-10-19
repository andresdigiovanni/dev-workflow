---
name: dev-plan
description: Turns a spec into a task-by-task implementation plan with exact interfaces between tasks. Use when work is forecast past 400 changed lines — the tasks will be handed to sub-agents that cannot see each other's context. Skip at 400 or fewer, however many tasks or files.
---

# Plan

Write the plan for someone skilled who knows nothing about this codebase, will read the tasks out of order, and cannot ask you questions. That constraint is what makes the plan worth writing.

## Questions first

The plan starts from `dev-explore`'s spec. Mapping the tasks can uncover an open surface, a dependency or a caller-observable behavior the spec leaves unsettled. Ask those before writing the plan, in one round, in the router's question format (rule 3), each surface with its four answers (`dev-explore`, *Justify every new surface*). Anything found later is asked at the *Handoff*.

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
- In an existing codebase, follow its patterns. Don't restructure unilaterally. Splitting a file you're already modifying, and that has grown unwieldy, is fair.

**Then forecast the size**, tests included. Past 400 changed lines review quality drops off a cliff, so every plan is cut into slices of at most 400 that each ship as their own chained PR, per `dev-ship`. Mark where each slice starts with a `## Slice K: <name>` heading above its first task. A forecast of 400 or fewer: say the switch to *Explored*, with the spec as its authority — ask for the go-ahead on the spec alone, commit it as the first commit on a branch in the current tree, start the ledger, and build it in `dev-implement`'s direct mode.

## Task structure

A task (router, *Terms*) is sized to be worth a fresh reviewer's gate.

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

**Mirror:** `exact/path/existing.py` — `<function or class>`: the existing
code this task follows for errors, naming, validation and tests — or
`none — no precedent`

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

**A wide mechanical change** — a rename or a retype that breaks many call sites at once — can't land as one green task. Sequence it in tasks that are each green: *expand*, the new form beside the old; *migrate* the callers in batches, one task per batch; *contract*, removing the old form once nothing uses it.

**The `Interfaces` block is the load-bearing part.** An implementer sees only their own task, so this block is the only way they learn the names and types their neighbors use. Tasks sent to sub-agents without it produce code that doesn't connect.

**`Mirror` carries the local pattern.** The implementer doesn't know how this codebase reports errors or names its tests, and code that ignores that ships as a second way of doing the same thing. Name code that exists; when nothing comparable does, say so — never invent a pattern.

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
3. **Interfaces agree.** Does Task 7 call it `clear_layers` where Task 3 defined `clear_full_layers`? For every pair of tasks sharing a file or an interface: does what one produces match what the other consumes? For every task on its own: do the tests it specifies match the code it specifies? A mismatch found now isn't found in round three of a fix loop.
4. **The input nobody tests.** What input does the spec imply but no task's tests exercise? Name the most likely ones and settle each per `dev-testing`, *What to cover*: a codebase convention's result is a test in the task that owns the code; anything else is asked per *Handoff*.
5. **Nothing beyond the spec.** Every task, and every file in its `Files`, serves a requirement you can point at: a cleanup, a refactor "while we're there", a helper no requirement needs is scope the user didn't ask for — cut it, or move it to the spec's out-of-scope list as a follow-up. Every public surface a task produces appears under the spec's contracts with the same shape, and in that task's `Produces`; the implementer treats anything missing from its `Interfaces` block as not its to add. A task that exports more than the contracts: make the extra private or cut it.
6. **Mirrors.** Every task that adds code names a `Mirror` that exists — open it — or says there is none.

Fix inline and move on. No second pass.

## Builder check

Then read `references/builder-check.md` and run it: a fresh sub-agent reads spec and plan as an implementer who can't ask, and returns the questions a wrong guess would cost.

## Handoff

1. Save to `docs/plans/YYYY-MM-DD-<slug>.md`, or where the repo already keeps plans.
2. Link it, and the spec when `dev-explore` wrote one this session and it isn't approved yet.
3. Ask, in one round: every question for the user found since *Questions first*, the self-review's and the builder check's included; where the plan runs, with the options in `dev-implement`'s `references/delegated.md`, *Setup* — unless that section says it is already settled; and the go-ahead on spec and plan. Each is its own question, never folded into the go-ahead. Implementation waits for every answer.

A change they ask for in the spec reaches the plan too: update both, re-run the self-review, and hand them back.

**Once approved**, spec and plan go in together as the first commit on the work branch — `docs: spec and plan for <slug>`, in the repo's commit convention — so every task commit after it argues from a committed authority. Create the branch or worktree that was settled first, per `dev-implement`'s `references/delegated.md`, *Setup*. Move the two files there if they were written elsewhere, and stage them by path.
