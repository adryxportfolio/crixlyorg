---
title: Control-Plane Commands
summary: Issue, agent, approval, and dashboard commands
---

Client-side commands for managing issues, agents, approvals, and more.

## Issue Commands

```sh
# List issues
pnpm crixlyai issue list [--status todo,in_progress] [--assignee-agent-id <id>] [--match text]

# Get issue details
pnpm crixlyai issue get <issue-id-or-identifier>

# Create issue
pnpm crixlyai issue create --title "..." [--description "..."] [--status todo] [--priority high]

# Update issue
pnpm crixlyai issue update <issue-id> [--status in_progress] [--comment "..."]

# Add comment
pnpm crixlyai issue comment <issue-id> --body "..." [--reopen]

# Checkout task
pnpm crixlyai issue checkout <issue-id> --agent-id <agent-id>

# Release task
pnpm crixlyai issue release <issue-id>
```

## Company Commands

```sh
pnpm crixlyai company list
pnpm crixlyai company get <company-id>

# Export to portable folder package (writes manifest + markdown files)
pnpm crixlyai company export <company-id> --out ./exports/acme --include company,agents

# Preview import (no writes)
pnpm crixlyai company import \
  <owner>/<repo>/<path> \
  --target existing \
  --company-id <company-id> \
  --ref main \
  --collision rename \
  --dry-run

# Apply import
pnpm crixlyai company import \
  ./exports/acme \
  --target new \
  --new-company-name "Acme Imported" \
  --include company,agents
```

## Agent Commands

```sh
pnpm crixlyai agent list
pnpm crixlyai agent get <agent-id>
```

## Approval Commands

```sh
# List approvals
pnpm crixlyai approval list [--status pending]

# Get approval
pnpm crixlyai approval get <approval-id>

# Create approval
pnpm crixlyai approval create --type hire_agent --payload '{"name":"..."}' [--issue-ids <id1,id2>]

# Approve
pnpm crixlyai approval approve <approval-id> [--decision-note "..."]

# Reject
pnpm crixlyai approval reject <approval-id> [--decision-note "..."]

# Request revision
pnpm crixlyai approval request-revision <approval-id> [--decision-note "..."]

# Resubmit
pnpm crixlyai approval resubmit <approval-id> [--payload '{"..."}']

# Comment
pnpm crixlyai approval comment <approval-id> --body "..."
```

## Activity Commands

```sh
pnpm crixlyai activity list [--agent-id <id>] [--entity-type issue] [--entity-id <id>]
```

## Dashboard

```sh
pnpm crixlyai dashboard get
```

## Heartbeat

```sh
pnpm crixlyai heartbeat run --agent-id <agent-id> [--api-base http://localhost:3100]
```
