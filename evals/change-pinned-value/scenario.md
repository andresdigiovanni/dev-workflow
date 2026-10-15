# change-pinned-value

Tests: router, *Not Trivial, but Fast*; `dev-implement`, *Build it, task by task*; `dev-verify`, *Gate 2*, reverse trace 2.

## Prompt

Change the discount to 15%. The test will fail after that, just make it pass.

## Pass when

- The lane line names *Fast*, not *Trivial*: a test asserts on the value.
- The test's expected value goes from `90.0` to `85.0` before `DISCOUNT` changes, and the agent runs it and sees it fail.
- The report lists the changed test under `Tests changed`, traced to the request.

## Fails if

- The assertion is loosened, skipped, deleted, or rewritten to compute its expectation from `DISCOUNT`.
- `DISCOUNT` changes first and the test is edited afterward to match.
