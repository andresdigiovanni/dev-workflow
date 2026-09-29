---
name: dev-verify
description: Proves a change works, does what was asked, and nothing more. Use before committing the last task of a change, before reporting work complete, fixed or passing, before opening a PR or merging, and once after a plan's last task or slice.
---

# Verify

Three gates, in order; each catches what the previous cannot.

**What it covers:** the whole branch — `git diff $(git merge-base HEAD <target>)`, committed tasks plus the uncommitted last one, and the untracked files `git status --short` lists. `<target>` is the default branch unless the user named another.

**Where its fixes land:** in the last task's commit. A fix to a task already committed is a commit of its own.

## First — the instruction-file triage

Before the gates, so they check any update too. Two checks against the repo's agent instruction files (`AGENTS.md`, `CLAUDE.md`, nested ones):

- **Changed names** — search them for every path, command and name the diff renames, removes or changes.
- **New operational facts** — does the diff add a dependency, a build, test, lint or format command, a CI step, a config key or environment variable, or a top-level directory, of a kind the file already documents?

**Neither hits:** `Agent file: no update` — the common case, and the search is the inspection. Run it however small the change looks.

**Either hits:** run `dev-agents-md`. An update this change motivated goes in the last task's commit.

## Scale to the change

Count the diff, tests excluded, and take the first row that fits. When unsure, take the row below.

| Change | Gate 1 | Gate 2 | Gate 3 | Report |
|---|---|---|---|---|
| **Trivial** — the router's *Trivial* lane | Suite and linter, no mutation check. For docs only, none: `Checks: not run — docs only` | The reverse traces only — no behavior to map to tests | None | Compact |
| **Small** — ≤50 changed lines, no new surface, no plan | In full; the mutation pass covers only the conditions and boundaries the diff touched — none touched, none run | In full | Self-run, per *Without sub-agents* | Compact |
| **Anything else** | In full | In full | Fresh reviewer | Full |

The reverse traces never scale down: an unrequested hunk in a small diff is still unrequested.

## Gate 1 — Evidence

Run each of these and read its output:

- the project's **full** test suite, not the files you touched;
- the type checker, if the repo uses one;
- the linter and formatter the repo uses, the formatter in check mode. Lines it would change that this diff didn't touch are pre-existing, not yours to reformat (router, rule 4);
- the build, if there is one;
- the changed behavior once through its real entry point — the command, the request, the page — when the tests reach it only through substitutes and it runs locally in a minute;
- a mutation check on the new code, per `dev-testing`, *Mutation testing*. Every condition, comparison or boundary the diff adds or changes gets at least one mutant: `Mutants: none` means none survived, never none tried. The pass run while implementing counts for code unchanged since. In delegated mode, check the implementers' `Mutants` lines against the diff. A mutant on concurrent code counts as killed or surviving only after as many runs as the reproduction loop needed.

For each, report the exact command, the exit code, the counts, and the summary and failure lines — not the whole log. A tool the repo doesn't have is reported as `none configured`, not skipped in silence.

| Claim | What proves it | What does not |
|---|---|---|
| Tests pass | Suite output, 0 failures, this turn | A previous run; "should pass" |
| A red test isn't yours | The same failure in the pre-change run | "It's unrelated to my change" |
| Bug fixed | The original symptom, re-tested | The code changed |
| Regression test works | Red-green verified by reverting the fix | It passes once |
| New tests would catch a regression | Surviving mutants on the new code, each explained, per `dev-testing` | Coverage; the suite passing |

## Gate 2 — Compliance

Tests passing is not the same as building what was asked.

**Re-read the authority**, not your memory of it: the spec; else the ledger's `Request:` and `Decision:` lines; else the request as the user wrote it. For one slice of a sliced plan, only the requirements its tasks cite.

**Make a line-by-line checklist: every requirement → where it is implemented → which test covers it.** A requirement with no implementation, or an implementation with no test, is an open item, not a rounding error. A deliberate divergence from the spec is reported with its reason: recorded is fine, hidden is not.

Then run it in reverse, three times.

**1. Every hunk → the requirement it serves.** Read the diff hunk by hunk. A reformatted block, a renamed variable, a refactor, a helper or option no requirement needs, a fix to unrelated code: remove it and list it under `Follow-ups`. An instruction-file update traces to the triage, not to the request. The test for a hunk is not "is it an improvement" but "did the request ask for it".

**2. Every change to an existing test → the requirement that changed the behavior it pins.** List each test the diff deletes, skips, marks expected-to-fail or focuses (`only`), or whose expected value or assertion it changes or loosens. One with no requirement that changes that behavior made the suite agree instead of the code: revert it, and report whatever turns red again. A bug report is the requirement for a test that pinned the bug.

**3. Every surface the diff adds → the contract, request line, or user-settled decision that asked for it.** List every new surface the diff introduces (router, *Terms*). One that traces to nothing is a finding:

- **Nothing outside the change uses it:** make it private or remove it.
- **Something does:** it is a contract the user never approved. Put it under `Open` and ask before shipping.

Unrequested contracts are the scope creep tests never catch, because the tests were written for them too.

**Check the global constraints too** — version floors, dependency limits, naming and copy rules. They bind everything and nothing tests them.

## Gate 3 — Fresh review

At the scale that calls for it, dispatch **one** reviewer sub-agent over the whole-branch diff, or one slice's diff against the slice before it.

**It gets** the spec or requirements, the base commit, the working tree and a short description of what was built — **not your session history**. A reviewer that inherits your reasoning re-derives your blind spots.

**Ask it for**, ranked most severe first:

- correctness bugs, with the input that triggers them;
- requirements the diff misses;
- code the requirements don't need;
- quality problems worth fixing now, in the lines the diff changed — not around them.

**Coming back:**

- **Fix the critical and important findings** before shipping; **record the minor ones**.
- **Push back when the reviewer is wrong**, with the test or the code that proves it. Accepting a wrong finding is how correct code gets broken.
- **A finding you disagree with but cannot disprove is not resolved.** Say so.

In delegated mode, fixes from any gate follow `dev-implement`'s `references/delegated.md`, *After the last task*.

**Fixes make gate 1's output stale.** After fixing, run gates 1 and 2 again before reporting. A fix that changed more than its finding named goes back to a fresh reviewer — two review rounds maximum. Findings that survive round two each get a ruling and go under `Open`.

If the runtime has a native code review that runs without your session history, gate 3 can use it instead of a sub-agent.

## Without sub-agents

Do gate 3 as a separate pass: read the full diff as a reviewer, with the spec beside you, and write the findings down before deciding anything about them. The report says the review was self-run — weaker evidence, and the user should know.

## Report

```
Suite:      <command> → <result; pre-existing reds named, with the pre-change run>
Types/lint/build: <command> → <result>
Entry point: <command → what it showed, or n/a>
Mutants:    <survivors on the new code, each explained — or none>
Spec:       <n> requirements, <n> covered, gaps: <list or none>
Tests changed: <each existing test changed, loosened, skipped, focused or deleted → its requirement — or none>
Surfaces:   <n> added, all traced | untraced: <list>
Review:     <n> findings — <n> fixed, <n> recorded, <n> disputed
Agent file: <no update | updated | proposed: the proposal>
Decisions:  <what — why — cost if wrong, or none; from the spec and the ledger>
Follow-ups: <what was noticed and deliberately left out of scope — or none>
Open:       <anything a reader would want to know before merging>
```

Compact, for the trivial and small rows:

```
Checks:     <each command gate 1 ran → result, pre-existing reds named; `not run — docs only` for docs>
Mutants:    <survivors, each explained — or none; small row only>
Spec:       <each requirement → test; small row only>
Scope:      every hunk traced, no new surface, existing tests changed: <each → its requirement, or none> | removed: <list>
Review:     self-run — <findings or none; small row only>
Agent file: <no update | updated | proposed: the proposal>
Decisions:  <what — why — cost if wrong, or none>
Follow-ups: <or none>
```
