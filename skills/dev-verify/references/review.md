# Gate 3 — the fresh review

Read from `dev-verify`, *Gate 3 — Fresh review*, before dispatching the reviewer or running the review yourself, and again before ruling on what it returns. A plan's per-task reviewers get the same brief (`dev-implement`'s `references/delegated.md`, *Per task*).

## Contents
- The brief
- Severity
- The security lens
- Besides the findings
- A finding you dispute
- Without sub-agents

## The brief

The reviewer gets the spec or requirements, the base commit, the working tree, a short description of what was built, the repo's documented standards — `CONTRIBUTING`, `CODING_STANDARDS`, a style guide the repo names — and the security lens when `dev-verify`'s security triage hit — **not your session history**.

Ask it for findings ranked most severe first, each in this shape:

```
[<severity>] <title>
Where:   <path> — <function or class>
Trigger: <the input or state that makes it fail>
Outcome: <what the caller sees>
Missed:  <the guard, type or test that should catch it and doesn't>
```

After the findings, ask for the two lists in *Besides the findings*.

What to look for, in the lines the diff changed — not around them:

- correctness bugs, with the input that triggers them;
- requirements the diff misses, and code the requirements don't need;
- errors that vanish: a catch that drops the error, a fallback value that turns a failure into a plausible result, an error rethrown without its cause, a remote call with no timeout, a partial write with no rollback;
- breaches of the repo's documented standards, citing the file and the rule;
- quality problems worth fixing now.

Give it these rules as written:

- **Only read.** Never change the working tree, the index, HEAD or a branch — no checkout, stash, restore, reset or commit: the change under review is usually uncommitted, and those take it with them. Running tests is fine.
- **Report only what you can trigger.** Before writing a finding: you can point at the code, name the input that breaks it, you read its callers, and you would defend its severity. Missing one: drop it, or report it as minor.
- **Dispatch no sub-agents.** This review is the seat the work gets; one you spawn duplicates it.
- **The description and any implementer's report are claims.** Check them against the diff. A rationale they give never lowers a finding's severity.
- **Never quote a secret** in a finding: write `<REDACTED>`.
- **The spec's silence about an input is not permission for it to fail.** Grade such a finding by what the caller gets.
- **Zero findings is a valid review.** A finding made up to have something to report is the commonest reviewer failure, and each one costs a fix round.
- **Skip these** unless the spec or a repo convention makes them matter: a literal that is a well-known constant, such as a status code or a port; a missing doc comment; a null check after a guard that already excludes null; a loop over a collection whose size the code fixes; a call left unawaited on purpose; a long function that is one exhaustive switch; anything the formatter or linter owns.

**Never pre-judge.** The brief tells the reviewer nothing to ignore, no severity cap, and not that the plan or you chose something: the skip list above is the only exclusion. A finding you expect to be wrong is settled after it comes back, per *A finding you dispute*.

## Severity

| Severity | What it is | Before shipping |
|---|---|---|
| **Critical** | a wrong result, data loss or a security hole, with its trigger | fixed |
| **Important** | a requirement the diff misses, code no requirement needs, a failure on an input the spec implies | fixed |
| **Minor** | a quality problem in the changed lines | recorded under `Follow-ups` |

A critical or important finding with no `Trigger` is minor.

## The security lens

Added to the brief when the security triage hit. In the changed lines:

- input from outside the process reaching a query, a shell, a path, a template or a deserializer without the escaping or validation the repo uses elsewhere;
- a new path to an action with no authorization check, or with the check after the action;
- a secret in the code, a log line, an error message or a test fixture;
- secrets compared in non-constant time, a homemade crypto primitive, a token from a non-cryptographic random source;
- a file or resource created with wider permissions than its users need.

## Besides the findings

Ask the reviewer for two lists after its findings:

- **Cannot verify from the diff** — requirements that live in unchanged code or span tasks. Resolve each yourself before ruling; a confirmed gap is a finding.
- **Declined to judge** — behaviors it considered and set aside as outside the spec, one line each with the reason. Rule on each: a finding, or a `Decision:` line with its cost if wrong, which goes under the report's `Decisions`. Nothing it set aside is dropped silently.

When no request, spec or codebase convention fixes what an input the spec is silent on should give, the fix is a question to the user, not handling you invent (`dev-testing`, *What to cover*).

## A finding you dispute

Fix the findings you agree with. One you think is wrong is not yours to rule on: you wrote the code, and the reasoning that would have produced the bug is the one judging it.

Dispatch a fresh verifier with the finding, the code it names and the spec — not the reviewer's reasoning, not yours. Its job is to refute the finding: cite the guard, type or caller that makes the trigger impossible, or run the trigger and show it doesn't fail. It only reads and runs: to try the trigger, it writes only in a temporary directory outside the repository, and runs no git command that writes.

- **Refuted, with the line or the run cited:** record it under `Review` as disputed, with that evidence.
- **Not refuted, or the verifier is unsure:** the finding stands. Uncertainty never clears a finding.

## Without sub-agents

Also the review of a *Small* change in `dev-verify`. Do it as a separate pass: read the full diff as a stranger would, with the spec beside you, and write the findings down — under the brief's rules and shape — before deciding anything about them. For a finding you dispute, write the trigger out and try it — a test or a run, not an argument. Not disproven: it stands. The report says the review was self-run — weaker evidence, and the user should know.
