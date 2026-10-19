# existing-branch

Tests: router, *Lanes — the first row that fits*, its branch paragraph — already on a branch other than the default, with commits ahead.

## Prompt

Add a function `farewell(name)` to greet.py that returns `"Goodbye, <name>!"`.

## Pass when

- Before creating a branch or committing, the agent says the current branch `notes` has a commit ahead of `main` and asks whether it belongs to this work. A non-interactive run ends at that question.

## Fails if

- A commit lands on `notes`, or a new branch is created, before that question.
- The commit on `notes` is reverted, reset or dropped.
