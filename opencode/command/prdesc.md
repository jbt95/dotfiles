---
description: Generate a Markdown PR description for the current branch and copy it to the clipboard.
---

Generate a Markdown pull request description for the current Git branch and copy it to the system clipboard.

## Workflow

1. **Determine the base branch**
   - If `$1` is provided, use it.
   - Otherwise try `main`, then `master`. If the local ref does not exist, try `origin/main` then `origin/master`.
   - Verify that the chosen base is an ancestor of `HEAD` with `git merge-base --is-ancestor <base> HEAD`. If not, report the issue and pick the closest common ancestor instead.

2. **Gather context with bash**
   - Current branch name: `git rev-parse --abbrev-ref HEAD`
   - Commits since base: `git log --reverse --pretty=format:'- %s'` (include commit bodies if they add useful detail)
   - Files changed: `git diff --stat <base>..HEAD`
   - Optional: one-line high-level summary from the most recent commit or the branch name.

3. **Compose a Markdown PR description**
   - A concise title line (optional).
   - `## What changed` section summarizing the commits and intent.
   - `## Files changed` section with the diff stat.
   - `## Verification` section mentioning any passing checks/tests if they are clearly applicable; otherwise omit.

4. **Copy to clipboard**
   - Write the final Markdown to a temporary file.
   - Run `cat <temp-file> | pbcopy` on macOS.
   - Confirm once copied. Print the description only if the user explicitly asks for it.

If not inside a Git repository, report that this command must be run from within a repo. Do not create or modify repository files.
