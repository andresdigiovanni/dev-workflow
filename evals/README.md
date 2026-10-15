# evals

Scenarios that check the skills, not the code: each one is a small repository with a trap in it, a prompt, and what the agent must and must not do. `dev-skills`, *Check that it fires*, says to run a scenario before and after every edit that changes behavior; this folder keeps those scenarios so they can be run again — after an edit to another skill, or on a new model.

Nothing here is installed; `install.sh` copies only `skills/` and the router.

## Run one

```
evals/setup.sh <scenario> <new empty dir> [claude|opencode]
```

It copies the scenario's `repo/` into the directory, installs this checkout's skills and router into it at project scope, commits everything on `main`, and prints the prompt. Then, from that directory, start a **fresh** session — no hint about which skill is under test — and paste the prompt as written.

Several scenarios pass by the agent stopping to ask. Answer nothing: the question, with its options and a recommendation, is the result. A non-interactive run (`claude -p "<prompt>"`) ends at that question, which is enough.

## Read the result

Check each line of the scenario's `Pass when` against what happened — the conversation, `git log`, and `git diff main` on the branch the agent made. One `Fails if` line seen is a fail, however good the rest looks.

Run it on the smallest model the set is meant to work with as well as the strongest: a strong model often passes without the skill's help, so its pass says little about a weaker one.

## Add one

Only for a trap an agent has actually fallen into. A folder with:

- `scenario.md` — `Tests:` (the skill and section under test), `## Prompt`, `## Pass when`, `## Fails if`;
- `repo/` — the smallest repository that holds the trap. Python and `unittest`, so it runs anywhere with `python3`; its README names the test and check commands.

## Scenarios

| Scenario | The trap |
|---|---|
| `change-pinned-value` | a test pins the old value; "just make it pass" |
| `debug-empty-average` | a crash fix whose expected result nobody gave |
| `retry-two-readings` | "retry 3 times" — 3 calls or 4? |
| `bent-check` | a red lint check that's easier to switch off than to satisfy |
| `upload-path` | a file read by name, one `../` from a secret |
| `cache-expiry` | a fixed duration that invites a new knob |
