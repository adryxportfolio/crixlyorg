# CLI Reference

Crixly CLI now supports both:

- instance setup/diagnostics (`onboard`, `doctor`, `configure`, `env`, `allowed-hostname`)
- control-plane client operations (issues, approvals, agents, activity, dashboard)

## Base Usage

Use repo script in development:

```sh
pnpm crixlyai --help
```

First-time local bootstrap + run:

```sh
pnpm crixlyai run
```

Choose local instance:

```sh
pnpm crixlyai run --instance dev
```

## Deployment Modes

Mode taxonomy and design intent are documented in `doc/DEPLOYMENT-MODES.md`.

Current CLI behavior:

- `crixlyai onboard` and `crixlyai configure --section server` set deployment mode in config
- runtime can override mode with `CRIXLY_DEPLOYMENT_MODE`
- `crixlyai run` and `crixlyai doctor` do not yet expose a direct `--mode` flag

Target behavior (planned) is documented in `doc/DEPLOYMENT-MODES.md` section 5.

Allow an authenticated/private hostname (for example custom Tailscale DNS):

```sh
pnpm crixlyai allowed-hostname dotta-macbook-pro
```

All client commands support:

- `--data-dir <path>`
- `--api-base <url>`
- `--api-key <token>`
- `--context <path>`
- `--profile <name>`
- `--json`

Company-scoped commands also support `--company-id <id>`.

Use `--data-dir` on any CLI command to isolate all default local state (config/context/db/logs/storage/secrets) away from `~/.crixly`:

```sh
pnpm crixlyai run --data-dir ./tmp/crixly-dev
pnpm crixlyai issue list --data-dir ./tmp/crixly-dev
```

## Context Profiles

Store local defaults in `~/.crixly/context.json`:

```sh
pnpm crixlyai context set --api-base http://localhost:3100 --company-id <company-id>
pnpm crixlyai context show
pnpm crixlyai context list
pnpm crixlyai context use default
```

To avoid storing secrets in context, set `apiKeyEnvVarName` and keep the key in env:

```sh
pnpm crixlyai context set --api-key-env-var-name CRIXLY_API_KEY
export CRIXLY_API_KEY=...
```

## Company Commands

```sh
pnpm crixlyai company list
pnpm crixlyai company get <company-id>
pnpm crixlyai company delete <company-id-or-prefix> --yes --confirm <same-id-or-prefix>
```

Examples:

```sh
pnpm crixlyai company delete PAP --yes --confirm PAP
pnpm crixlyai company delete 5cbe79ee-acb3-4597-896e-7662742593cd --yes --confirm 5cbe79ee-acb3-4597-896e-7662742593cd
```

Notes:

- Deletion is server-gated by `CRIXLY_ENABLE_COMPANY_DELETION`.
- With agent authentication, company deletion is company-scoped. Use the current company ID/prefix (for example via `--company-id` or `CRIXLY_COMPANY_ID`), not another company.

## Issue Commands

```sh
pnpm crixlyai issue list --company-id <company-id> [--status todo,in_progress] [--assignee-agent-id <agent-id>] [--match text]
pnpm crixlyai issue get <issue-id-or-identifier>
pnpm crixlyai issue create --company-id <company-id> --title "..." [--description "..."] [--status todo] [--priority high]
pnpm crixlyai issue update <issue-id> [--status in_progress] [--comment "..."]
pnpm crixlyai issue comment <issue-id> --body "..." [--reopen]
pnpm crixlyai issue checkout <issue-id> --agent-id <agent-id> [--expected-statuses todo,backlog,blocked]
pnpm crixlyai issue release <issue-id>
```

## Agent Commands

```sh
pnpm crixlyai agent list --company-id <company-id>
pnpm crixlyai agent get <agent-id>
pnpm crixlyai agent local-cli <agent-id-or-shortname> --company-id <company-id>
```

`agent local-cli` is the quickest way to run local Claude/Codex manually as a Crixly agent:

- creates a new long-lived agent API key
- installs missing Crixly skills into `~/.codex/skills` and `~/.claude/skills`
- prints `export ...` lines for `CRIXLY_API_URL`, `CRIXLY_COMPANY_ID`, `CRIXLY_AGENT_ID`, and `CRIXLY_API_KEY`

Example for shortname-based local setup:

```sh
pnpm crixlyai agent local-cli codexcoder --company-id <company-id>
pnpm crixlyai agent local-cli claudecoder --company-id <company-id>
```

## Approval Commands

```sh
pnpm crixlyai approval list --company-id <company-id> [--status pending]
pnpm crixlyai approval get <approval-id>
pnpm crixlyai approval create --company-id <company-id> --type hire_agent --payload '{"name":"..."}' [--issue-ids <id1,id2>]
pnpm crixlyai approval approve <approval-id> [--decision-note "..."]
pnpm crixlyai approval reject <approval-id> [--decision-note "..."]
pnpm crixlyai approval request-revision <approval-id> [--decision-note "..."]
pnpm crixlyai approval resubmit <approval-id> [--payload '{"...":"..."}']
pnpm crixlyai approval comment <approval-id> --body "..."
```

## Activity Commands

```sh
pnpm crixlyai activity list --company-id <company-id> [--agent-id <agent-id>] [--entity-type issue] [--entity-id <id>]
```

## Dashboard Commands

```sh
pnpm crixlyai dashboard get --company-id <company-id>
```

## Heartbeat Command

`heartbeat run` now also supports context/api-key options and uses the shared client stack:

```sh
pnpm crixlyai heartbeat run --agent-id <agent-id> [--api-base http://localhost:3100] [--api-key <token>]
```

## Local Storage Defaults

Default local instance root is `~/.crixly/instances/default`:

- config: `~/.crixly/instances/default/config.json`
- embedded db: `~/.crixly/instances/default/db`
- logs: `~/.crixly/instances/default/logs`
- storage: `~/.crixly/instances/default/data/storage`
- secrets key: `~/.crixly/instances/default/secrets/master.key`

Override base home or instance with env vars:

```sh
CRIXLY_HOME=/custom/home CRIXLY_INSTANCE_ID=dev pnpm crixlyai run
```

## Storage Configuration

Configure storage provider and settings:

```sh
pnpm crixlyai configure --section storage
```

Supported providers:

- `local_disk` (default; local single-user installs)
- `s3` (S3-compatible object storage)
