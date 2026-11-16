# The checks

Read from `SKILL.md`, step 4, before any reviewer is dispatched. A caller may ask for one section alone.

## Contents

- The commands
- Instruction files
- What a result does

## The commands

On an own change only; on a foreign one each line of the report reads `not run: foreign`. Run each of these in `<code>` and read its output:

- the project's **full** test suite, not the files the change touched;
- the type checker, if the repo uses one;
- the linter and the formatter the repo uses, the formatter in check mode. Lines it would change that the diff did not touch are pre-existing;
- the build, if there is one;
- the changed behavior once through its real entry point (the command, the request, the page), when the tests reach it only through substitutes and it runs locally in a minute. Otherwise the line reads `n/a`.

For each, keep the exact command, the exit code, the counts, and the summary and failure lines, not the whole log. A tool the repo does not have is `none configured`, never skipped in silence. A red test the baseline already showed is named as pre-existing, with the baseline; with no baseline it is reported red.

`<code>` may be a clone with no dependencies installed. Install nothing there: the line reads `not run: <why>`.

## Instruction files

On every change, own or foreign: a search, never an edit. Two checks against the repo's agent instruction files (`AGENTS.md`, `CLAUDE.md`, nested ones):

- **Changed names**: search them for every path, command and name the diff renames, removes or changes.
- **New operational facts**: does the diff add a dependency, a build, test, lint or format command, a CI step, a config key or environment variable, or a top-level directory, of a kind the file already documents?

Neither hits: `no update`, the common case; the search is the inspection, so run it however small the change looks. Either hits:

- **A line this diff made wrong, or a new fact of a kind the file already lists**: `update: <path>:<line> → <what is true now>`, checked against the repo.
- **A new convention, a rule drawn from a session decision, or drift older than this change**: `proposed: <instruction — evidence — gain>`, the gain being what a future agent gets from it.
- **The line is still accurate**: `no update`.

## What a result does

- A command that fails, and that the baseline did not show failing, makes the verdict `Fix first`, named beside the findings' numbers.
- An `update` line does the same, named `agent file`.
- A command that could not run on an own change makes the verdict `Not settled`.
- `not run: foreign`, `none configured`, `n/a`, `no update` and `proposed` change no verdict.
