---
name: dev-implement
description: Writes the code for a change. Use before the first edit to any source or test file, however small the change — a new function, a fix, a flag — when executing an approved plan task by task, and when resuming a plan after a context compaction. Not for the Trivial lane: typos, docs, comments, copy.
---

# Implement

Two modes, one discipline. **Load `dev-testing` before writing any test or code, and follow it:** no implementation code before its failing test.

- **Direct mode** — no plan. You write the code. This is the common case: don't reach for delegated mode because the work feels important.
- **Delegated mode** — there is an approved plan. **Read `references/delegated.md` in full before starting, and again after any context compaction.** It holds the ledger, the per-task loop and the resume rules.

## Before either mode

Branch first, per the router.

- **Direct mode** — a branch in the current working tree; anything more costs more than the change. If the tree holds uncommitted work that isn't part of this change, leave it alone and stage by path.
- **Delegated mode** — where the plan runs, and how its worktree is set up: `references/delegated.md`, *Setup*.

## Direct mode — no plan

### 1. Read the code the change lands in

Read the affected code, its callers and its tests. Find how the codebase already does what you're adding — how neighboring code reports errors, names things, validates input, is tested — and follow that pattern. A change that ignores the local pattern gets rewritten in review, or ships as a second way of doing the same thing.

Searches first, whole files only where the change lands.

### 2. Run the baseline, before writing any test or code

Run the project's full test command and keep the result. A test that is red now is not yours: the report names it as pre-existing, with the baseline as the evidence. Without this run, every red test at the end is yours to explain.

On the *Bug* lane, `dev-debug`'s reproduction test is red in this run by design. It is the task, not a pre-existing failure.

### 3. Settle what the request leaves open

Before the first test, write the cases each requested behavior needs (`dev-testing`, *What to cover*), and check that the request, or a convention in the code, fixes the expected result of every one. Typical gaps:

- a count — does "retry 3 times" mean 3 calls or 4?
- what a second call does — does a second discount replace the first or stack on it?
- an input at the edge of what the change adds — a value exactly at a new limit, an empty list passed to a new parameter.

Only behavior the request adds or alters counts. An edge of existing behavior the change doesn't touch is not open, and asking about it grows the scope. "The natural reading" is not a settlement: if you can state a second reading a caller would notice, it is open.

Then sort every decision the request didn't settle, per router rule 3. A caller-observable one — output, errors, defaults, call counts, what is accepted or rejected — a new surface the request doesn't pin down, or a dependency the repo doesn't use and the request doesn't name is the user's; ask a dependency with its cost and the alternative without it. A new surface goes with its four answers (`dev-explore`, *Justify every new surface*); with no request line to quote, drop it and list it as a follow-up. Anything else — a private name, where a helper lives — you decide and record.

**Ask everything open in one round, now, before any code** — one stop instead of several — in the router's question format (rule 3). Then carry on with the answers. Don't build the option you expect them to pick while you wait. A question found only mid-change is asked then, on its own.

### 4. Build it, task by task

Most direct-mode changes are a single task (router, *Terms*). Each task goes test first, per `dev-testing`.

**Forecast the size before the first test.** Past 400 changed lines, tests included, the lane is *Planned*: switch to it, starting at `dev-explore`.

**Changing behavior that existing tests pin?** Edit those tests to the new behavior first and watch them fail; the request is the requirement `dev-verify` traces them to. A new test beside an old one that still asserts the old behavior leaves the suite contradicting itself.

Commit each task per `dev-ship`, *One task, one commit*: in direct mode only the last one waits for `dev-verify`, which is its review. No sub-agents and no per-task review.

**Touch only what the request needs** (router, rule 4): the unrelated bug, the tempting rename, the file that "could use a cleanup" go in the report's follow-ups. Noticed is not debugged — `dev-debug` is for unexpected behavior in what you're changing.

## The ledger

Defined in the router, *Terms*. `dev-explore` or `dev-plan`'s switch starts it on *Explored*, `dev-debug` at a fix that didn't hold, and `references/delegated.md`, *Setup*, for a plan. When there is one, add every decision you settle to it.
