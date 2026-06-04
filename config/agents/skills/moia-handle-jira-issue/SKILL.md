---
name: moia-handle-jira-issue
description: Manage Jira issues using the acli CLI. Use when creating non-subtask Jira issues, transitioning issue status, or viewing issue details. Does not require a parent issue.
---

# Jira Issue Management

Use `acli` (Atlassian CLI) for all Jira operations. Verify availability with `which acli`, then check Jira authentication with `acli jira auth status`.

Use this skill for Jira work items that are not subtasks, such as `Epic`, `Story`, `Task`, or `Bug`.
Do not require a parent ticket. Only include parent fields when the user explicitly asks for a hierarchy that supports them.

## Creating Issues

Use `--from-json` with a JSON payload via stdin:

```bash
acli jira workitem create --from-json /dev/stdin << 'EOF'
{
  "summary": "Ticket summary here",
  "projectKey": "MOIA",
  "type": "Task",
  "additionalAttributes": {
    "components": [
      {"name": "Component A"},
      {"name": "Component B"}
    ]
  }
}
EOF
```

### JSON Fields

| Field | Description |
|---|---|
| `summary` | Ticket title (Prefix with "[iOS] " for iOS work) |
| `projectKey` | Jira project key |
| `type` | `Epic`, `Story`, `Task`, or `Bug` |
| `additionalAttributes` | Fields without dedicated JSON keys (e.g. `components`) |

### Hierarchy

```
Epic (level 1)
  Story / Task / Bug (level 0)
    Sub-task (level -1)
```

A child type must be exactly one level below its parent. Creating a Task under a Story fails with "does not belong to appropriate hierarchy" - use `Sub-task` instead.

### Components

Components are set via `additionalAttributes.components` as an array of `{"name": "..."}` objects. No direct CLI flag exists. If no components are specified, use "PAS iOS" and "Mobile Platform".

### Discovering the JSON Schema

```bash
acli jira workitem create --generate-json
```

## Transitioning Issues

```bash
acli jira workitem transition --key "MOIA-123456" --status "In Development" --yes
```

Common statuses: `Open`, `In Development`, `In Review`, `Done`.

The `--yes` flag skips the confirmation prompt.

## Viewing Issues

```bash
acli jira workitem view MOIA-123456
acli jira workitem view MOIA-123456 --json
```
