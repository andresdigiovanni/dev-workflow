---
name: dev-testing
description: Use before writing any implementation code, when adding missing coverage, and when judging whether an existing suite actually holds. Covers the test-first cycle, what makes a test worth having, property-based testing, and mutation testing as proof the suite would catch a regression. Language-agnostic — detect the repository's own tooling and conventions before writing anything.
---

# Testing

A green suite means the tests did not fail. It does not mean they would have.

Everything here is about the difference.

## 0. Read the repository first

Before writing a test: find the project's test command, its existing test layout, its naming conventions, and whether it already runs property-based or mutation testing. Follow what is there. Never invent a command or a convention — run what the repo runs.

## 1. Test first, and watch it fail

```
write the test  →  run it, see it FAIL  →  minimal code  →  run it, see it PASS  →  refactor
```

**If you did not watch the test fail, you do not know what it tests.** This is the whole rule; the rest is consequence.

Verifying the red is not a formality:

- It must **fail**, not error. An error is usually a typo or a bad import, and a test that errors proves nothing about behavior.
- It must fail **for the right reason** — the behavior is missing — and the message must say so.
- If it **passes** on the first run, you wrote a test for behavior that already exists. Either the feature is already there, or the test doesn't reach the thing you think it reaches. Find out which before writing any code.

Then write the smallest code that turns it green. Not the general version, not the configurable version. The test defines the scope; anything beyond it is untested code you now have to maintain.

Write code before the test? Delete it and start from the test. Keeping it "as reference" and adapting it means the test gets shaped by the implementation, which is the failure this rule prevents.

**The exceptions, named so that skipping is a decision and not a habit:** throwaway prototypes, generated code, configuration files. Everything else — features, bug fixes, refactors, behavior changes — goes test first.

## 2. What makes a test worth having

**One behavior per test.** A test that checks four things tells you "something broke".

**The name states the guarantee**, not the function under test. `retries three times before giving up` over `test_retry`. When it fails at 3am the name is the whole message.

**Exercise real code.** Substitute a dependency only when using the real one is genuinely impractical — the network, the clock, a paid service, something irreducibly slow. Every substitution is a place where the test and reality can diverge silently. A test built mostly out of substitutes verifies your model of the system, not the system; when it asserts only that a substitute was called, it verifies nothing at all.

**Assert on observable behavior** — what the caller gets back, what state is visible afterward, what the system does next. Not on internal structure: a test coupled to private shape breaks on every refactor and catches no bugs.

**Never write a test to raise a coverage number.** Coverage says a line ran. It says nothing about whether anything would notice if that line were wrong. Section 5 is how you find out.

## 3. What to cover

For each behavior:

- the path that works
- each way it is supposed to fail, and what it does when it fails
- the boundaries — empty, one, many, the maximum, one past the maximum, zero, negative
- the invalid inputs that a real caller will actually send
- what remains true afterward when something fails partway through

A test you can't state the purpose of in one sentence is one you don't need.

## 4. Property-based testing

Example tests pin the cases you thought of. Property tests cover the space you didn't.

**Worth it when** the input space is large and there is something that must hold across all of it. **Not worth it** for a function with three meaningful inputs — write the three.

The four shapes that pay for themselves:

- **Invariant** — something true of the output for every input. Sorting returns the same multiset. A parser never returns a negative length.
- **Round trip** — encode then decode returns the original. Serialize then deserialize. Write then read.
- **Idempotence** — applying twice equals applying once. Normalization, deduplication, cleanup routines.
- **Equivalence** — two routes to the same answer agree. The fast path against the obvious one. The new implementation against the old one, across the whole input space, which is how you make a rewrite safe.

Properties complement example tests, they don't replace them. Keep the examples that document the interesting cases — they are also the documentation.

When a property fails, the framework hands you a minimal failing input. **Add it as a permanent example test.** The generator may not produce it again.

## 5. Mutation testing — the proof the suite works

The suite tells you nothing about itself. Mutation testing does.

**The method:** introduce a small change to the source that breaks its meaning — flip a comparison, change a boundary, swap an operator, remove a call, alter a returned constant. Run the suite. A suite that does its job goes red. **A mutant that survives is a change to your code that no test noticed.**

That is the only direct measurement of whether the tests would catch a regression. Coverage measures execution; mutation measures detection.

For each surviving mutant, decide which of three it is:

1. **A missing test** — the behavior matters and nothing checks it. Write it.
2. **A semantically equivalent change** — the mutation doesn't alter observable behavior. Nothing to do; say why.
3. **Outside the useful boundary** — logging, a debug path, something genuinely untestable. Say which, and say it explicitly.

**A task is not finished while a relevant surviving mutant is unexplained.** "The suite passes" and "the suite would catch this" are different claims, and only mutation testing supports the second.

If the repo has a mutation tool configured, run it. If it doesn't, you can still do this by hand on the code you just wrote: change the boundary, run the tests, put it back. It takes a minute and it is how you find out your new test asserts nothing.

## 6. Regression tests, proven red

A test written *after* a fix has never been seen to fail, so it isn't yet known to test the fix.

```
write the test  →  run it, PASS  →  revert the fix  →  run it, it MUST FAIL
                                 →  restore the fix  →  run it, PASS
```

Without the revert you have a test that passes. You don't have a regression test. The same applies to any guard or assertion added to an existing green suite: make it fail on purpose once, or you don't know it is connected to anything.

## 7. When tests were taught to agree

Broken in production, green in the suite, is a specific and common shape. Before you believe the suite:

- Check whether the change that introduced the defect **also changed a fixture, a helper, or a golden file** to accept it. That removes the broken shape from the test surface at the exact moment it becomes broken.
- Check for a test that **asserts the defect as intended behavior**. Delete it rather than leaving a test that pins a bug in place.
- Check that the test reaches the real surface. A test that passes against unmodified code is not testing the change.

## 8. Green means the whole suite

Your test passing is not the suite passing. Before calling anything done, run **the project's full test command**, even when the task named a single file.

A scope statement bounds the deliverable, not the verification. Any failure that run shows — including one you did not cause — goes in your report by name. A red test you watched scroll past and did not mention is a report falsified by omission.
