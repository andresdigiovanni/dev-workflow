---
name: dev-skills
description: Use when creating, editing, reviewing or debugging a skill in this set. Covers what makes a description fire at the right moment, how to stay portable across agents, size discipline, and how to tell whether a skill actually triggers.
---

# Writing skills in this set

## The description is the skill's trigger

Name and body are what the agent reads *after* deciding to load it. The `description` is the only thing it reads when deciding **whether** to load it. Most skills that never fire have a good body and a vague description.

Write it as **when to use this**, in the situation's own words — the words that will be in the conversation when it applies.

- ✅ `Use when encountering a bug, a test failure, or any unexpected behavior, before proposing a fix.`
- ❌ `A systematic approach to debugging.`

State the skip condition too, when there is one. A skill that fires on everything gets ignored like a smoke alarm in a kitchen.

Frontmatter carries `name` and `description` and nothing else. Extra fields are agent-specific and don't travel.

## Portable by construction

This set runs on more than one agent. Two rules keep it that way:

**Never name a tool.** Write the action, not the mechanism: "dispatch a fresh sub-agent", not the name of a particular agent-spawning tool. "Read the file", not the name of a read tool. "Record it in the ledger", not the name of a todo system.

**Every delegating skill carries a `## Without sub-agents` section** — three lines on how to get the same result in one pass, and what context to exclude by hand.

Paths stay neutral: `docs/specs/`, `docs/plans/`, `.dev-runs/`. Nothing under an agent-specific directory.

## Size

Roughly 150 lines is the ceiling. Past it, one of two things is true:

- **It does two jobs.** Split it, and give each half a description that fires on its own situation.
- **It's carrying reference material.** Move that to a `references/` file the skill points at, so the cost is paid only when it's needed.

A skill competes for the same context the actual work needs. A rule stated once and sharply beats the same rule stated three times with escalating emphasis. If a paragraph does not change what the agent does, cut it.

## Write the rule, then the reason

An instruction lands better with the failure it prevents attached. `Watch the test fail — if you did not, you do not know what it tests` works; `Always follow TDD` does not. One sentence of why, not a paragraph of insistence.

When a rule gets bypassed in practice, the fix is usually a **verifiable skip criterion**, not louder wording. "Skip if the change is simple" is a judgment call and will be abused. "Skip if two files or fewer and no new interface" is checkable.

## Cross-references

Refer to a sibling skill by its bare name — `dev-testing`, not a namespaced or prefixed form. Namespaces differ per agent; bare names survive a rename of the set.

## Check that it fires

Reading well is not the same as triggering. Give a fresh agent — with no hint about which skill you mean — a request that should invoke it, and see whether it does. Then give it a request that is deliberately just below the skip criterion, and check that it doesn't.

A skill that doesn't fire is worth nothing regardless of its content, and that is a `description` problem every time.

## Keep the set small

Before adding a skill, ask whether it is really a section of one that already exists. Two skills that fire in the same situation are one skill, and splitting them means the agent loads half the guidance it needed.
