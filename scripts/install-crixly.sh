#!/usr/bin/env bash
set -euo pipefail

section() {
  printf "\n==> %s\n" "$1"
}

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
    if [ "$NODE_MAJOR" -ge 20 ]; then
      return
    fi
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "Node.js 20+ not found. Installing via Homebrew..."
    brew install node@20 >/dev/null
    if ! command -v node >/dev/null 2>&1 && [ -x "/opt/homebrew/opt/node@20/bin/node" ]; then
      export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    echo "Node.js 20+ not found. Installing via apt..."
    sudo apt-get update -y >/dev/null
    sudo apt-get install -y ca-certificates curl gnupg >/dev/null
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
    sudo apt-get update -y >/dev/null
    sudo apt-get install -y nodejs >/dev/null
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "Error: Node.js 20+ is required. Install Node.js first: https://nodejs.org" >&2
    exit 1
  fi

  NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
  if [ "$NODE_MAJOR" -lt 20 ]; then
    echo "Error: Node.js 20+ is required. Current version: $(node -v)" >&2
    exit 1
  fi
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi
  if ! command -v corepack >/dev/null 2>&1; then
    echo "Error: pnpm is required (or corepack to install it)." >&2
    exit 1
  fi
  corepack enable >/dev/null 2>&1 || true
  corepack prepare pnpm@9.15.4 --activate >/dev/null 2>&1
}

wait_for_health() {
  local base_port="$1"
  local timeout="${2:-180}"
  local max_offset="${3:-100}"
  local elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    for offset in $(seq 0 "$max_offset"); do
      local port=$((base_port + offset))
      local url="http://localhost:${port}/api/health"
      if curl -fsS "$url" >/dev/null 2>&1; then
        echo "$port"
        return 0
      fi
    done
    sleep 2
    elapsed=$((elapsed + 2))
  done
  return 1
}

section "Checking dependencies"
ensure_node
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required. Install git first: https://git-scm.com" >&2
  exit 1
fi
ensure_pnpm

REPO_URL="${CRIXLY_REPO_URL:-https://github.com/adryxportfolio/crixlyorg.git}"
INSTALL_DIR="${CRIXLY_INSTALL_DIR:-$HOME/crixlyorg}"
BASE_PORT="${PORT:-3100}"
CRIXLY_HOME="${CRIXLY_HOME:-$INSTALL_DIR/.crixly}"

section "Preparing install directory"
echo "Installing and starting Crixly from $REPO_URL..."
echo "Install directory: $INSTALL_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
export CRIXLY_HOME
mkdir -p "$CRIXLY_HOME"

section "Installing dependencies"
pnpm install

section "Applying runtime defaults"
pnpm setup:env

section "Building CRIXLY"
pnpm build

# Install global crixlyai/crixly shims into user PATH.
SHIM_DIR="${HOME}/.crixly/bin"
mkdir -p "$SHIM_DIR"
section "Installing global command shims"
cat > "$SHIM_DIR/crixlyai" <<EOF
#!/usr/bin/env bash
export CRIXLY_HOME="$CRIXLY_HOME"
pnpm --dir "$INSTALL_DIR" crixlyai "\$@"
EOF
chmod +x "$SHIM_DIR/crixlyai"
cat > "$SHIM_DIR/crixly" <<EOF
#!/usr/bin/env bash
export CRIXLY_HOME="$CRIXLY_HOME"
pnpm --dir "$INSTALL_DIR" crixlyai "\$@"
EOF
chmod +x "$SHIM_DIR/crixly"

case ":${PATH}:" in
  *":${SHIM_DIR}:"*) ;;
  *)
    export PATH="${SHIM_DIR}:${PATH}"
    if [ -f "${HOME}/.bashrc" ] && ! grep -Fq 'export PATH="$HOME/.crixly/bin:$PATH"' "${HOME}/.bashrc"; then
      printf '\nexport PATH="$HOME/.crixly/bin:$PATH"\n' >> "${HOME}/.bashrc"
    fi
    if [ -f "${HOME}/.zshrc" ] && ! grep -Fq 'export PATH="$HOME/.crixly/bin:$PATH"' "${HOME}/.zshrc"; then
      printf '\nexport PATH="$HOME/.crixly/bin:$PATH"\n' >> "${HOME}/.zshrc"
    fi
    ;;
esac

section "Starting CRIXLY"
mkdir -p "${HOME}/.crixly/logs"
nohup env CRIXLY_HOME="$CRIXLY_HOME" pnpm start > "${HOME}/.crixly/logs/server.log" 2>&1 &

RUNNING_PORT="$(wait_for_health "$BASE_PORT" 180 100 || true)"
if [ -z "$RUNNING_PORT" ]; then
  echo "Error: CRIXLY failed health check on ports ${BASE_PORT}-$((BASE_PORT + 100))" >&2
  echo "Inspect logs: ${HOME}/.crixly/logs/server.log" >&2
  exit 1
fi

if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "http://localhost:${RUNNING_PORT}" >/dev/null 2>&1 || true
elif command -v open >/dev/null 2>&1; then
  open "http://localhost:${RUNNING_PORT}" >/dev/null 2>&1 || true
fi

echo
echo "CRIXLY is running at http://localhost:${RUNNING_PORT}"
echo "Global commands installed: crixlyai, crixly"
echo "Logs: ${HOME}/.crixly/logs/server.log"
