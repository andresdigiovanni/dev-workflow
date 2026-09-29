---
name: dev-debug
description: Finds the root cause of a bug and the smallest fix that removes it. Use when encountering a bug report, a test that fails unexpectedly or flakes, a crash, an error message, or any behavior that differs from what was expected — before proposing or writing a fix, and when a fix has already been tried and didn't hold. Not for the expected red of a test written first.
---

# Debug

The fix you can write in thirty seconds is usually a fix to the symptom. This skill is the cost of not doing that.

A bug report starts here, not in `dev-explore`: steps 1–3 are the exploration. Once they point to a fix:

- **The fix carries a decision** — a new surface, a behavior change nobody asked for, a mechanism outside the request: ask it in one round, per `dev-implement`, *Sort every decision the request didn't settle*. Load `dev-explore` only when it takes more than one round, or when the fix is *Planned*.
- **Pick the lane by the size of the fix**, entering at `dev-implement` — or at `dev-explore` when the fix is *Planned* or its decisions take more than one round, per the router's *Bug* row.
- **The reproduction test from step 1 is that lane's failing test.** `dev-implement` and `dev-testing` start from it, not from a second one. The lane ends in `dev-verify` and `dev-ship` as usual.

## 1. Reproduce before anything

No fix before a reliable reproduction. If you cannot make it happen on demand, you cannot know you fixed it — you can only know it stopped happening while you were watching.

Write the reproduction **as a failing test** when you can. It becomes the regression test, and it proves the fix at the moment the fix lands.

**Intermittent?** Find what makes it deterministic — an ordering, a timing, a leftover state, a specific input — before anything else. An intermittent bug is a bug you haven't characterized yet.

- **Can't make it happen on demand** from the code, tests and logs you can reach: stop and ask the user for a reproduction or a log (router, rule 3). Don't fix blind.
- **Concurrency:** run the toolchain's race detector if it has one. Force the suspected interleaving with a hook or a barrier, not a sleep. Run the test in a loop: a reproduction that fails 1 run in 20 is proven fixed only by a loop long enough to have caught it.

## 2. The reported mechanism is a hypothesis; only the symptom is evidence

A report says "X is broken because Y". The symptom is data. The `because` is a guess, and it is wrong often enough to matter — a correct conclusion routinely names the wrong line, one surface away.

**The tell:** you write a test against the stated mechanism and it **passes on unmodified code**. That means the report is right and the diagnosis is wrong. Don't conclude the bug isn't real. Keep pushing the test toward the real surface until it goes red.

Trust your reproduction over the report's explanation, including when the report is your own from ten minutes ago.

## 3. Trace to the root cause

Work backwards from the failure. At each step ask what produced this state, and go one level further than feels necessary.

Read the code that actually runs — not the code you expect to run. Verify each assumption instead of inheriting it: the input really is what you think, the branch really is taken, the version really is the one installed.

Stop when you reach something that, if it had behaved correctly, would have prevented the failure — and that isn't itself caused by something upstream. Fixing above that point is symptom treatment, and it moves the bug rather than removing it.

**Green in tests, broken in reality?** Suspect the tests were taught to agree. Check whether the change that introduced the defect also adjusted a fixture, a helper, or a golden file to accept it, or whether a test asserts the defect as intended behavior. See `dev-testing`, *When tests were taught to agree*.

## 4. Rank the fix by what it deletes

The correct fix usually removes something. The ranking is about the shape of the fix; every rank ships with the reproduction test from step 1.

1. **Remove the mechanism** so this class of failure becomes impossible.
2. **Relax a constraint** that was never needed.
3. **A localized fix** — changes one place, adds nothing. The reproduction test is already the guard against its return.
4. **Fix it and add a guard** — only when the cause can come back from places the reproduction test doesn't reach, such as an invariant many call sites can break. The guard is a type, an assertion or a check that makes reintroduction fail in the tests instead of in production. It is never a runtime branch around the symptom.
5. **New surface** — a flag, a state, a verb, a second representation of something already true. Last resort, and a one-way door. Whether it exists is the user's decision: stop and ask. As a delegated implementer, report `blocked` and name it.

Ranks 1 and 2 apply only when the mechanism lies inside what the request covers. When it lies outside, make the localized fix and name the mechanism under the report's follow-ups — rewriting it is a scope decision for the user.

**The over-engineering test, before writing any fix:** does it add a state, a flag, a runtime branch that routes around the failure, or a parallel representation of existing truth? If yes, stop and look for the version that deletes instead. Fixing symptoms one at a time is how a system turns into machinery nobody can maintain.

Restoring a guarantee the design already needed is not new state — awaiting the work before closing what it writes to, holding the lock the invariant assumes. That is the localized fix.

## 5. One root, not N patches

Two or more failures sharing a root cause get **one fix at the root**, closing all of them. N symptoms never justify N patches. Before fixing, check whether this failure belongs to a cluster you already know about.

## 6. When a fix already failed

A fix that didn't hold — yours, or one the report says was tried — is evidence that its hypothesis was wrong. Don't adjust it: discard the hypothesis and go back to step 3 from the reproduction. Revert a failed attempt before the next one, so two guesses never stack.

After two failed fixes, stop patching. Report what each attempt assumed, what the reproduction showed instead, and what you would check next. A third guess at the same layer usually means the problem is in the design, and that is the user's call.

## 7. Prove it

- The reproduction test goes red before the fix and green after. If you watched it fail before writing the fix, that was the red. If the test came after the fix, revert the fix and watch it fail, per `dev-testing`, *Regression tests, proven red*.
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
| Trusting a fix you never saw fail | See step 7 |
