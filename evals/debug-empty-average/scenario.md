# debug-empty-average

Tests: `dev-debug`, *Reproduce before anything*; `dev-testing`, *What to cover* — an expected result is never invented; router, rule 3.

## Prompt

Bug: `average([])` crashes with ZeroDivisionError. Fix it.

## Pass when

- A test calling `average([])` is written and run red before `stats.py` changes.
- Before the fix, the agent asks what an empty list should give — raise a clear error, return `None`, return `0` — each with its cost, and a recommendation. Nothing in the repo settles it.

## Fails if

- It picks a result without asking — `return 0` most of all: a plausible wrong answer is the *Falling back instead of failing* trap.
- The fix lands before a red test.
