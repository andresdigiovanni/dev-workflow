---
name: dev-debug
description: Use when encountering a bug, a test failure, or any unexpected behavior, before proposing or writing a fix. Reproduce first, trace to the root cause, fix the cause rather than the symptom, and prefer the fix that deletes a mechanism over the one that adds a guard.
---

# Debug

The fix you can write in thirty seconds is usually a fix to the symptom. This skill is the cost of not doing that.

## 1. Reproduce before anything

No fix before a reliable reproduction. If you cannot make it happen on demand, you cannot know you fixed it — you can only know it stopped happening while you were watching.

Write the reproduction **as a failing test** when you can. It becomes the regression test, and it proves the fix at the moment the fix lands.

Intermittent? Find what makes it deterministic — an ordering, a timing, a leftover state, a specific input — before doing anything else. An intermittent bug is a bug you haven't characterized yet.

## 2. The reported mechanism is a hypothesis; only the symptom is evidence

A report says "X is broken because Y". The symptom is data. The `because` is a guess, and it is wrong often enough to matter — a correct conclusion routinely names the wrong line, one surface away.

**The tell:** you write a test against the stated mechanism and it **passes on unmodified code**. That means the report is right and the diagnosis is wrong. Don't conclude the bug isn't real. Keep pushing the test toward the real surface until it goes red.

Trust your reproduction over the report's explanation, including when the report is your own from ten minutes ago.

## 3. Trace to the root cause

Work backwards from the failure. At each step ask what produced this state, and go one level further than feels necessary.

Read the code that actually runs — not the code you expect to run. Verify each assumption instead of inheriting it: the input really is what you think, the branch really is taken, the version really is the one installed.

Stop when you reach something that, if it had behaved correctly, would have prevented the failure — and that isn't itself caused by something upstream. Fixing above that point is symptom treatment, and it moves the bug rather than removing it.

**Green in tests, broken in reality?** Suspect the tests were taught to agree. Check whether the change that introduced the defect also adjusted a fixture, a helper, or a golden file to accept it, or whether a test asserts the defect as intended behavior. See `dev-testing` §7.

## 4. Rank the fix by what it deletes

The correct fix usually removes something. Ranked:

1. **Remove the mechanism** so this class of failure becomes impossible.
2. **Relax a constraint** that was never needed.
3. **Add a guard** that turns reintroduction into a test failure.
4. **A localized fix** behind the failing test that reproduces it.
5. **New surface** — a flag, a state, a verb, a second representation of something already true. Last resort, and a one-way door.

**The over-engineering test, before writing any fix:** does it add a state, a flag, a gate, or a parallel representation of existing truth? If yes, stop and look for the version that deletes instead. Fixing symptoms one at a time is how a system turns into machinery nobody can maintain.

## 5. One root, not N patches

Two or more failures sharing a root cause get **one fix at the root**, closing all of them. N symptoms never justify N patches. Before fixing, check whether this failure belongs to a cluster you already know about.

## 6. Prove it

- The reproduction test goes red before the fix and green after. Verify both directions — revert the fix and watch it fail. See `dev-testing` §6.
- The full suite is green.
- The original reported symptom is re-tested in the original conditions, not approximated.

## Common traps

| Trap | What it looks like |
|---|---|
| Fixing the first thing you find | The first suspicious line is rarely the cause |
| Changing things to see what happens | If you can't say why a change should work, you're guessing; guesses that work hide the real bug |
| Widening a `try`/`catch` | That deletes the evidence, not the bug |
| Adding a retry or a wait | Waiting on a condition is fine; waiting on a duration hides a race |
| "It works now" after several changes | Undo them one at a time until you know which one mattered |
| Trusting a fix you never saw fail | See §6 |
