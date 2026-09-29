---
name: dev-skills
description: Conventions and tests for the dev-* skill set. Use when creating, editing, reviewing or debugging one of the dev-* skills of this workflow, not skills in general. Also use when a dev-* skill fires when it shouldn't, or doesn't fire when it should.
---

# Writing skills in this set

## The description is the skill's trigger

Name and body are what the agent reads *after* deciding to load it. The `description` is the only thing it reads when deciding **whether** to load it. Most skills that never fire have a good body and a vague description.

Write it as **when to use this**, in the situation's own words — the words that will be in the conversation when it applies.

- ✅ `Use when encountering a bug, a test failure, or any unexpected behavior, before proposing a fix.`
- ❌ `A systematic approach to debugging.`

State the skip condition too, when there is one. A skill that fires on everything gets ignored like a smoke alarm in a kitchen.

**Say when, not how.** Open with what the skill is for in one short clause, then the trigger — but never summarize its steps. A description that lists the process becomes a shortcut: the agent follows the summary and skips the body — the gate the summary left out is the one that gets dropped.

Third person, no first or second person — the description is injected into the system prompt.

Keep that opening clause to a dozen words so the trigger words come right after it: hosts truncate long skill listings, and what's cut can't match.

Frontmatter carries `name` and `description` and nothing else. The spec allows a few optional fields, but hosts handle them differently and some reject fields they don't know. `name` matches the folder: lowercase letters, digits and single hyphens, no hyphen at either end, at most 64 characters. `description` has no XML tags and stays under 1024 characters, the hard limit; aim for well under half that.

## Portable by construction

This set runs on more than one agent. Two rules keep it that way:

**Never name a tool.** Write the action, not the mechanism: "dispatch a fresh sub-agent", not the name of a particular agent-spawning tool. "Read the file", not the name of a read tool. "Record it in the ledger", not the name of a todo system.

**Every delegating skill carries a `## Without sub-agents` section** — in its `SKILL.md`, or in the reference that holds the delegation — three lines on how to get the same result in one pass, and what context to exclude by hand.

Paths stay neutral: `docs/specs/`, `docs/plans/`, `.dev-runs/`. Nothing under an agent-specific directory.

## Size

Roughly 1,600 words of `SKILL.md` is the ceiling — count with `wc -w`; lines here are paragraphs, not a measure. Past it, one of two things is true:

- **It does two jobs.** Split it, and give each half a description that fires on its own situation.
- **It's carrying reference material, or a mode most runs don't use.** Move that to a `references/` file the skill points at — one level deep, with a contents list at the top — and say in `SKILL.md` exactly when to read it, so the cost is paid only when it's needed.

Some hosts keep only the first few thousand tokens of a skill after a context compaction, so the rules that must survive go first, and a reference file that must survive says to re-read it.

A skill competes for the same context the actual work needs. A rule stated once and sharply beats the same rule stated three times with escalating emphasis. If a paragraph does not change what the agent does, cut it.

## Write the rule, then the reason

An instruction lands better with the failure it prevents attached. `Watch the test fail — if you did not, you do not know what it tests` works; `Always follow TDD` does not. One sentence of why, not a paragraph of insistence.

When a rule gets bypassed in practice, the fix is usually a **verifiable skip criterion**, not louder wording. "Skip if the change is simple" is a judgment call and will be abused. "Skip at three commits or fewer" is checkable.

No dates, no "currently", no version-of-the-month: a skill outlives them, and a stale fact reads as a rule.

## Cross-references

Refer to a sibling skill by its bare name — `dev-testing`, not a namespaced or prefixed form. Namespaces differ per agent; bare names survive a rename of the set. Point at a section by its heading in italics — `dev-testing`, *Regression tests, proven red* — and when you rename a heading, search the set for it.

One term per concept, across the whole set. *New surface*, *pins down* and *open* are defined once in the router's *Terms*, *task* in `dev-ship`, the `Interfaces` block in `dev-plan`; a synonym reads as a second concept — "exported interface" for "exported function or type" is one.

## Check that it fires

Reading well is not the same as triggering. Give a fresh agent — with no hint about which skill you mean — a request that should invoke it, and see whether it does. Then give it a request that is deliberately just below the skip criterion, and check that it doesn't.

A skill that doesn't fire is worth nothing regardless of its content, and that is a `description` problem every time.

Firing is half of it. For an edit that changes behavior, write the scenario that tempts the shortcut the edit is meant to close — an unrequested flag, a fix already tried, a one-line change. Run it on a fresh agent before the edit and after, in a scratch repository that really contains the trap, not a description of it.

- **The before-run already does the right thing:** the edit isn't needed.
- **The after-run still doesn't:** the wording isn't done.

Run both on the smallest model the set is meant to work with, not only the strongest. A strong model often does the right thing unprompted, so a clean before-run on it says nothing about a smaller one.

## Keep the set small

Before adding a skill, ask whether it is really a section of one that already exists. Two skills that fire in the same situation are one skill, and splitting them means the agent loads half the guidance it needed.
