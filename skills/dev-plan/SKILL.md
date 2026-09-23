---
name: dev-plan
description: Use when work spans more than about three tasks, touches more than two files, or creates an interface another task will consume — especially when tasks will be handed to sub-agents that cannot see each other's context. Produces a task-by-task plan with exact file maps, interface contracts, and test-first steps. Skip for changes confined to one or two files with no new interfaces.
---

# Plan

Write the plan for someone skilled who knows nothing about this codebase, will read the tasks out of order, and cannot ask you questions. That constraint is what makes the plan worth writing.

## Skip this skill when all three hold

- Three tasks or fewer.
- Two files or fewer.
- No new interface that another task will consume.

Below that bar the plan costs more than it saves — `dev-implement` works straight from the request or the spec.

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

- One clear responsibility per file. Files that change together live together — split by responsibility, not by technical layer.
- Prefer focused files. You reason better about code you can hold in context at once, and your edits are more reliable when the file is small.
- In an existing codebase, follow its patterns. Don't restructure unilaterally; splitting a file you're already modifying and that has grown unwieldy is fair.

## Task structure

A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate. Fold setup, config and docs into the task whose deliverable needs them. Split only where a reviewer could reject one task and approve its neighbor. Every task ends in something independently testable.

````markdown
### Task N: <name>

**Files:**
- Create: `exact/path/new.py`
- Modify: `exact/path/existing.py:123-145`
- Test: `tests/exact/path/test_new.py`

**Interfaces:**
- Consumes: <exact signatures produced by earlier tasks>
- Produces: <exact function names, parameter and return types that later
  tasks rely on>

- [ ] **Step 1 — write the failing test**
<the actual test code>

- [ ] **Step 2 — run it, confirm it fails**
Run: `<exact command>`
Expected: FAIL, <the specific message>

- [ ] **Step 3 — minimal implementation**
<the actual code>

- [ ] **Step 4 — run it, confirm it passes**
Run: `<exact command>` and then the project's full suite
Expected: PASS, suite green

- [ ] **Step 5 — commit**
`git commit -m "<message>"`
````

**The `Interfaces` block is the load-bearing part.** An implementer sees only their own task. This block is the only way they learn the names and types their neighbors use. A plan whose tasks go to sub-agents without it will produce code that doesn't connect.

Each step is one action, two to five minutes.

## No placeholders

These are plan failures, not shortcuts:

- "TBD", "implement later", "fill in details"
- "Add appropriate error handling" / "handle edge cases" / "add validation"
- "Write tests for the above" without the test code
- "Same as Task N" without repeating the code — tasks get read out of order
- A step that says what to do without showing how
- A reference to a type, function or method that no task defines

## Self-review

Run this yourself once the plan is written, with the spec open. Not a sub-agent.

1. **Spec coverage.** Walk each requirement in the spec. Point at the task that implements it. List the gaps and close them.
2. **Placeholders.** Search for every pattern above. Fix what you find.
3. **Name and type consistency.** Does Task 7 call it `clear_layers` where Task 3 defined `clear_full_layers`? That is a bug, found now instead of in round three of a fix loop.
4. **Task agreement.** For every pair of tasks sharing a file or an interface: does what one produces match what the other consumes? For every task on its own: do the tests it specifies match the code it specifies?
5. **The input nobody tests.** What input does the spec imply but no task's tests exercise? The spec says what the software must do, not everything it will meet; its silence about an input is not permission for that input to crash. Name the most likely ones and add each test to the task that owns the code.

Fix inline and move on. No second pass.

## Handoff

Save to `docs/plans/YYYY-MM-DD-<slug>.md`, link it, and ask the user to read it before implementation starts.
