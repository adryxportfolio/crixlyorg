#!/usr/bin/env bash
set -euo pipefail

if ! command -v node >/dev/null 2>&1; then
  echo "Error: Node.js 20+ is required. Install Node.js first: https://nodejs.org" >&2
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "Error: npm/npx is required but was not found in PATH." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required. Install git first: https://git-scm.com" >&2
  exit 1
fi

NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
if [ "$NODE_MAJOR" -lt 20 ]; then
  echo "Error: Node.js 20+ is required. Current version: $(node -v)" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  if ! command -v corepack >/dev/null 2>&1; then
    echo "Error: pnpm is required (or corepack to install it)." >&2
    exit 1
  fi
  corepack enable >/dev/null 2>&1 || true
  corepack prepare pnpm@9.15.4 --activate >/dev/null 2>&1
fi

REPO_URL="${CRIXLY_REPO_URL:-https://github.com/adryxportfolio/crixlyorg.git}"
INSTALL_DIR="${CRIXLY_INSTALL_DIR:-$HOME/crixlyorg}"

echo "Installing and starting Crixly from $REPO_URL..."
echo "Install directory: $INSTALL_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
pnpm install
pnpm crixlyai onboard --yes

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:3100" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:3100" >/dev/null 2>&1 || true
fi

echo
echo "Crixly install complete."
echo "Open http://localhost:3100"
