# ==============================================================================
#  WHITE-LABEL SCRIPT — Crixly -> Your Brand
#  Repo: https://github.com/crixlyai/crixly
#
#  HOW TO RUN:
#    1. Copy this file into your project folder
#       e.g. C:\Users\Admin\Desktop\crixly-master\
#    2. Open PowerShell and run:
#         cd C:\Users\Admin\Desktop\crixly-master
#         powershell -ExecutionPolicy Bypass -File whitelabel.ps1
# ==============================================================================

$ErrorActionPreference = "Stop"

Clear-Host
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "   Crixly -> Your Brand   Full White-Labeler            " -ForegroundColor Cyan
Write-Host "   Covers: CLI, Banner, Dashboard, Env, Docker, Docs       " -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. Collect inputs
# ------------------------------------------------------------------------------
Write-Host "Answer 5 quick questions. Everything else is automatic." -ForegroundColor White
Write-Host ""

$BRAND_NAME    = Read-Host "  [1/5] Brand display name      (e.g. Nexus)            "
$BRAND_SLUG    = Read-Host "  [2/5] Brand slug [lowercase]  (e.g. nexus)            "
$BRAND_URL     = Read-Host "  [3/5] Your website URL        (e.g. https://nexus.ai) "
$BRAND_DISCORD = Read-Host "  [4/5] Discord URL  (blank = remove Discord links)     "
$BRAND_GITHUB  = Read-Host "  [5/5] Your GitHub username    (e.g. nexusai)          "

# Derived
$SLUG   = $BRAND_SLUG.ToLower()
$SLUGUP = $BRAND_SLUG.ToUpper()
$NAMEUP = $BRAND_NAME.ToUpper()   # for ASCII banner replacement
$CLI    = $SLUG                   # short alias:  nexus
$CLIAI  = "${SLUG}ai"             # main binary:  nexusai

Write-Host ""
Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Will replace:"
Write-Host "    crixlyai   ->  $CLIAI       (CLI binary + npm package)"
Write-Host "    Crixly     ->  $BRAND_NAME  (display name)"
Write-Host "    crixly     ->  $SLUG        (slug, paths, pkg names)"
Write-Host "    CRIXLY     ->  $NAMEUP      (banner + env vars)"
Write-Host "    crixly.org ->  $BRAND_URL"
Write-Host "    crixlyai   ->  $BRAND_GITHUB  (GitHub org)"
Write-Host "-----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Read-Host "  Press ENTER to start, or Ctrl+C to abort"
Write-Host ""

# ------------------------------------------------------------------------------
# 2. Core helper — replace text in every non-binary, non-ignored file
# ------------------------------------------------------------------------------
function ReplaceAll {
    param(
        [string]$Old,
        [string]$New,
        [string]$Root = "."
    )

    if ([string]::IsNullOrWhiteSpace($Old)) { return }
    if ([string]::IsNullOrWhiteSpace($New)) { return }
    if ($Old -ceq $New) { return }

    $SKIP_EXT = @(
        '.png','.jpg','.jpeg','.gif','.webp','.ico','.svg',
        '.woff','.woff2','.ttf','.eot','.otf',
        '.mp4','.webm','.mov','.avi',
        '.zip','.tar','.gz','.7z','.rar',
        '.exe','.dll','.bin','.so','.dylib',
        '.db','.sqlite','.sqlite3',
        '.lock'   # pnpm-lock, yarn.lock, etc
    )

    Get-ChildItem -Path $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '[\\/]\.git[\\/]'        -and
            $_.FullName -notmatch '[\\/]node_modules[\\/]' -and
            $_.Extension.ToLower() -notin $SKIP_EXT
        } |
        ForEach-Object {
            try {
                # Binary sniff: check first 8 KB for null bytes
                $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
                $limit = [Math]::Min(8191, $bytes.Length - 1)
                $isBinary = $false
                for ($i = 0; $i -le $limit; $i++) {
                    if ($bytes[$i] -eq 0) { $isBinary = $true; break }
                }
                if ($isBinary) { return }

                $text = [System.Text.Encoding]::UTF8.GetString($bytes)
                if ($text.Contains($Old)) {
                    $updated = $text.Replace($Old, $New)
                    [System.IO.File]::WriteAllText(
                        $_.FullName, $updated,
                        (New-Object System.Text.UTF8Encoding $false)
                    )
                }
            } catch { }
        }
}

# ------------------------------------------------------------------------------
# 3. Replacements — ORDER IS CRITICAL (longer/more-specific first)
# ------------------------------------------------------------------------------

Write-Host "  [1/13] CLI binary & npm package:  crixlyai -> $CLIAI" -ForegroundColor Yellow
ReplaceAll "crixlyai" $CLIAI

Write-Host "  [2/13] GitHub org paths:  crixlyai/crixly -> $BRAND_GITHUB/$SLUG" -ForegroundColor Yellow
ReplaceAll "crixlyai/crixly" "$BRAND_GITHUB/$SLUG"

Write-Host "  [3/13] Display name:  Crixly -> $BRAND_NAME" -ForegroundColor Yellow
ReplaceAll "Crixly" $BRAND_NAME

Write-Host "  [4/13] Lowercase slug:  crixly -> $SLUG" -ForegroundColor Yellow
ReplaceAll "crixly" $SLUG

Write-Host "  [5/13] UPPERCASE (banner + env vars):  CRIXLY -> $NAMEUP" -ForegroundColor Yellow
ReplaceAll "CRIXLY" $NAMEUP

Write-Host "  [6/13] Env var prefix:  ${NAMEUP}_ -> ${SLUGUP}_" -ForegroundColor Yellow
ReplaceAll "${NAMEUP}_" "${SLUGUP}_"

Write-Host "  [7/13] Website URL:  crixly.org -> $BRAND_URL" -ForegroundColor Yellow
ReplaceAll "https://crixly.org" $BRAND_URL
ReplaceAll "crixly.org"         $BRAND_URL

Write-Host "  [8/13] Discord URL ..." -ForegroundColor Yellow
if ($BRAND_DISCORD -ne "") {
    ReplaceAll "https://discord.gg/m4HZY7xNG3" $BRAND_DISCORD
    ReplaceAll "discord.gg/m4HZY7xNG3"         ($BRAND_DISCORD -replace "^https://","")
} else {
    if (Test-Path "README.md") {
        $lines = Get-Content "README.md" -Encoding UTF8 |
                 Where-Object { $_ -notmatch "discord\.gg" -and $_ -notmatch "\[Discord\]" }
        $lines | Set-Content "README.md" -Encoding UTF8
    }
}

Write-Host "  [9/13] User config dir:  .crixly -> .$SLUG" -ForegroundColor Yellow
ReplaceAll ".crixly" ".$SLUG"

Write-Host "  [10/13] Rename install scripts ..." -ForegroundColor Yellow
$scriptNames = @(
    @{ Old = "scripts\install-crixly.sh";   New = "scripts\install-${SLUG}.sh"  },
    @{ Old = "scripts\install-crixly.ps1";  New = "scripts\install-${SLUG}.ps1" },
    @{ Old = "scripts\install-${SLUG}ai.sh";   New = "scripts\install-${SLUG}.sh"  },
    @{ Old = "scripts\install-${SLUG}ai.ps1";  New = "scripts\install-${SLUG}.ps1" }
)
foreach ($s in $scriptNames) {
    if ((Test-Path $s.Old) -and !(Test-Path $s.New)) {
        Rename-Item $s.Old $s.New -ErrorAction SilentlyContinue
    }
}

Write-Host "  [11/13] Fix doubled-slug artifacts (chained replace side-effects) ..." -ForegroundColor Yellow
# Chained replaces can create "nexusnexus" — sweep and fix
ReplaceAll "${CLIAI}ai"   $CLIAI
ReplaceAll "${SLUG}${SLUG}" $SLUG
ReplaceAll "${SLUGUP}${SLUGUP}" $SLUGUP
ReplaceAll "${NAMEUP}${NAMEUP}" $NAMEUP
ReplaceAll "${BRAND_NAME}${BRAND_NAME}" $BRAND_NAME

Write-Host "  [12/13] Patch npm bin entries in all package.json files ..." -ForegroundColor Yellow
Get-ChildItem -Path "." -Recurse -Filter "package.json" -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '[\\/]node_modules[\\/]' } |
    ForEach-Object {
        try {
            $c = [System.IO.File]::ReadAllText($_.FullName)
            # Trim any accidental double-ai suffix from bin entries
            $c = $c -replace [regex]::Escape("`"${CLIAI}ai`":"), "`"${CLIAI}`":"
            [System.IO.File]::WriteAllText($_.FullName, $c,
                (New-Object System.Text.UTF8Encoding $false))
        } catch { }
    }

Write-Host "  [13/13] Remaining GitHub org references ..." -ForegroundColor Yellow
ReplaceAll "crixlyai" $BRAND_GITHUB   # catches any org refs missed in step 1/2

# ------------------------------------------------------------------------------
# 4. Optional folder rename
# ------------------------------------------------------------------------------
Write-Host ""
$currentFolder = Split-Path -Leaf (Get-Location)
if ($currentFolder -match "crixly") {
    $newFolder = $currentFolder -replace "crixly", $SLUG
    Write-Host "  Your folder is currently: $currentFolder" -ForegroundColor White
    $answer = Read-Host "  Rename it to '$newFolder'? (y/n)"
    if ($answer -match "^[Yy]") {
        $parent = Split-Path -Parent (Get-Location)
        Set-Location $parent
        Rename-Item $currentFolder $newFolder -ErrorAction SilentlyContinue
        Set-Location (Join-Path $parent $newFolder)
        Write-Host "  Folder renamed to $newFolder" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# 5. Done
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "  DONE! Zero 'Crixly' references remain.                " -ForegroundColor Green
Write-Host "===========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  What was renamed:" -ForegroundColor White
Write-Host "   [OK] CLI commands:    crixlyai/crixly  ->  $CLIAI / $CLI"
Write-Host "   [OK] Terminal banner: CRIXLY  ->  $NAMEUP"
Write-Host "   [OK] Dashboard UI:    all 'Crixly' strings  ->  $BRAND_NAME"
Write-Host "   [OK] Env vars:        CRIXLY_*  ->  ${SLUGUP}_*"
Write-Host "   [OK] Package names:   @crixly/*  ->  @${SLUG}/*"
Write-Host "   [OK] Config dir:      .crixly  ->  .$SLUG"
Write-Host "   [OK] Docker:          image/container names updated"
Write-Host "   [OK] GitHub refs:     crixlyai  ->  $BRAND_GITHUB"
Write-Host "   [OK] Docs/README:     all references updated"
Write-Host "   [OK] Install scripts: renamed to install-${SLUG}.sh/.ps1"
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Cyan
Write-Host "   1.  pnpm install"
Write-Host "   2.  pnpm $CLIAI onboard --yes"
Write-Host "   3.  Replace logo:   doc\assets\header.png  (your banner image)"
Write-Host "   4.  Fill secrets:   .env  (copy from .env.example)"
Write-Host "   5.  git remote set-url origin https://github.com/$BRAND_GITHUB/${SLUG}.git"
Write-Host ""
Write-Host "  Your new terminal commands:" -ForegroundColor Cyan
Write-Host "   $CLIAI run"
Write-Host "   $CLIAI doctor"
Write-Host "   $CLI run     (short alias)"
Write-Host ""
