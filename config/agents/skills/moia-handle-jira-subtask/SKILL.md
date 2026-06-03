---
name: moia-handle-jira-subtask
description: Manage Jira subtasks using the acli CLI. Use when creating Jira Sub-task work items or when the user asks for a Jira subtask. Requires a parent issue before creating a subtask.
---

# Jira Subtask Management

Use `acli` (Atlassian CLI) for all Jira operations. Verify availability with `which acli`.

Only create `Sub-task` tickets with this skill. A parent ticket is required. If no parent ticket was provided, ask the user for one before creating the subtask.

## Creating Subtasks

Use `--from-json` with a JSON payload via stdin:

```bash
acli jira workitem create --from-json /dev/stdin << 'EOF'
{
  "summary": "Ticket summary here",
  "projectKey": "MOIA",
  "type": "Sub-task",
  "parentIssueId": "MOIA-123456",
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
| `type` | Must be `Sub-task` |
| `parentIssueId` | Parent ticket key (required) |
| `additionalAttributes` | Fields without dedicated JSON keys (e.g. `components`) |

### Hierarchy

```
Epic (level 1)
  Story / Task / Bug (level 0)
    Sub-task (level -1)
```

A subtask parent must be a level 0 issue such as `Story`, `Task`, or `Bug`. Creating a subtask under an Epic fails because it skips a hierarchy level.

### Components

Components are set via `additionalAttributes.components` as an array of `{"name": "..."}` objects. No direct CLI flag exists. If no components are specified, use "PAS iOS" and "Mobile Platform".

### Discovering the JSON Schema

```bash
acli jira workitem create --generate-json
```

## Transitioning Subtasks

```bash
acli jira workitem transition --key "MOIA-123456" --status "In Development" --yes
```

Common statuses: `Open`, `In Development`, `In Review`, `Done`.

The `--yes` flag skips the confirmation prompt.

## Viewing Subtasks

```bash
acli jira workitem view MOIA-123456
acli jira workitem view MOIA-123456 --json
```
