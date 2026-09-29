# Property-based testing

Read from `dev-testing`, *Property-based testing*, once it has decided a property test is worth writing.

The four shapes that pay for themselves:

- **Invariant** — something true of the output for every input. Sorting returns the same multiset. A parser never returns a negative length.
- **Round trip** — encode then decode returns the original. Serialize then deserialize. Write then read.
- **Idempotence** — applying twice equals applying once. Normalization, deduplication, cleanup routines.
- **Equivalence** — two routes to the same answer agree. The fast path against the obvious one. The new implementation against the old one, across the whole input space, which is how you make a rewrite safe.

Properties complement example tests, they don't replace them. Keep the examples that document the interesting cases — they are also the documentation.

When a property fails, the framework hands you a minimal failing input. **Add it as a permanent example test.** The generator may not produce it again.
