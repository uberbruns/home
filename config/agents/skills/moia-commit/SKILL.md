---
name: moia-commit
description: Create a git commit for staged changes with a conventional commit message prefixed by the Jira ticket ID.
---

# Create Commit

Create a git commit for the currently staged changes.

## Steps

1. Examine staged files: `git diff --cached --name-status`
2. Extract the ticket ID (`MOIA-xxxxxx`) from the current branch name
3. If needed, fetch ticket context: `acli jira workitem view MOIA-xxxxxx`
4. Create the commit

## Commit Message Format

- Prefix with ticket ID: `MOIA-xxxxxx: <message>`
- Use imperative mood (Add/Fix/Update, not Added/Fixed/Updated)
- Summarize what the change accomplishes, not what files changed
- Keep to one line, 50-72 characters if possible
- No bullet points, no body
- No coauthorship