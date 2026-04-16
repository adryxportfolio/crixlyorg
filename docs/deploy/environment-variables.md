---
title: Environment Variables
summary: Full environment variable reference
---

All environment variables that Crixly uses for server configuration.

## Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3100` | Server port |
| `HOST` | `127.0.0.1` | Server host binding |
| `DATABASE_URL` | (embedded) | PostgreSQL connection string |
| `CRIXLY_HOME` | `~/.crixly` | Base directory for all Crixly data |
| `CRIXLY_INSTANCE_ID` | `default` | Instance identifier (for multiple local instances) |
| `CRIXLY_DEPLOYMENT_MODE` | `local_trusted` | Runtime mode override |

## Secrets

| Variable | Default | Description |
|----------|---------|-------------|
| `CRIXLY_SECRETS_MASTER_KEY` | (from file) | 32-byte encryption key (base64/hex/raw) |
| `CRIXLY_SECRETS_MASTER_KEY_FILE` | `~/.crixly/.../secrets/master.key` | Path to key file |
| `CRIXLY_SECRETS_STRICT_MODE` | `false` | Require secret refs for sensitive env vars |

## Agent Runtime (Injected into agent processes)

These are set automatically by the server when invoking agents:

| Variable | Description |
|----------|-------------|
| `CRIXLY_AGENT_ID` | Agent's unique ID |
| `CRIXLY_COMPANY_ID` | Company ID |
| `CRIXLY_API_URL` | Crixly API base URL |
| `CRIXLY_API_KEY` | Short-lived JWT for API auth |
| `CRIXLY_RUN_ID` | Current heartbeat run ID |
| `CRIXLY_TASK_ID` | Issue that triggered this wake |
| `CRIXLY_WAKE_REASON` | Wake trigger reason |
| `CRIXLY_WAKE_COMMENT_ID` | Comment that triggered this wake |
| `CRIXLY_APPROVAL_ID` | Resolved approval ID |
| `CRIXLY_APPROVAL_STATUS` | Approval decision |
| `CRIXLY_LINKED_ISSUE_IDS` | Comma-separated linked issue IDs |

## LLM Provider Keys (for adapters)

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API key (for Claude Local adapter) |
| `OPENAI_API_KEY` | OpenAI API key (for Codex Local adapter) |
