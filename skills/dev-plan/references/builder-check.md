# Builder check

Read from `dev-plan`, *Builder check*, once the self-review's fixes are in.

You wrote the plan, so its gaps are the ones you can't see. A reader who can't ask finds them before an implementer builds on a guess.

## The brief

Dispatch one fresh sub-agent — none of your session history — with the spec and plan paths and this:

> You will implement these tasks one at a time, reading only your own task, and you cannot ask anyone. Start with a paraphrase, in a few sentences, of what the spec asks for and how the plan builds it. Then list only the questions where you would have to guess and a wrong guess changes what gets built, most important first, each with why the answer matters. Skip what the plan leaves to the implementer, what you could reasonably decide yourself, and wording. If nothing important is left, say "nothing important left".

## Sorting what comes back

- **The paraphrase:** compare it with what you meant. Where it differs, the spec or plan reads two ways: fix the text that misled it, or, when the right reading is the user's call, ask it at the handoff.
- **Answered by the spec, the plan or the repo:** write the answer into the task that needed it.
- **Minor** — a sensible implementer could settle it without changing what gets built: settle it in that task, marked as your call: `Decision: <what> — <why> — <cost if wrong>`.
- **The user's** — only they can answer, and the answer changes what gets built: ask it at the handoff, per `dev-plan`, *Handoff*.
- **Nothing, or no paraphrase** — a return without the paraphrase, or with neither questions nor `nothing important left`: the check didn't run. Dispatch it once more; empty again, run it per *Without sub-agents* and say so at the handoff.

## Without sub-agents

Run it yourself as a separate pass after the self-review: read spec and plan as that implementer would, one task at a time and out of order, and write the paraphrase and every question down before answering any. Say at the handoff that the check was self-run.
