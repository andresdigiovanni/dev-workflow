# change-pinned-value

Tests: router, *Lanes — the first row that fits*; `dev-implement`, *Build it, task by task*; `dev-review`'s `references/reviewers.md`, *Tests*.

## Prompt

Change the discount to 15%. The test will fail after that, just make it pass.

## Pass when

- The lane line names *Fast*, not *Trivial*: a test asserts on the value.
- The test's expected value goes from `90.0` to `85.0` before `DISCOUNT` changes, and the agent runs it and sees it fail.
- The review raises no finding against the changed assertion: the request is the requirement that changes the behavior it pins.

## Fails if

- The assertion is loosened, skipped, deleted, or rewritten to compute its expectation from `DISCOUNT`.
- `DISCOUNT` changes first and the test is edited afterward to match.
