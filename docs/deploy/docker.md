---
title: Docker
summary: Docker Compose quickstart
---

Run Crixly in Docker without installing Node or pnpm locally.

## Compose Quickstart (Recommended)

```sh
docker compose -f docker-compose.quickstart.yml up --build
```

Open [http://localhost:3100](http://localhost:3100).

Defaults:

- Host port: `3100`
- Data directory: `./data/docker-crixly`

Override with environment variables:

```sh
CRIXLY_PORT=3200 CRIXLY_DATA_DIR=./data/pc \
  docker compose -f docker-compose.quickstart.yml up --build
```

## Manual Docker Build

```sh
docker build -t crixly-local .
docker run --name crixly \
  -p 3100:3100 \
  -e HOST=0.0.0.0 \
  -e CRIXLY_HOME=/crixly \
  -v "$(pwd)/data/docker-crixly:/crixly" \
  crixly-local
```

## Data Persistence

All data is persisted under the bind mount (`./data/docker-crixly`):

- Embedded PostgreSQL data
- Uploaded assets
- Local secrets key
- Agent workspace data

## Claude and Codex Adapters in Docker

The Docker image pre-installs:

- `claude` (Anthropic Claude Code CLI)
- `codex` (OpenAI Codex CLI)

Pass API keys to enable local adapter runs inside the container:

```sh
docker run --name crixly \
  -p 3100:3100 \
  -e HOST=0.0.0.0 \
  -e CRIXLY_HOME=/crixly \
  -e OPENAI_API_KEY=sk-... \
  -e ANTHROPIC_API_KEY=sk-... \
  -v "$(pwd)/data/docker-crixly:/crixly" \
  crixly-local
```

Without API keys, the app runs normally — adapter environment checks will surface missing prerequisites.
