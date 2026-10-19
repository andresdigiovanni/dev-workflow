---
name: dev-explore
description: Settles the facts and the user's decisions before any code is written. Use when a request is ambiguous, has a design choice with more than one defensible answer, touches code a search doesn't locate, adds new surfaces (endpoint, flag, exported function, config key) that take more than one round of questions, is forecast past 400 changed lines, or when the user asks for options or trade-offs. Skip when none hold.
---

# Explore

Turn a vague request into a settled one. The output is shared understanding, not code.

A bug report goes to `dev-debug` first: its reproduction and root-cause trace are the exploration. Come here only when its fix needs more than one round of decisions, or is *Planned*.

## 1. Split unknowns into facts and decisions

Write two columns before anything else. This split is the skill.

- **Facts** — anything knowable from the repo, the history, the dependencies, the network. **Yours to find.** Never ask the user.
- **Decisions** — anything where two answers are both defensible and the choice belongs to the user: scope, trade-offs, priorities, what "done" means.

A question in the wrong column wastes a round trip. "Which test framework does this repo use?" is a fact. "Should this be backward compatible?" is a decision. So is a number the request needs but doesn't give — a limit, a timeout, a size, a retention — unless the repo already fixes it.

## 2. Resolve the facts in parallel

Dispatch one sub-agent per independent factual question, all in the same turn. Each returns the answer and the file paths that prove it, not file dumps.

Give each one a question, not a topic: "Does the auth module validate token expiry, and where?", not "look into auth". A fact one search answers, answer yourself: a sub-agent costs more than the search.

## 3. Check the scope before asking

If the request covers several independent subsystems, say so now, before any round is spent on the whole. Propose a split into sub-projects, how they relate and the order they get built in, as a question in the first round: the scope is the user's. Then take the first one through the rest of this flow; each sub-project goes through it on its own.

## 4. Justify every new surface

A surface is a contract: once something depends on it, taking it back is a breaking change. Agents add them by reflex — an optional flag, a spare field, an endpoint "for later". Each one is a decision for the round, never a fact, and it arrives with these four answers worked out:

- **Requirement** — the line of the request or spec that needs it, quoted, or the requirement that cannot be met without it (a rate limit needs a rejection response). None means it is out of scope: drop it rather than ask, and list it as a follow-up.
- **Consumer** — who calls it now. A real caller, not "someone might".
- **Existing home** — could a surface that already exists absorb it? Extending one beats adding a second.
- **Smallest shape** — the fewest parameters, fields and options that serve that consumer. No knob for a value with one known setting, nothing optional "for the future", private until something outside needs it.

## 5. Ask the decisions in rounds

**Open the first round with a Context block:** the facts that shape the decisions. Both it and each question take the router's question format (rule 3). A wrong fact caught here costs one line instead of a wrong design.

**Ask the whole frontier in one round.** The frontier is every decision whose prerequisites are already settled. Never ask one question at a time. A question whose answer depends on another question in this round belongs to the next round.

**The approach comes first.** Before the details, list the mechanisms that could meet the request: in the code, in front of it (a proxy, a gateway, a managed service), or a dependency that already does it.

- **More than one survives the facts:** the first round opens with that question — two or three approaches, each with what it costs and what it rules out.
- **Only one survives:** say so in one Context line, naming each rejected mechanism and the fact that rules it out. A mechanism you didn't consider isn't ruled out.

Never settle the approach inside the Context block: a fact line that picks the architecture is a decision taken for the user.

**One exception, in the first round only:** when what is unknown is the user's intent — the goal, who it serves — and no option can be defended yet, open with one open question instead. Options offered before you know what they want steer the answer. The rounds after it carry options.

Offer an option only if you would defend it. Don't manufacture three approaches when there is one. A decision with one defensible answer is a fact: it goes in the spec or the ledger, not in a round.

**Each round's answers reshape the tree.** Settled decisions unblock the questions that hung off them: recompute the frontier and ask the next round. Send a round only once every fact sub-agent you dispatched has returned (router, rule 1).

The phase ends when the frontier is empty: nothing left silently assumed.

## 6. Record the outcome

### When a plan follows (*Planned* lane)

Write `docs/specs/YYYY-MM-DD-<slug>.md`, or where the repo already keeps specs. The plan argues from it, and the conversation doesn't survive compaction. Cover only what the work needs:

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

No spec file. Write the settled request, the decisions and any pinned surface to the ledger (router, *Terms*) as `Request:` and `Decision:` lines.

Then:

- **Go ahead** when the facts left no decision to ask, or the user answered every question with one of its options and no fact changed since.
- **Wait** when an answer went outside the options or changed the scope: restate the settled request in a few lines and wait for the go-ahead.

## Without sub-agents

Answer the factual questions yourself, cheapest first, and stop each one as soon as you have the answer. Don't read whole files when a search will do.
