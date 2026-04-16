$ErrorActionPreference = "Stop"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error "Node.js 20+ is required. Install Node.js first: https://nodejs.org"
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  Write-Error "npm/npx is required but was not found in PATH."
}

$nodeVersionRaw = node -p "process.versions.node"
$nodeMajor = [int]($nodeVersionRaw.Split(".")[0])
if ($nodeMajor -lt 20) {
  Write-Error "Node.js 20+ is required. Current version: $(node -v)"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is required. Install git first: https://git-scm.com"
}

if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command corepack -ErrorAction SilentlyContinue)) {
    Write-Error "pnpm is required (or corepack to install it)."
  }
  corepack enable | Out-Null
  corepack prepare pnpm@9.15.4 --activate | Out-Null
}

$repoUrl = if ($env:CRIXLY_REPO_URL) { $env:CRIXLY_REPO_URL } else { "https://github.com/adryxportfolio/crixlyorg.git" }
$installDir = if ($env:CRIXLY_INSTALL_DIR) { $env:CRIXLY_INSTALL_DIR } else { Join-Path $HOME "crixlyorg" }

Write-Host "Installing and starting Crixly from $repoUrl..."
Write-Host "Install directory: $installDir"

if (Test-Path (Join-Path $installDir ".git")) {
  git -C $installDir pull --ff-only
} else {
  git clone $repoUrl $installDir
}

Set-Location $installDir
pnpm install

pnpm crixlyai onboard --yes

try {
  Start-Process "http://localhost:3100" | Out-Null
} catch {
  # Ignore browser auto-open failures; installer already succeeded.
}

Write-Host ""
Write-Host "Crixly install complete."
Write-Host "Open http://localhost:3100"
