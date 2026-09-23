---
name: dev-explore
description: Use when a request is ambiguous, spans code you don't know, or carries a design decision with more than one defensible answer. Resolves facts from the codebase in parallel, then drives the open decisions to closure in batched question rounds, ending in a short written spec. Skip when the request names both the what and the where and the affected code is already understood.
---

# Explore

Turn a vague request into a settled one. The output is shared understanding, not code.

## Skip this skill when all three hold

- The request names what to change and where.
- No design decision has more than one defensible answer.
- You already know the state of the affected code.

Any one of these failing means run the skill. "It seems simple" is not one of the three.

## 1. Split unknowns into facts and decisions

Write two columns before anything else. This split is the skill.

- **Facts** — anything knowable from the repo, the history, the dependencies, the network. **Yours to find.** Never ask the user.
- **Decisions** — anything where two answers are both defensible and the choice belongs to the user: scope, trade-offs, priorities, what "done" means.

A question in the wrong column wastes a round trip. "Which test framework does this repo use?" is a fact. "Should this be backward compatible?" is a decision.

## 2. Resolve the facts in parallel

Dispatch one sub-agent per independent factual question, all in the same turn. Each returns the answer and the file paths that prove it — not file dumps.

Give each one a question, not a topic. "Does the auth module validate token expiry, and where?" not "look into auth".

**Without sub-agents:** answer them yourself, cheapest first, and stop as soon as you have the answer. Don't read whole files when a search will do.

## 3. Ask the decisions in rounds

The **frontier** is every decision whose prerequisites are already settled. Ask **the whole frontier in one round** — never one question at a time. A question whose answer depends on another question open in this round belongs to the next round, not this one.

```
❓ **Q1 — <short title>**: <the question, with the options if there are options>

➡️ <your recommended answer and the one reason that decides it>

---

❓ **Q2 — <short title>**: …
```

Every question carries your recommendation. A question without one is you making the user do your thinking.

Each round's answers reshape the tree: settled decisions unblock the questions that hung off them. Recompute the frontier and ask the next round. A sub-agent still running is an unsettled prerequisite — it blocks only the questions downstream of it, not the round.

Propose alternatives where alternatives genuinely exist, as options inside a question. Don't manufacture three approaches when there is one.

The phase ends when the frontier is empty: nothing left silently assumed.

## 4. Check the scope before writing

If the request covers several independent subsystems, say so now. Decompose into sub-projects, name how they relate and in what order they get built, and take the first one through the rest of this flow. Each sub-project gets its own spec.

## 5. Write the spec

`docs/specs/YYYY-MM-DD-<slug>.md`. If the work is not going to `dev-plan`, skip the file and put a paragraph in the conversation instead.

Cover only what the work needs: the goal, the decisions that were settled and why, the constraints that apply project-wide (versions, dependency limits, conventions — with exact values), what is explicitly out of scope, and what "done" looks like.

Then read it once with fresh eyes:

- **Placeholders** — any TBD, any "handle errors appropriately". Fix them.
- **Contradictions** — does any section disagree with another?
- **Two readings** — could a requirement be read two ways? Pick one and say which.
- **Scope** — is this one implementation's worth of work?

Fix inline. Then hand the spec to the user to read before the plan starts.
