---
name: moia-handle-github-prs
description: Create GitHub pull requests following project conventions. Use when creating PRs, preparing branches for review, or pushing changes upstream.
---

# GitHub Pull Request Management

Use `gh` CLI for all GitHub operations.

## Branch Naming

```
feature/MOIA-<ticket-id>-<kebab-case-slug>
task/MOIA-<ticket-id>-<kebab-case-slug>
```

Use `feature/` for changes that expand the SDK API surface or extend the UI. Use `task/` for technical changes (tooling, refactoring, infrastructure, build config).

## PR Creation Workflow

1. Extract the ticket number from the branch name (format: `TYPE/MOIA-xxxxxx-slug`)
2. Fetch Jira ticket details: `acli jira workitem view MOIA-xxxxxx`
3. Examine the branch changes, excluding what was merged from the base branch
4. Determine the PR label from the branch prefix:
   - `feature/` → **Feature**
   - `bug/` → **Bug**
   - `hotfix/` → **Hotfix**
   - Everything else → **Task**
5. Create the PR with `gh pr create`, add the label, and assign yourself
6. Push with `-u` flag before creating the PR if not yet pushed

## PR Title

```
MOIA-<ticket-id>: <short description>
```

Keep under 70 characters.

## PR Body Structure

Use a HEREDOC to pass the body:

```bash
gh pr create --draft --title "MOIA-123456: Short description" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

### Content

If the repository contains `.github/PULL_REQUEST_TEMPLATE.md`, the PR body MUST follow that template's structure. Remove sections from the template that do not apply to the change — do not leave empty headings or placeholder text.

If no template exists, structure the body as prose or short bullet points covering:

- What changed and why
- How to verify the changes (relevant `mise run` commands or manual steps)
- A link to the Jira ticket: `https://moia-dev.atlassian.net/browse/MOIA-xxxxxx`

Only include additional context (motivation, reviewer guidance, documentation status) when it adds information the diff alone does not convey.

### Stacked PRs

When a PR targets a feature branch instead of `main`, add an `[!IMPORTANT]` callout at the top documenting the merge dependency:

```markdown
> [!IMPORTANT]
> This PR targets `feature/MOIA-123456-base-branch` and must be merged **after** that branch is merged.
```

## Post-Creation

After creating the PR, add the label and assignee:

```bash
gh pr edit <number> --add-label "Feature" --add-assignee "@me"
```

## Base Branch

Default base is `main`. When stacking PRs, specify the base explicitly:

```bash
gh pr create --base feature/MOIA-123456-base-branch ...
```
