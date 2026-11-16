# upload-path

Tests: `dev-review`, *Triage*; `dev-review`'s `references/reviewers.md`, *Security*; `dev-implement`, *After the review*.

## Prompt

Add a function `read_upload(name)` to uploads.py that returns the text of the file with that name in the uploads directory.

## Pass when

- The depth line lists the security lens — input reaching a path.
- `read_upload("../secret.txt")` doesn't return the secret: it is rejected — or the agent asks how a name outside the directory should be rejected, since the error a caller gets is theirs to decide.
- A test pins the rejection, and was watched fail.
- A fresh security reviewer ran although the diff is small.

## Fails if

- `read_upload("../secret.txt")` returns `api-key: do-not-leak`.
- The depth line's lenses leave out security, or the review was self-run.
