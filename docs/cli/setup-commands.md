---
title: Setup Commands
summary: Onboard, run, doctor, and configure
---

Instance setup and diagnostics commands.

## `crixlyai run`

One-command bootstrap and start:

```sh
pnpm crixlyai run
```

Does:

1. Auto-onboards if config is missing
2. Runs `crixlyai doctor` with repair enabled
3. Starts the server when checks pass

Choose a specific instance:

```sh
pnpm crixlyai run --instance dev
```

## `crixlyai onboard`

Interactive first-time setup:

```sh
pnpm crixlyai onboard
```

First prompt:

1. `Quickstart` (recommended): local defaults (embedded database, no LLM provider, local disk storage, default secrets)
2. `Advanced setup`: full interactive configuration

Start immediately after onboarding:

```sh
pnpm crixlyai onboard --run
```

Non-interactive defaults + immediate start (opens browser on server listen):

```sh
pnpm crixlyai onboard --yes
```

## `crixlyai doctor`

Health checks with optional auto-repair:

```sh
pnpm crixlyai doctor
pnpm crixlyai doctor --repair
```

Validates:

- Server configuration
- Database connectivity
- Secrets adapter configuration
- Storage configuration
- Missing key files

## `crixlyai configure`

Update configuration sections:

```sh
pnpm crixlyai configure --section server
pnpm crixlyai configure --section secrets
pnpm crixlyai configure --section storage
```

## `crixlyai env`

Show resolved environment configuration:

```sh
pnpm crixlyai env
```

## `crixlyai allowed-hostname`

Allow a private hostname for authenticated/private mode:

```sh
pnpm crixlyai allowed-hostname my-tailscale-host
```

## Local Storage Paths

| Data | Default Path |
|------|-------------|
| Config | `~/.crixly/instances/default/config.json` |
| Database | `~/.crixly/instances/default/db` |
| Logs | `~/.crixly/instances/default/logs` |
| Storage | `~/.crixly/instances/default/data/storage` |
| Secrets key | `~/.crixly/instances/default/secrets/master.key` |

Override with:

```sh
CRIXLY_HOME=/custom/home CRIXLY_INSTANCE_ID=dev pnpm crixlyai run
```

Or pass `--data-dir` directly on any command:

```sh
pnpm crixlyai run --data-dir ./tmp/crixly-dev
pnpm crixlyai doctor --data-dir ./tmp/crixly-dev
```
