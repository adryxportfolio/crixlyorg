$ErrorActionPreference = "Stop"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error "Node.js 20+ is required. Install Node.js first: https://nodejs.org"
}

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  Write-Error "npx is required but was not found in PATH."
}

$nodeVersionRaw = node -p "process.versions.node"
$nodeMajor = [int]($nodeVersionRaw.Split(".")[0])
if ($nodeMajor -lt 20) {
  Write-Error "Node.js 20+ is required. Current version: $(node -v)"
}

Write-Host "Installing and starting Crixly..."
Write-Host "This may take a minute on first run."

npx --yes crixlyai onboard --yes

try {
  Start-Process "http://localhost:3100" | Out-Null
} catch {
  # Ignore browser auto-open failures; installer already succeeded.
}

Write-Host ""
Write-Host "Crixly install complete."
Write-Host "Open http://localhost:3100"
