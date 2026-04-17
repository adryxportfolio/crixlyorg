#!/usr/bin/env bash
# =============================================================================
#  Crixly White-Label Script
#  Run this from INSIDE the cloned crixlyorg folder:
#
#    cd ~/Desktop/crixlyorg
#    bash whitelabel.sh
# =============================================================================

set -e

# ── 1. Collect brand info ─────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║        Crixly → Your Brand  White-Labeler        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

read -p "  Your brand name  (e.g. Acme):        " BRAND_NAME
read -p "  Your brand slug  (e.g. acme, no spaces, lowercase): " BRAND_SLUG
read -p "  Your CLI command (e.g. acme):         " BRAND_CLI
read -p "  Your website URL (e.g. https://acme.com): " BRAND_URL
read -p "  Your Discord URL (leave blank to remove): " BRAND_DISCORD

echo ""
echo "──────────────────────────────────────────────────"
echo "  Replacing:"
echo "    'Crixly'    → '$BRAND_NAME'"
echo "    'crixly'    → '$BRAND_SLUG'"
echo "    'crixlyai'  → '${BRAND_CLI}ai'  (or your CLI name)"
echo "    'crixly.org'→ '$BRAND_URL'"
echo "──────────────────────────────────────────────────"
read -p "  Looks good? Press ENTER to continue, Ctrl+C to abort."
echo ""

# ── 2. Helpers ────────────────────────────────────────────────────────────────

# Cross-platform sed in-place (macOS needs '' after -i, Linux doesn't)
sedi() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# Replace text in all non-binary files under a directory
replace_in_files() {
  local OLD="$1"
  local NEW="$2"
  local DIR="${3:-.}"

  grep -rl --include="*" "$OLD" "$DIR" 2>/dev/null \
    | grep -v ".git/" \
    | grep -v "node_modules/" \
    | grep -v "pnpm-lock.yaml" \
    | while IFS= read -r file; do
        # skip binary files
        if file "$file" | grep -qE 'text|JSON|script|empty'; then
          sedi "s|${OLD}|${NEW}|g" "$file"
        fi
      done
}

echo "  [1/9] Replacing display name  'Crixly' → '$BRAND_NAME' ..."
replace_in_files "Crixly" "$BRAND_NAME"

echo "  [2/9] Replacing lowercase slug 'crixly' → '$BRAND_SLUG' ..."
replace_in_files "crixly" "$BRAND_SLUG"

echo "  [3/9] Replacing CLI binary 'crixlyai' → '${BRAND_CLI}ai' ..."
replace_in_files "crixlyai" "${BRAND_CLI}ai"

# Some files also reference just "crixly" as the short alias — already done above
# But double-check the bin entries in package.json files
echo "  [4/9] Patching npm bin entries ..."
find . -name "package.json" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  | while IFS= read -r pj; do
      sedi "s|\"${BRAND_SLUG}ai\": \"|\"${BRAND_CLI}ai\": \"|g" "$pj"
      sedi "s|\"${BRAND_SLUG}\": \"|\"${BRAND_CLI}\": \"|g" "$pj"
    done

echo "  [5/9] Replacing website URL 'crixly.org' → '$BRAND_URL' ..."
replace_in_files "https://crixly.org" "$BRAND_URL"
replace_in_files "crixly.org" "$BRAND_URL"

echo "  [6/9] Replacing Discord URL ..."
if [ -n "$BRAND_DISCORD" ]; then
  replace_in_files "https://discord.gg/m4HZY7xNG3" "$BRAND_DISCORD"
else
  # Remove discord badge lines from README
  sedi "/discord\.gg\/m4HZY7xNG3/d" README.md 2>/dev/null || true
  sedi "/Discord/d" README.md 2>/dev/null || true
fi

echo "  [7/9] Renaming install scripts ..."
# Rename the shell install scripts
if [ -f "scripts/install-crixly.sh" ]; then
  mv "scripts/install-crixly.sh" "scripts/install-${BRAND_SLUG}.sh"
fi
if [ -f "scripts/install-crixly.ps1" ]; then
  mv "scripts/install-crixly.ps1" "scripts/install-${BRAND_SLUG}.ps1"
fi

# Fix references to those script filenames inside README and other docs
replace_in_files "install-${BRAND_SLUG}ai.sh" "install-${BRAND_SLUG}.sh"
replace_in_files "install-${BRAND_SLUG}ai.ps1" "install-${BRAND_SLUG}.ps1"

echo "  [8/9] Patching Docker image / container names ..."
for f in Dockerfile Dockerfile.* docker-compose*.yml docker/*.yml docker/*.yaml; do
  [ -f "$f" ] || continue
  # image names and labels already covered by slug replace above
  # just ensure BRAND_SLUG appears correctly
  sedi "s|image: ${BRAND_SLUG}org|image: ${BRAND_SLUG}|g" "$f" 2>/dev/null || true
done

echo "  [9/9] Replacing GitHub repo references ..."
replace_in_files "adryxportfolio/crixlyorg" "${BRAND_SLUG}org"
replace_in_files "adryxportfolio" "${BRAND_SLUG}"

# ── 3. Rename the repo folder itself (optional) ───────────────────────────────

echo ""
CURRENT_DIR=$(basename "$PWD")
if [ "$CURRENT_DIR" = "crixlyorg" ]; then
  echo "  ✔ Your current folder is named 'crixlyorg'."
  read -p "  Rename it to '${BRAND_SLUG}org'? (y/n): " RENAME_FOLDER
  if [[ "$RENAME_FOLDER" =~ ^[Yy]$ ]]; then
    cd ..
    mv "crixlyorg" "${BRAND_SLUG}org"
    echo "  Folder renamed → ${BRAND_SLUG}org"
    cd "${BRAND_SLUG}org"
  fi
fi

# ── 4. Done ───────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  ✅  White-labeling complete!                    ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "  Next steps:"
echo "  1. Run:  pnpm install"
echo "  2. Run:  pnpm ${BRAND_CLI}ai onboard --yes"
echo "  3. Swap in your own logo assets in:  doc/assets/"
echo "  4. Update .env with your secrets"
echo "  5. Optionally:  git remote set-url origin <your-new-repo-url>"
echo ""
echo "  Your CLI commands are now:"
echo "    ${BRAND_CLI}ai run"
echo "    ${BRAND_CLI}ai doctor"
echo "    ${BRAND_CLI} run     (short alias)"
echo ""
