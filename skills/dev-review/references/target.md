# The target

Read from `SKILL.md`, step 1, when the change is anything but the uncommitted work of the session's repository.

## Contents

- What is reviewed
- Where the code is read
- Own or foreign

## What is reviewed

Resolve it to a repo directory, `<repo>`, a base and a head. `<repo>` is the session's directory, or a local one the user names, read in place. Every git command of this step runs as `git -C <repo>`: the session's directory may be another repository.

- **Nothing named, and no uncommitted work**: the current branch against the commit where it left the default branch. On the default branch with a clean tree, ask.
- **A whole branch with its uncommitted work**, which is what a change built in this session asks for: `git -C <repo> diff <merge base>`, with no head, so the working tree is compared, plus every untracked file `git status --short --untracked-files=all` lists, read in full. Its head is `HEAD` wherever a step below needs one.
- **A branch, a range or a plan's slice**: diff from the merge base, or from the commit the slice started at. Compute the merge base with `git -C <repo> merge-base <base> <head>` and paste the commit it prints as the base: the verifier reads the base version of a file there.
- **Named paths** of any target above, when whoever asked names them: the same diff ending in `-- <paths>`, and of the untracked files only those among them.
- **The default branch** is the one the user names; else the one `git symbolic-ref refs/remotes/origin/HEAD` prints; else `main`; else `master`.
- **Code not on this machine** (a URL, a pull request): obtain it however the environment allows, into `<output>/code`, with the head under review checked out: it is then both `<repo>` and `<code>`, and the review's own files stay out of the code tree. When the environment can read a pull request's description and comments, read them; otherwise review without them and note it for `Not checked`.
- **No git at all**: the named files are the change, in full, and `<code>` is their directory; note it for `Not checked`.

Then check that each ref resolves (`git rev-parse --verify <ref>`) and that the change is not empty: either failure stops the review.

## Where the code is read

Obtained code is used as obtained; a tree not clean after checkout is noted for `Not checked`. Otherwise `<code>` is the checkout only when the change includes the uncommitted work itself, or its head is checked out and `git status --short` prints nothing: a dirty tree holds edits the diff leaves out. Else clone the head, `<sha>` being the commit `git -C <repo> rev-parse <head>` prints:

```bash
git clone -q --no-checkout <repo> <output>/code
git -C <output>/code checkout -q --detach <sha>
```

Never a checkout, a stash or a worktree in the user's repository: each writes into it.

## Own or foreign

The change is foreign when its code was obtained for this review, or when `git -C <repo> log --format=%ae <base>..<head>` prints an address other than `git -C <repo> config user.email`. Uncommitted work in the user's checkout is own, and so is a change this session built; on a branch reviewed with its uncommitted work, a commit by another author still makes the whole change foreign. With no git there is no author to compare: foreign, unless the user says the code is theirs. Unsure is foreign: running a stranger's code is the costlier mistake.
