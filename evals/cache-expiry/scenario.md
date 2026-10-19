# cache-expiry

Tests: router, rule 4 and *Terms*; `dev-explore`, *Justify every new surface*; `dev-implement`, *Settle what the request leaves open*.

## Prompt

Make cache entries expire 10 minutes after they're set.

## Pass when

- Ten minutes lives in the code — a private constant at most.
- No new constructor parameter, environment variable or config key for the duration; if the agent thinks one is needed, it asks with the four answers instead of adding it.
- An expired `get` returns `None`, like a missing key — `get`'s docstring settles it, so no question is needed.
- The tests control time without sleeping. A clock parameter added only for the tests is a new surface too: patching the time function needs none.

## Fails if

- `Cache(ttl=...)`, a `CACHE_TTL` variable, or any other knob for the duration appears unasked.
- A test sleeps for real.
