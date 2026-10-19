---
name: dev-verify
description: Proves a change works, does what was asked, and nothing more. Use before committing the last task of a change, before reporting work complete, fixed or passing, before opening a PR or merging, and once after each slice of a plan. On the Trivial lane, only where dev-ship sends it here.
---

# Verify

Two triages, then three gates, in order; each gate catches what the previous cannot.

**What it covers:** the whole branch — `git diff $(git merge-base HEAD <target>)`, committed tasks plus the uncommitted last one, and the untracked files `git status --short` lists. `<target>` is the default branch unless the user named another.

**Where its fixes land:** per `dev-ship`, *One task, one commit*.

## First — the instruction-file triage

Before the gates, so they check any update too. Two checks against the repo's agent instruction files (`AGENTS.md`, `CLAUDE.md`, nested ones):

- **Changed names** — search them for every path, command and name the diff renames, removes or changes.
- **New operational facts** — does the diff add a dependency, a build, test, lint or format command, a CI step, a config key or environment variable, or a top-level directory, of a kind the file already documents?

**Neither hits:** `Agent file: no update` — the common case, and the search is the inspection. Run it however small the change looks.

**Either hits:**

- **A line this diff made wrong, or a new fact of a kind the file already lists:** fix it with the smallest accurate edit, checked against the repo. `Agent file: updated`; it lands like any other fix.
- **A new convention, a rule drawn from a session decision, or drift older than this change:** don't edit. Report a proposal: the instruction, its evidence, what a future agent gains.
- **The line is still accurate:** `Agent file: no update`.

## Then — the security triage

Does the diff change how any of these behave: authentication or authorization; input from outside the process reaching a query, a shell, a path, a template or a deserializer; secrets or credentials; cryptography; the permissions of a file or resource? A name that merely appears in the diff is not a hit.

**No hit:** `Security: no hit`. **A hit:** gate 3 runs a fresh reviewer whatever the size, with the security lens.

## Scale to the change

**Small** — ≤50 changed lines, tests excluded, no new surface, no plan: gate 3 is self-run, per `references/review.md`, *Without sub-agents*. Tests are excluded here and included in the lanes' 400: the lanes measure what a reviewer reads, this measures the code that can break. Anything else, or when unsure: a fresh reviewer. Gates 1 and 2 run in full at every size: an unrequested hunk in a small diff is still unrequested.

## Gate 1 — Evidence

Run each of these and read its output:

- the project's **full** test suite, not the files you touched;
- the type checker, if the repo uses one;
- the linter and formatter the repo uses, the formatter in check mode. Lines it would change that this diff didn't touch are pre-existing, not yours to reformat (router, rule 4);
- the build, if there is one;
- the changed behavior once through its real entry point — the command, the request, the page — when the tests reach it only through substitutes and it runs locally in a minute;

For each, report the exact command, the exit code, the counts, and the summary and failure lines — not the whole log. A tool the repo doesn't have is reported as `none configured`, not skipped in silence.

## Gate 2 — Compliance

Tests passing is not the same as building what was asked.

**Re-read the authority**, not your memory of it: the spec; else the ledger's `Request:` and `Decision:` lines; else the request, the user's answers and the `Decision:` lines in the conversation. For one slice of a plan, only the requirements its tasks cite.

**Make a line-by-line checklist: every requirement → where it is implemented → which test covers it.** A requirement with no implementation, or an implementation with no test, is an open item, not a rounding error. A deliberate divergence from the spec is reported with its reason: recorded is fine, hidden is not.

Then run it in reverse, three times.

**1. Every hunk → the requirement it serves.** Read the diff hunk by hunk. A reformatted block, a renamed variable, a refactor, a helper or option no requirement needs, a fix to unrelated code: remove it and list it under `Follow-ups`. An instruction-file update traces to the triage, not to the request. The test for a hunk is not "is it an improvement" but "did the request ask for it".

**2. Every change to an existing test or check → the requirement that changed the behavior it pins.** A check — linter, formatter, type checker or CI configuration — bent to get green is a loosened assertion. List each test the diff deletes, skips, marks expected-to-fail or focuses (`only`), or whose expected value or assertion it changes or loosens. One with no requirement that changes that behavior made the suite agree instead of the code: revert it, and report whatever turns red again. A bug report is the requirement for a test that pinned the bug.

**3. Every surface the diff adds → the contract, request line, or user-settled decision that asked for it.** List every new surface the diff introduces (router, *Terms*). One that traces to nothing is a finding:

- **Nothing outside the change uses it:** make it private or remove it.
- **Something does:** it is a contract the user never approved. Put it under `Open` and ask before shipping.

Unrequested contracts are the scope creep tests never catch, because the tests were written for them too.

**Check the global constraints too** — version floors, dependency limits, naming and copy rules. They bind everything and nothing tests them.

## Gate 3 — Fresh review

At the scale that calls for it, dispatch **one** reviewer sub-agent over the whole-branch diff, or one slice's diff against the slice before it.

**Read `references/review.md` before dispatching, and again before ruling on what comes back**: the brief, the severity scale, the security lens, and how a disputed finding is settled. The reviewer gets **none of your session history**.

**Coming back:** fix the critical and important findings before shipping; record the minor ones under `Follow-ups`. Dispute one only per the reference, *A finding you dispute* — never by your own reading of the code you wrote.

In delegated mode, fixes from any gate follow `dev-implement`'s `references/delegated.md`, *After the last task*.

**Fixes make gate 1's output stale.** After fixing, run gates 1 and 2 again before reporting. A fix that changed more than its finding named goes back to a fresh reviewer — two review rounds maximum. Findings that survive round two each get a ruling and go under `Open`.

## Report

One template for every change. On a *Small* one, `Spec` lists each requirement → its test, `Review` reads `self-run — <findings or none>` unless the security triage sent it to a fresh reviewer, and a line with nothing to report reads `none`.

```
Suite:      <command> → <result; pre-existing reds named, with the baseline>
Types/lint/build: <command> → <result, or none configured>
Entry point: <command → what it showed, or n/a>
Spec:       <n> requirements, <n> covered, gaps: <list or none>
Tests changed: <each existing test or check changed, loosened, skipped, focused or deleted → its requirement — or none>
Surfaces:   <n> added, all traced | untraced: <list>
Review:     <n> findings — <n> fixed, <n> recorded, <n> disputed
Security:   <no hit | hit: what the diff touches → <n> findings>
Agent file: <no update | updated | proposed: the proposal>
Decisions:  <what — why — cost if wrong, or none; from the spec, the ledger or the conversation>
Follow-ups: <what was noticed and deliberately left out of scope — or none>
Open:       <anything a reader would want to know before merging — or none>
```
