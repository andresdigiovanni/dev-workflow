---
name: dev-testing
description: Writes tests that would catch a regression, not just pass. Use before writing any implementation code, when adding missing coverage, and when judging whether an existing suite actually holds. Also use when a test passes on its first run, when an existing test goes red after a change, or when a coverage number is being used as evidence.
---

# Testing

A green suite means the tests did not fail. It does not mean they would have.

## 0. Read the repository first

Before writing a test, find the project's test command, test layout, naming conventions, and whether it uses property-based testing. Follow what is there; never invent a command or a convention.

**No test setup at all?** Adding a framework is a new dependency, and that is the user's decision (router, rule 3). Ask, with your recommendation and what it costs. Until they answer, check the behavior by running the real code with a command whose output you can paste, and say in the report that nothing automated covers it.

The same holds for behavior the existing setup can't reach — a visual layout, a deploy script: check it by running it, and say so.

## 1. Test first, and watch it fail

```
write the test  →  run it, see it FAIL  →  minimal code  →  run it, see it PASS  →  refactor
```

**If you did not watch the test fail, you do not know what it tests.** This is the whole rule; the rest is consequence.

- It must **fail**, not error. An error is usually a typo or a bad import, and it proves nothing about behavior.
- It must fail **for the right reason** — the behavior is missing — and the message must say so.
- If it **passes** on the first run, the feature is already there or the test doesn't reach what you think it reaches. Find out which before writing any code.

  The exception is a test written on purpose to pin behavior that must keep working, such as the boundary just inside a new limit. Its first-run green is the expected result; say so.

Then write the smallest code that turns it green — not the general version, not the configurable one. Anything beyond the test is untested code you now maintain. The refactor step tidies the code this change wrote, not the code around it.

**Wrote new behavior before its test?** Delete it and start from the test: keeping it "as reference" lets the implementation shape the test. The one accepted test-after path is a bug fix already written: prove its test red by reverting the fix, per step 5.

**The exceptions:** a prototype the user called throwaway, generated code, and the *Trivial* lane. Everything else — features, bug fixes, behavior changes — goes test first. "It's too small to test" is not an exception: small changes are where the missing test goes unnoticed.

**A refactor** changes no behavior, so there is no failing test to write first. If no test pins the code you're about to move: write one against the current code, break the code once to watch it fail, restore it, then refactor with the suite green before and after.

## 2. What makes a test worth having

**One behavior per test.** A test that checks four things tells you "something broke".

**The name states the guarantee**, not the function under test: `retries three times before giving up` over `test_retry`. When it fails at 3am, the name is the whole message.

**Exercise real code.** Substitute a dependency only when the real one is impractical — the network, the clock, a paid service, something irreducibly slow. Each substitution is where test and reality can silently diverge. A test that asserts only that a substitute was called verifies nothing.

**Deterministic.** No real clock, unseeded randomness, live network or dependence on test order. A test that fails one run in twenty teaches everyone to rerun it instead of reading it.

**Assert on observable behavior** — what the caller gets back, what state is visible afterward, what the system does next. Not on internal structure: a test coupled to private shape breaks on every refactor and catches no bugs.

**Never write a test to raise a coverage number.** Coverage says a line ran. It says nothing about whether anything would notice if that line were wrong. Watching each test fail, step 1, is how you know it would.

## 3. What to cover

For each behavior the change adds or alters, the cases that apply to it:

- the path that works
- each way it is supposed to fail, and what it does when it fails
- the boundaries — empty, one, many, the maximum, one past the maximum, zero, negative
- the invalid inputs that a real caller will actually send
- what remains true afterward when something fails partway through

**Each case needs an expected result, and you don't get to invent one.**

- **The request, the spec or a codebase convention fixes it** — how the code reports a bad argument, what it returns on empty: that is a fact. Write the test.
- **None of them does:** what should happen is the user's decision, not handling to add on your own. In direct mode, ask it in the round before the first test (`dev-implement`, *Settle what the request leaves open*). In a plan, it was asked at the handoff.

Neither invent the handling nor drop the case. A parameter's name hinting at a range is not a decision about what happens outside it.

A test you can't state the purpose of in one sentence is one you don't need.

## 4. Property-based testing

Example tests pin the cases you thought of; property tests cover the space you didn't.

- **Worth it** when the input space is large and something must hold across all of it — an invariant, a round trip, idempotence, two routes that must agree. Then read `references/property-based.md` before writing one.
- **Not worth it** for a function with three meaningful inputs: write the three.

## 5. Regression tests, proven red

A test written *after* a fix has never been seen to fail, so it isn't yet known to test the fix.

```
write the test  →  run it, PASS  →  revert the fix  →  run it, it MUST FAIL
                                 →  restore the fix  →  run it, PASS
```

Without the revert you have a test that passes, not a regression test. The same applies to any guard or assertion added to a green suite: make it fail on purpose once, or you don't know it is connected to anything.

## 6. Green means the whole suite

Before calling anything done, run **the project's full test command**, even when the task named a single file: a scope statement bounds the deliverable, not the verification.

**Every failure it shows goes in the report by name**, including one you did not cause — as pre-existing when the baseline showed it too. A red test left unmentioned is a report falsified by omission.

**An existing test that goes red is evidence, not an obstacle.** Never change its expected value, loosen its assertion, skip it, mark it expected-to-fail, focus it (`only`) or delete it to get green — unless a requirement, in the request or the spec, changes the behavior it pins. Then name that requirement in the report. A test that pins the bug being fixed counts: the bug report is the requirement. A pre-existing red the request doesn't cover stays red; fixing it is a follow-up.
