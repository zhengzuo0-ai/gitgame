#!/usr/bin/env bash
# Smoke test: readme-update.sh preserves markers and writes placeholder when no characters exist.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Guard: require anchors to exist in README.md
grep -q "<!-- ALIVE -->" README.md || { echo "FAIL: no <!-- ALIVE --> anchor in README.md"; exit 1; }
grep -q "<!-- /ALIVE -->" README.md || { echo "FAIL: no <!-- /ALIVE --> anchor"; exit 1; }
grep -q "<!-- FALLEN -->" README.md || { echo "FAIL: no <!-- FALLEN --> anchor"; exit 1; }
grep -q "<!-- /FALLEN -->" README.md || { echo "FAIL: no <!-- /FALLEN --> anchor"; exit 1; }

# Backup
cp README.md /tmp/gitgame-readme.bak
trap 'mv /tmp/gitgame-readme.bak README.md' EXIT

# Run update
bash .claude/scripts/readme-update.sh > /dev/null

# Anchors must survive
grep -q "<!-- ALIVE -->" README.md
grep -q "<!-- /ALIVE -->" README.md
grep -q "<!-- FALLEN -->" README.md
grep -q "<!-- /FALLEN -->" README.md

# With no alive characters, should show placeholder
if ! grep -q "无人在世" README.md; then
    echo "FAIL: expected '无人在世' placeholder in ALIVE block"
    exit 1
fi

echo "OK — readme-update.sh preserves markers and writes placeholders"
