---
name: moia-handle-jira
description: Manage Jira tickets using the acli CLI. Use when creating tickets, transitioning ticket status, or viewing ticket details.
---

# Jira Ticket Management

Use `acli` (Atlassian CLI) for all Jira operations. Verify availability with `which acli`.

Only create Sub-task tickets. If no parent ticket was provided, ask the user for one before proceeding.

## Creating Tickets

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
| `summary` | Ticket title (Prefix with "[iOS] ") |
| `projectKey` | Jira project key |
| `type` | `Epic`, `Story`, `Task`, `Sub-task`, or `Bug` |
| `parentIssueId` | Parent ticket key (required for Sub-task) |
| `additionalAttributes` | Fields without dedicated JSON keys (e.g. `components`) |

### Hierarchy

```
Epic (level 1)
  Story / Task / Bug (level 0)
    Sub-task (level -1)
```

A child type must be exactly one level below its parent. Creating a Task under a Story fails with "does not belong to appropriate hierarchy" — use `Sub-task` instead.

### Components

Components are set via `additionalAttributes.components` as an array of `{"name": "..."}` objects. No direct CLI flag exists. If no components are specified, use "PAS iOS" and "Mobile Platform".

### Discovering the JSON Schema

```bash
acli jira workitem create --generate-json
```

## Transitioning Tickets

```bash
acli jira workitem transition --key "MOIA-123456" --status "In Development" --yes
```

Common statuses: `Open`, `In Development`, `In Review`, `Done`.

The `--yes` flag skips the confirmation prompt.

## Viewing Tickets

```bash
acli jira workitem view MOIA-123456
acli jira workitem view MOIA-123456 --json
```
