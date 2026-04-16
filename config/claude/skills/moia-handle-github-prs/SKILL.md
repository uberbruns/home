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
## Summary
- First change
- Second change

## Test plan
- [ ] `mise run sdk:test`
- [ ] `mise run demo:build`

## Relevant Issues
* https://moia-dev.atlassian.net/browse/MOIA-123456
EOF
)"
```

### Sections

**Summary** (required): Bullet points describing the changes. Focus on what changed and why, not implementation details.

**Test plan** (required): Checkbox items describing how to verify the changes. Include relevant `mise run` commands.

**Relevant Issues** (required): Link to the Jira ticket.

The following sections are optional. Only include them when they add value — omit for straightforward changes:

**Motivation and Context**: Why this change is needed, what is better with it, dependencies on other PRs.

**Where to start reviewing**: Guide the reviewer through the code. Point out areas where feedback is especially wanted.

**Reviewer checklist**: Expectations for the reviewer as PR author.

**Documentation status**: Checkbox indicating whether documentation was updated.

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
