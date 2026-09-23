---
name: dev-agents-md
description: Use when repository files changed during the session and a finish line is near — before reporting a task, branch or session complete, before merging or opening a PR, at session end — even if you believe no instruction file exists, nothing needs updating, or the change is too small. The skill decides whether anything belongs there; pre-deciding its outcome is skipping it. Also use when auditing the instruction file for drift.
---

# Keep the agent instruction file accurate

Maintain the repository's agent instruction file as a minimal, accurate execution contract. Not documentation of the repository — only durable knowledge that changes how a future agent works and cannot be inferred reliably from the repo itself.

## When to run

Whenever repository files changed and the work is wrapping up. The trigger is the observable fact "files changed and we're finishing", **not** your judgment about whether the change mattered. Deciding significance is step 3's job, after inspection. Ending in "no update" is the expected common case, not wasted work.

Skip only when the session changed no repository files.

| Excuse | Reality |
|---|---|
| "There's no instruction file, so nothing to update" | Pre-deciding the outcome without inspecting is skipping the skill. |
| "The change is too small to matter" | "Meaningful" is decided in step 3, never at the trigger. |
| "The docs were already updated" | Instruction-file drift is a separate thing from README accuracy. |
| "Optionally I could audit…" | On a repo-changing session the audit is not optional. |

## 1. Find the right file

Different agents read different filenames — `AGENTS.md`, `CLAUDE.md`, and others. Find which ones this repo actually has, at the root and nested.

**Maintain one canonical file.** If the repo has several, keep the content in the canonical one and make the others point at it. Never maintain the same rules in two places; they will drift and a future agent will read the stale one.

## 2. Inspect

Read the existing instruction files, parent and nested, and treat their content as potentially stale.

Evidence order — earlier beats later when they disagree:

1. The current source and actual repository behavior
2. Tests and CI configuration
3. Package manifests and tooling configuration
4. Existing implementation patterns
5. The existing instruction files
6. Repository documentation
7. Decisions and corrections from this session

Never invent a command, a path, a convention or a constraint.

## 3. Decide what belongs

Look for changes touching: repository or module structure · architectural boundaries · dependencies or package manager · build, test, lint or format workflow · CI/CD · configuration and environment variables · APIs, integrations, data access · required validation steps · established implementation patterns · repo-wide or subsystem conventions · recurring agent mistakes · instructions that are now wrong.

Add or change an instruction only when it is relevant to future agents, durable, generalizable beyond this change, hard to infer from the repo, not already written down, and appropriate for this file.

> **The test: would removing this instruction plausibly cause a future agent to make a mistake?**

If not, don't add it. Prefer pointing at a canonical file or example over duplicating an explanation.

## 4. Choose the narrowest scope

Root file for repo-wide rules, nested file for a subsystem. Before adding: check the parent, check the children, avoid duplicating, avoid parent/child conflicts. Create a nested file only when the subsystem genuinely needs distinct instructions.

## 5. Update what's unambiguous, propose what isn't

**Update directly** when repository evidence makes it clear: a documented command no longer matches the config, a documented path is gone, a technology was replaced, the package manager changed, a required validation command changed. Make the smallest accurate change.

**Propose instead of writing** when it takes judgment — whether a new implementation is a permanent pattern, whether a session decision generalizes, whether an emerging habit should become a rule. A proposal states the instruction, the evidence, the intended scope, and what a future agent gains. When the evidence is weak, change nothing.

**Corrections:** document a correction only when it is likely to recur, specific to this repo, broadly applicable, and preventable by instruction. Write the resulting rule, never the incident.

## 6. Keep it small

Document: important structure, operational commands, architectural constraints, canonical patterns, required validation, constraints that prevent recurring mistakes.

Don't document: generic programming advice, personal preference, obvious facts about the code, temporary details, one-off fixes, speculative conventions, history with no operational value, anything already written elsewhere.

Right tool for the job — tooling for mechanically enforceable rules, documentation for reference material, skills for reusable workflows, the instruction file for concise rules that change agent behavior.

Before adding: *does this change behavior enough to justify permanent context?* Prefer `New endpoints follow the pattern in src/api/example.ts` over `ALL endpoints MUST ALWAYS follow exactly this pattern` unless the repo really requires the stronger form.

When the file gets too big: remove redundant rules, remove obsolete ones, move reference material to docs, move subsystem rules to nested files, reference examples instead of copying them. Don't add content because there is room.

## 7. Idempotency

Running this against an unchanged repository must produce no change. Don't add duplicates, don't rephrase existing rules, don't reorder or reformat, don't touch the file just because the skill ran.

## 8. Validate

Verify every referenced path exists. Verify every documented command against the actual configuration. Check parent and child interactions for duplication or contradiction. Confirm each new rule reflects real repository behavior. Read the final diff and remove anything without durable value.

## 9. Report exactly one outcome

- **No update** — existing instructions are accurate and no durable knowledge changed.
- **Updated** — drift or durable knowledge was found; the right file was minimally updated.
- **Proposed** — something potentially useful needs human judgment. *(state it, with evidence and scope)*
