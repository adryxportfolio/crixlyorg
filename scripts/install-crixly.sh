#!/usr/bin/env bash
set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js 20+ is required. Install Node.js first: https://nodejs.org" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npx is required but was not found in PATH." >&2
  exit 1
fi

NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "Error: Node.js 20+ is required. Current version: $(node -v)" >&2
  exit 1
fi

echo "Installing and starting Crixly..."
echo "This may take a minute on first run."

npx --yes crixlyai onboard --yes

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:3100" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:3100" >/dev/null 2>&1 || true
fi

echo
echo "Crixly install complete."
echo "Open http://localhost:3100"
