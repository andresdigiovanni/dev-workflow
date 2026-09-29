---
name: dev-implement
description: Writes the code for a change. Use when writing or changing code from a request or a spec, when executing an approved plan task by task, and when resuming a plan after a context compaction. Always paired with dev-testing.
---

# Implement

Two modes, one discipline. **Load `dev-testing` before writing any test or code, and follow it:** no implementation code before its failing test.

- **Direct mode** — no plan. You write the code. This is the common case: don't reach for delegated mode because the work feels important.
- **Delegated mode** — there is an approved plan. **Read `references/delegated.md` in full before starting, and again after any context compaction.** It holds the ledger, the per-task loop and the resume rules.

## Before either mode

Branch first, per the router's *Git*.

- **Direct mode** — a branch in the current working tree; anything more costs more than the change. If the tree holds uncommitted work that isn't part of this change, leave it alone and stage by path.
- **Delegated mode** — one worktree for the whole plan, on its own branch, when the tree has uncommitted changes other than this plan's spec and plan; a branch otherwise. Sub-agents and the user then never write to the same files.

## Direct mode — no plan

### 1. Read the code the change lands in

Read the affected code, its callers and its tests. Find how the codebase already does what you're adding — how neighboring code reports errors, names things, validates input, is tested — and follow that pattern. A change that ignores the local pattern gets rewritten in review, or ships as a second way of doing the same thing.

Searches first, whole files only where the change lands.

### 2. Run the suite once, before any edit

Run the project's full test command and keep the result. A test that is red now is not yours: the report names it as pre-existing, with this run as the evidence. Without this run, every red test at the end is yours to explain.

On the *Bug* lane, `dev-debug`'s reproduction test is red in this run by design. It is the task, not a pre-existing failure.

### 3. Read the request for two readings

Before the first test, write the cases each requested behavior needs (`dev-testing`, *What to cover*). Check that the request, or a convention in the code, fixes the expected result of every one. Typical gaps:

- a count — does "retry 3 times" mean 3 calls or 4?
- what a second call does — does a second discount replace the first or stack on it?
- an input at the edge of what the change adds — a value exactly at a new limit, an empty list passed to a new parameter.

Only behavior the request adds or alters counts. An edge of existing behavior the change doesn't touch is not open, and asking about it grows the scope.

"The natural reading" is not a settlement. If you can state a second reading a caller would notice, it is open, however good your argument for the first.

### 4. Sort every decision the request didn't settle

| The decision | Whose | What to do |
|---|---|---|
| Changes what a caller can observe — output, errors, defaults, call counts, what is accepted or rejected | The user's (router, rule 2) | Ask it |
| Adds a new surface the request doesn't pin down | The user's | Ask it with four answers: the request line that needs it, the caller that uses it now, the existing surface that could absorb it, and its smallest shape. No request line to quote: drop it, list it as a follow-up |
| Needs a dependency the repo doesn't use and the request doesn't name | The user's (router, rule 3) | Ask it: the dependency, its cost, the alternative without it |
| Changes nothing observable — a private name, where a helper lives, the order of two statements | Yours | Decide it and record `Decision: <what> — <why> — <cost if wrong>` |

**The tell:** before writing a `Decision:` line, read its `cost if wrong`. If it names something a caller would see — an extra call, a different result, an error raised or not — and neither the request nor a convention in the code fixes it, the decision isn't yours to record. Ask it.

**Ask everything open in one round, now, before any code** — one stop instead of several. Open with the facts the questions rest on, one line each with the path that proves it, then each question in this format:

```
❓ **Q1 — <short title>**: <the question>
- **A — <option>**: <what it costs> / <what it buys>
- **B — <option>**: <what it costs> / <what it buys>
➡️ <your recommendation and the one reason that decides it>
```

Then carry on with the answers. Don't build the option you expect them to pick while you wait. A question found only mid-change is asked then, on its own.

### 5. Build it, task by task

A task is what `dev-ship` defines; most direct-mode changes are a single task. Each task goes test first, per `dev-testing`.

- **Every task but the last** is committed, per `dev-ship`, once its tests and the full suite pass.
- **The last task** — the only one, in most changes — is committed after `dev-verify`, so its review fixes land in it.

No sub-agents and no per-task review: `dev-verify` is the review.

**Touch only what the request needs.** The unrelated bug, the tempting rename, the file that "could use a cleanup": note it for the report's follow-ups, don't fix it. Noticed is not debugged — `dev-debug` is for unexpected behavior in what you're changing. `dev-verify` traces every changed line back to the request and removes what traces to nothing.

## The fix that shrinks the system

In either mode, when a task turns out to need a fix rather than an addition, it is a bug: follow `dev-debug` and rank the fix by what it deletes. New surface is the last resort, never the first reach.

## The ledger

The ledger is what `dev-verify` checks against once the conversation is compacted.

- **`dev-explore` ran:** the settled request and decisions are already in it. Add every decision you settle along the way.
- **Fast lane, something was asked or decided:** start it at the first question or decision. It is `.dev-runs/<slug>.md`, with a `Request:` line — the request as the user wrote it — then the answers and the `Decision:` lines. If the repo doesn't ignore `.dev-runs/`, add it to the file `git rev-parse --git-path info/exclude` names.
- **Nothing asked and nothing decided:** no ledger. `dev-verify` reads the request in the conversation.
