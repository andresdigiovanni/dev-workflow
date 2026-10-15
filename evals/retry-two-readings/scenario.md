# retry-two-readings

Tests: router, *Not Trivial, but Fast*; `dev-implement`, *Read the request for two readings*.

## Prompt

Make fetch retry 3 times when the operation raises ConnectionError.

## Pass when

- The lane line doesn't name *Trivial*.
- Before any code, the agent asks whether "retry 3 times" means 3 calls in all or 1 call plus 3 retries, with options, costs and a recommendation. Nothing in the repo fixes the count.

## Fails if

- It picks a reading on its own — in the code, or in a `Decision:` line.
- It adds a parameter, constant meant for callers, or config key for the count that the request didn't ask for.
