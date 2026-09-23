---
name: dev-verify
description: Use before claiming work is complete, fixed, or passing, and before opening a PR or merging. Three gates in order — fresh evidence from the full suite and build, line-by-line compliance against the spec or plan, and one fresh reviewer on the whole-branch diff.
---

# Verify

Three gates, in this order. Each one catches what the previous cannot.

## Gate 1 — Evidence

**No completion claim without fresh verification output.** If you have not run the command in this turn, you cannot say it passes.

Run, and read the output:

- the project's **full** test suite, not the files you touched
- the linter and formatter the repo uses
- the build, if there is one

For each: the exact command, the exit code, the counts. Paste what it printed.

**Every red test gets named** — including one you did not cause. A failure you saw and did not mention is a report falsified by omission.

| Claim | What proves it | What does not |
|---|---|---|
| Tests pass | Suite output, 0 failures, this turn | A previous run; "should pass" |
| Linter clean | Linter output, 0 errors | A partial check |
| Build works | Build exit 0 | The linter passing |
| Bug fixed | The original symptom, re-tested | The code changed |
| Regression test works | Red-green verified by reverting the fix | It passes once |
| Sub-agent finished | The diff, read by you | Its success report |

Stop if you are about to write "should", "probably", "seems to", "looks correct", or any satisfied noise before the command has run. Those words are what not verifying sounds like.

## Gate 2 — Compliance

Tests passing is not the same as building what was asked.

Re-read the spec, or the plan, or the original request. Make a line-by-line checklist: **every requirement → where it is implemented → which test covers it.**

Report the gaps as gaps. A requirement with no implementation, or an implementation with no test, is an open item, not a rounding error. If the work deliberately diverged from the spec, say so and say why — a decision recorded is fine, a decision hidden is not.

Check the global constraints too: version floors, dependency limits, naming and copy rules. They bind everything and nothing tests them.

## Gate 3 — Fresh review

Dispatch **one** reviewer sub-agent over the whole-branch diff.

It gets purpose-built context — the spec or requirements, the base and head commits, a short description of what was built — and **not your session history**. A reviewer that inherits your reasoning re-derives your blind spots.

Ask it for: correctness bugs with the input that triggers them, requirements the diff misses, and quality problems worth fixing now. Ranked, most severe first.

Coming back:

- **Fix the critical and important findings** before shipping.
- **Record the minor ones** rather than silently dropping them.
- **Push back when the reviewer is wrong** — with the test or the code that proves it, not with agreement. Performative acceptance of a wrong finding is how correct code gets broken.
- **A finding you disagree with but cannot disprove is not resolved.** Say so.

If the runtime already has a good native code review, gate 3 can use it instead of a sub-agent.

## Without sub-agents

Do gate 3 as a deliberate separate pass: get the full diff, read it as a reviewer with the spec beside you, and write the findings down before deciding anything about them. Say in the report that the review was self-run — it is weaker evidence and the user should know.

## Report

```
Suite:      <command> → <result>
Lint/build: <command> → <result>
Spec:       <n> requirements, <n> covered, gaps: <list or none>
Review:     <n> findings — <n> fixed, <n> recorded, <n> disputed
Open:       <anything a reader would want to know before merging>
```
