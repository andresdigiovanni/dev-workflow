---
name: dev-explore
description: Settles the facts and the user's decisions before any code is written. Use when a request is ambiguous, has a design choice with more than one defensible answer, touches code a search doesn't locate, adds new surfaces (endpoint, flag, exported function, config key) that take more than one round of questions, spans more than three commits, or when the user asks for options or trade-offs. Skip when none hold.
---

# Explore

Turn a vague request into a settled one. The output is shared understanding, not code.

## Skip this skill when all five hold

- The request names what to change.
- No design decision has more than one defensible answer.
- A search for what the request names — a file, a symbol, a command, an error message — finds the affected code. Reading that code is `dev-implement`'s job, not exploration.
- No open new surface appears (router, *Terms*). A surface the request pins down is one the user already decided.
- The work fits in three commits. Past that, the approach is a decision however clear the request: never skipped on the *Planned* lane.

"It seems simple" is not one of the five. If any one fails, run the skill — unless all that fails is a few open surfaces, dependencies or behaviors and no answer would change the approach. Then run a *Single round* instead.

A bug report goes to `dev-debug` first: its reproduction and root-cause trace are the exploration. Come here only when the fix it finds carries a decision.

## Single round

When the only open items are a few surfaces, new dependencies or observable behaviors, and no answer would change the approach:

1. Skip steps 1–3 and 6.
2. Ask every open item in one round, in step 4's format. The Context block holds only the facts these questions rest on.
3. Give each surface step 5's four answers.
4. Carry on with the answers.

In the fast and bug lanes `dev-implement` runs this round itself (*Sort every decision the request didn't settle*), without loading this skill.

## 1. Split unknowns into facts and decisions

Write two columns before anything else. This split is the skill.

- **Facts** — anything knowable from the repo, the history, the dependencies, the network. **Yours to find.** Never ask the user.
- **Decisions** — anything where two answers are both defensible and the choice belongs to the user: scope, trade-offs, priorities, what "done" means.

A question in the wrong column wastes a round trip. "Which test framework does this repo use?" is a fact. "Should this be backward compatible?" is a decision. So is a number the request needs but doesn't give — a limit, a timeout, a size, a retention — unless the repo already fixes it.

## 2. Resolve the facts in parallel

Dispatch one sub-agent per independent factual question, all in the same turn. Each returns the answer and the file paths that prove it, not file dumps.

Give each one a question, not a topic: "Does the auth module validate token expiry, and where?", not "look into auth". A fact one search answers, answer yourself: a sub-agent costs more than the search.

## 3. Check the scope before asking

If the request covers several independent subsystems, say so now, before any round is spent on the whole. Decompose it into sub-projects, name how they relate and the order they get built in, and take the first one through the rest of this flow. Each sub-project goes through this flow on its own.

## 4. Ask the decisions in rounds

**Open the first round with a Context block:** the facts that shape the decisions, one line each, with the path that proves it. A wrong fact caught here costs one line instead of a wrong design.

**Ask the whole frontier in one round.** The frontier is every decision whose prerequisites are already settled. Never ask one question at a time. A question whose answer depends on another question in this round belongs to the next round.

**The approach comes first.** Before the details, list the mechanisms that could meet the request: in the code, in front of it (a proxy, a gateway, a managed service), or a dependency that already does it.

- **More than one survives the facts:** the first round opens with that question — two or three approaches, each with what it costs and what it rules out.
- **Only one survives:** say so in one Context line, naming each rejected mechanism and the fact that rules it out. A mechanism you didn't consider isn't ruled out.

Never settle the approach inside the Context block: a fact line that picks the architecture is a decision taken for the user.

```
❓ **Q1 — <short title>**: <the question>

- **A — <option>**: <what it costs> / <what it buys>
- **B — <option>**: <what it costs> / <what it buys>

➡️ <your recommended option and the one reason that decides it>

---

❓ **Q2 — <short title>**: …
```

Every question carries:

- **At least two options.** Without options it is a statement, not a question.
- **Your recommendation.** Without one you make the user do your thinking.
- **For each option, what it costs and what it buys** — complexity, time, risk, lines, a new dependency, a breaking change. An option without its cost is a sales pitch.

Offer an option only if you would defend it. Don't manufacture three approaches when there is one. A decision with one defensible answer is a fact: it goes in the spec or the ledger, not in a round.

**Before sending a round, put every question that would add a surface through step 5.** One with no requirement to quote is out of scope: drop it and list it as a follow-up; never offer it as an option. That isn't settling a surface for the user — it is not building what wasn't asked (router, rule 4). The follow-up line is how they ask for it if they want it.

**Each round's answers reshape the tree.** Settled decisions unblock the questions that hung off them: recompute the frontier and ask the next round. A sub-agent still running is an unsettled prerequisite. It blocks only the questions downstream of it, not the round.

The phase ends when the frontier is empty: nothing left silently assumed.

## 5. Justify every new surface

A surface is a contract: once something depends on it, taking it back is a breaking change. Agents add them by reflex — an optional flag, a spare field, an endpoint "for later". Each one is a decision for the round, never a fact, and it arrives with these four answers worked out:

- **Requirement** — the line of the request or spec that needs it, quoted, or the requirement that cannot be met without it (a rate limit needs a rejection response). None means it is out of scope: drop it rather than ask.
- **Consumer** — who calls it now. A real caller, not "someone might".
- **Existing home** — could a surface that already exists absorb it? Extending one beats adding a second.
- **Smallest shape** — the fewest parameters, fields and options that serve that consumer. No knob for a value with one known setting, nothing optional "for the future", private until something outside needs it.

## 6. Record the outcome

### When a plan follows (*Planned* lane)

Write `docs/specs/YYYY-MM-DD-<slug>.md`. The plan argues from it, and the conversation doesn't survive compaction. Cover only what the work needs:

- the goal;
- each settled decision, with the alternatives rejected and why;
- the constraints that apply project-wide — versions, dependency limits, conventions — with exact values;
- the **contracts**: every new surface, its exact shape, and the requirement it serves. Anything not listed here stays private;
- what is explicitly out of scope;
- what "done" looks like.

Then read it once with fresh eyes and fix inline:

- **Placeholders** — any TBD, any "handle errors appropriately".
- **Contradictions** — does any section disagree with another?
- **Two readings** — could a requirement be read two ways? Pick one and say which.
- **Scope** — is this one implementation's worth of work? Does every requirement quote the request or a user's answer? One that quotes neither is scope you added: cut it or ask it.

Go straight into `dev-plan`. The user approves spec and plan together at the plan's handoff.

### Otherwise (*Explored* lane)

No spec file. Write the settled request, the decisions and any pinned surface to the ledger as `Request:` and `Decision:` lines. That is what `dev-verify` checks against once the conversation is compacted.

The ledger is `.dev-runs/<slug>.md`. If the repo doesn't ignore `.dev-runs/`, add it to the file `git rev-parse --git-path info/exclude` names, so the ledger never lands in a commit.

Then:

- **Go ahead** when the facts left no decision to ask, or the user answered every question with one of its options and no fact changed since.
- **Wait** when an answer went outside the options or changed the scope: restate the settled request in a few lines and wait for the go-ahead.

## Without sub-agents

Answer the factual questions yourself, cheapest first, and stop each one as soon as you have the answer. Don't read whole files when a search will do.
