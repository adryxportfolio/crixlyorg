$ErrorActionPreference = "Stop"

function Write-Section([string]$message) {
  Write-Host ""
  Write-Host "==> $message" -ForegroundColor Cyan
}

function Assert-Command([string]$name, [string]$installHint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "$name is required. $installHint"
  }
}

function Ensure-Node {
  if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersionRaw = node -p "process.versions.node"
    $nodeMajor = [int]($nodeVersionRaw.Split(".")[0])
    if ($nodeMajor -ge 20) {
      return
    }
  }

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Node.js 20+ not found. Installing via winget..."
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent | Out-Null
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  }

  if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw "Node.js 20+ is required. Install from https://nodejs.org and rerun installer."
  }

  $nodeVersionRaw = node -p "process.versions.node"
  $nodeMajor = [int]($nodeVersionRaw.Split(".")[0])
  if ($nodeMajor -lt 20) {
    throw "Node.js 20+ is required. Current version: $(node -v)"
  }
}

function Ensure-Pnpm {
  if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    return
  }
  if (-not (Get-Command corepack -ErrorAction SilentlyContinue)) {
    throw "pnpm is required and corepack is unavailable. Reinstall Node.js LTS."
  }
  corepack enable | Out-Null
  corepack prepare pnpm@9.15.4 --activate | Out-Null
}

function Wait-Health([int]$basePort = 3100, [int]$timeoutSeconds = 180, [int]$maxPortOffset = 100) {
  $started = Get-Date
  while (((Get-Date) - $started).TotalSeconds -lt $timeoutSeconds) {
    foreach ($offset in 0..$maxPortOffset) {
      $port = $basePort + $offset
      $url = "http://localhost:$port/api/health"
      try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
          return $port
        }
      } catch {
      }
    }
    Start-Sleep -Seconds 2
  }
  return $null
}

Write-Section "Checking dependencies"
Ensure-Node
Assert-Command "git" "Install git from https://git-scm.com/download/win"
Ensure-Pnpm

$repoUrl = if ($env:CRIXLY_REPO_URL) { $env:CRIXLY_REPO_URL } else { "https://github.com/adryxportfolio/crixlyorg.git" }
$installDir = if ($env:CRIXLY_INSTALL_DIR) { $env:CRIXLY_INSTALL_DIR } else { Join-Path $HOME "crixlyorg" }
$basePort = if ($env:PORT) { [int]$env:PORT } else { 3100 }
$crixlyHome = if ($env:CRIXLY_HOME) { $env:CRIXLY_HOME } else { Join-Path $installDir ".crixly" }

Write-Section "Preparing install directory"
Write-Host "Repository: $repoUrl"
Write-Host "Install directory: $installDir"
if (Test-Path (Join-Path $installDir ".git")) {
  git -C $installDir pull --ff-only
} else {
  git clone $repoUrl $installDir
}

Set-Location $installDir
$env:CRIXLY_HOME = $crixlyHome
New-Item -ItemType Directory -Path $crixlyHome -Force | Out-Null

Write-Section "Installing dependencies"
pnpm install

Write-Section "Applying runtime defaults"
pnpm setup:env

Write-Section "Building CRIXLY"
pnpm build

Write-Section "Installing global command shims"
$shimDir = Join-Path $HOME ".crixly\bin"
New-Item -ItemType Directory -Path $shimDir -Force | Out-Null

function Write-ShimFiles([string]$baseName) {
  $cmdShimPath = Join-Path $shimDir "$baseName.cmd"
  $psShimPath = Join-Path $shimDir "$baseName.ps1"
  $cmdShim = @"
@echo off
pnpm --dir "$installDir" crixlyai %*
exit /b %ERRORLEVEL%
"@
  Set-Content -Path $cmdShimPath -Value $cmdShim -Encoding ASCII
  $psShim = @"
`$ErrorActionPreference = "Stop"
pnpm --dir "$installDir" crixlyai @args
exit `$LASTEXITCODE
"@
  Set-Content -Path $psShimPath -Value $psShim -Encoding ASCII
}

Write-ShimFiles "crixlyai"
Write-ShimFiles "crixly"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @()
if ($userPath) {
  $pathEntries = $userPath.Split(";") | Where-Object { $_ -ne "" }
}
$pathEntries = @($pathEntries | Where-Object { $_ -ne $shimDir })
$newUserPath = (@($shimDir) + $pathEntries) -join ";"
[Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
if (-not (($env:Path -split ";") -contains $shimDir)) {
  $env:Path = "$shimDir;$env:Path"
}

Write-Section "Starting CRIXLY"
$pnpmCommandSource = (Get-Command pnpm -ErrorAction Stop).Source
$pnpmCmdPath = [System.IO.Path]::ChangeExtension($pnpmCommandSource, ".cmd")
if (-not (Test-Path $pnpmCmdPath)) {
  $pnpmCmdPath = "pnpm"
}
$startCmd = 'set "CRIXLY_HOME={0}" && cd /d "{1}" && "{2}" start' -f $crixlyHome, $installDir, $pnpmCmdPath
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $startCmd -WindowStyle Minimized | Out-Null

$runningPort = Wait-Health -basePort $basePort -timeoutSeconds 180 -maxPortOffset 100
if ($null -eq $runningPort) {
  throw "CRIXLY started command was launched, but health check failed for ports $basePort-$($basePort+100)"
}

try {
  Start-Process "http://localhost:$runningPort" | Out-Null
} catch {
}

Write-Host ""
Write-Host "CRIXLY is running at http://localhost:$runningPort" -ForegroundColor Green
Write-Host "Global commands installed: crixlyai, crixly"
Write-Host "If this terminal cannot find commands yet, open a new terminal window."
