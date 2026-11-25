# The report

Read this before writing the report.

## Contents

- The template
- Filling it

## The template

```text
Verdict: <Ready | Fix first: <numbers and failing checks> | Not settled: <what is open>>
Does what was asked: <yes | no: <numbers> | not checked: <why>>
Built right: <yes | no: <numbers> | not checked: <why>>

Change: <what it does, in two or three sentences, from the code>
Target: <repo> <range> — <n> files, <n> changed lines — <own | foreign: nothing was run>
Depth: <Small | Standard>[, self-run] — lenses: <those that ran>

── Checks ──
Suite: <command> → <result; pre-existing reds named> | not run: <why>
Types/lint/build: <command> → <result> | none configured | not run: <why>
Entry point: <command> → <what it showed> | n/a | not run: <why>
Agent file: <no update | update: <path>:<line> → <what is true now> | proposed: <instruction — evidence — gain>>

── Findings ──
Critical
<n>. <title> — <path>:<line> [<lens or lenses>; <reproduced | traced>]
   Trigger: <...>
   Outcome: <...>
   Fix: <...>
Important
<same shape>
Minor
<n>. <path>:<line> — <problem>. <fix>.

── Unsettled ──
Needs checking: <finding — what would settle it>
Pre-existing: <path>:<line> — <problem>
Refuted: <n> — <finding → what refuted it>
Not checked: <lens that did not run or failed, group not covered, what a reviewer could not verify or set aside>
```

## Filling it

The answer that carries the report is the template filled in as one `text` code block, with nothing before the opening fence: the first line inside it is the verdict, and it ends at the template's last line, which the closing fence follows. Each label sits at the start of its line: a Markdown renderer folds plain lines into one paragraph and drops indentation, and the user scans for the labels. Nothing follows it: no advice, no pick between options, no account of how the review went, and no statement about the code that is not a line of the report. What a reviewer or verifier said outside its findings or blocks was verified by nobody, and the coordinator may be the session that wrote the code. When a skill of the workflow asked for the review, that skill continues after the report; the coordinator still adds nothing of its own to it.

Write the report in the user's language and keep the labels as they are: the user learns to scan for them, and a translated label breaks that.

Each line of a finding comes from where it was settled, and the coordinator writes none of its own: the title, the path, `Trigger`, `Outcome`, `Fix` and the lens from the reviewer's finding; the group, the evidence (`reproduced` or `traced`) and the origin from the verifier's answer.

Where each finding goes:

- `Confirmed` with `ORIGIN: introduced`: its severity group, with a number.
- `Confirmed` with `ORIGIN: pre-existing`: the `Pre-existing` line, with no number, whatever its severity. It counts toward neither line nor the verdict: the change did not introduce it.
- `Unproven`: `Needs checking`, with what would settle it. A finding whose verifier returned no usable answer goes there too and says so.
- `Refuted`: the `Refuted` line, with what refuted it; `<n>` is how many there are.

The lines:

- `Change` is written from the code, not from the author's description: a description is the author's account, and the report must not repeat it as fact.
- `<repo>` in `Target` is the repository's name or where the code was obtained from; every `<path>` is relative to the code directory. Neither is ever a path inside `<output>`: that directory is gone when the report is read. `<range>` is `<base>..<head>`, `uncommitted`, or, for a whole branch with its uncommitted work, `<base>..<head> + uncommitted`; a review of named paths says so after it: `paths: <list>`. With no git there is no range: `Target` opens with `files`, then the counts. `<n> changed lines` is the triage's count, tests left out: the same number as the depth line.
- `Suite`, `Types/lint/build`, `Entry point` and `Agent file` come from the checks, each as it came out: the exact command and its result, never a summary of your own. On a foreign change the first three read `not run: foreign`.
- Numbers start at 1 and run across `Critical`, `Important` and `Minor`, so the user can say "fix 2 and 5".
- A group or line with nothing is left out, except `Not checked`, which reads `nothing` when there is nothing: a missing line cannot be told from a lens that was skipped. The three section titles `── Checks ──`, `── Findings ──` and `── Unsettled ──` always stay, each on its own line after a blank one: `Checks` always holds its four lines and `Unsettled` always holds `Not checked`.
- With no numbered finding, `Critical`, `Important` and `Minor` are replaced by the line `No findings` under `── Findings ──`. The lines under `── Unsettled ──` are not: `Needs checking`, `Pre-existing` and `Refuted` stay when they hold something and `Not checked` always stays, because an unproven finding or a lens that failed is not a clean result.
- `Does what was asked` rests on the Critical and Important findings tagged `[intent]`, and `Built right` on those of every other tag, `[claims]` included: the author's description is not what was asked of the change. A merged finding counts on each line one of its lenses stands on. The two lines are never blended into one, because a change can be well built and still not be what was asked.
- A line reads `not checked: <why>` when no lens behind it gave an answer: `no intent found` when `intent.md` was empty, the lens that failed otherwise. It never reads `yes` for a question no reviewer answered.
- `Verdict` is `Fix first` followed by the numbers of the Critical and Important findings, then the failing checks, comma-separated: `Fix first: 2, 5, agent file`; with no number, `Fix first: suite`. A check is named only as `references/checks.md`, *What a result does*, says — a command that failed beyond the baseline, by its report line (`suite`, `types/lint/build` or `entry point`), or an `update` on the `Agent file` line, as `agent file`; a check that passed, `none configured` and `n/a` are never named. With no number and no failing check, it is `Not settled`, naming what is open, when a lens failed, anything is under `Needs checking` or a command could not run on an own change. Otherwise it is `Ready`; a line that reads `not checked: no intent found` does not prevent that.
- Critical and Important findings carry all their lines; a Minor one takes one line. A security finding or a design disagreement gets the sentences it needs: a one-line version loses the reasoning the reader must judge.
- `Not checked` holds every lens that did not run, with why (no risk hit, nothing to check it against), every lens that failed, every file group not covered, the reviewers' `Cannot verify from the diff` and `Declined to judge` lines, and the notes the review owes: a pull request read without its description or comments, a change with no base reviewed as whole files, and a change past 1,000 lines reviewed in part.
- `Needs checking`, `Pre-existing`, `Refuted` and `Not checked` take one entry per line: the first on the label's line, each further one on its own line below it, indented two spaces — `Needs checking: a — b`, then `  c — d` below it; never the label repeated, never entries joined by `;`. `Refuted`'s `<n>` counts all its entries and stays on the label's line.
- Never quote a secret, in any line of the report: write `<REDACTED>`, because the report is read by people and stored in a conversation.
