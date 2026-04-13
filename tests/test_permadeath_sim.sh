#!/usr/bin/env bash
# gitgame — simulated permadeath flow test.
# Creates a dummy character, simulates death (file move + tag), verifies all invariants.
# Cleans up after itself so the real game state stays pristine.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

# Use a clearly fake slug so we can detect + clean up
SLUG="testchar-perma-$(date +%s)"
TODAY=$(date +%Y-%m-%d)
GRAVE="game/Graveyard/${SLUG}-died-${TODAY}.md"
ALIVE="game/Characters/${SLUG}.md"
TAG="death/${SLUG}"

cleanup() {
    set +e
    rm -f "$ALIVE" "$GRAVE"
    git tag -d "$TAG" > /dev/null 2>&1
    # Reset README.md to whatever it was
    git checkout README.md > /dev/null 2>&1 || true
    bash .claude/scripts/readme-update.sh > /dev/null 2>&1 || true
}
trap cleanup EXIT

# Step 1: Create dummy alive character
cat > "$ALIVE" <<EOF
---
name: TestChar Permadeath
slug: ${SLUG}
class: Test Subject
level: 1
xp: 0
xp_to_next: 100
hp: 0
hp_max: 10
status: [bruised]
attributes:
  body: 1
  mind: 1
  edge: 1
  luck: 1
inventory: []
gold: 0
expeditions_survived: 0
created: ${TODAY}
last_played: ${TODAY}
tags: [character, alive]
---

# TestChar Permadeath

A test subject. Will die in a moment.
EOF

# Step 2: Verify it's alive (in Characters/, has alive tag)
if [ ! -f "$ALIVE" ]; then
    echo "FAIL: dummy character file not created"
    exit 1
fi

# Step 3: Simulate the death — what /graveyard would do
# 3a. Move file
mv "$ALIVE" "$GRAVE"

# 3b. Edit YAML — change tags + add death fields
python3 - "$GRAVE" <<'PYEOF'
import re, sys
p = sys.argv[1]
with open(p) as f:
    t = f.read()
t = re.sub(r'tags:\s*\[character,\s*alive\]', 'tags: [character, dead]', t)
# Add death fields after `tags:` line
t = re.sub(
    r'(tags: \[character, dead\])',
    r'\1\ndied_on: 2026-04-13\ndied_in: "[[ember-pass]]"\nkilled_by: test-trap\nturns_survived: 3\nfinal_hp: -2',
    t
)
# Append epitaph
t += "\n\n## 墓志铭\n\n他在第三回合摔进了一个本不该存在的坑。无人记得他原本要去哪里。\n"
with open(p, 'w') as f:
    f.write(t)
PYEOF

# 3c. Update README
bash .claude/scripts/readme-update.sh > /dev/null

# 3d. Tag the grave
git tag -a "$TAG" -m "他在第三回合摔进了一个本不该存在的坑。" 2>/dev/null || {
    echo "FAIL: could not create death tag"
    exit 1
}

# Step 4: Invariant checks
EXIT=0

# 4a. Character file no longer in Characters/
if [ -f "$ALIVE" ]; then
    echo "FAIL: dummy still in Characters/"
    EXIT=1
fi

# 4b. Character file present in Graveyard/
if [ ! -f "$GRAVE" ]; then
    echo "FAIL: dummy not in Graveyard/"
    EXIT=1
fi

# 4c. Tag exists
if ! git tag -l "$TAG" | grep -q "^${TAG}$"; then
    echo "FAIL: death tag missing"
    EXIT=1
fi

# 4d. YAML now has `tags: [character, dead]`
if ! grep -q '^tags:.*dead' "$GRAVE"; then
    echo "FAIL: tags not updated to dead"
    EXIT=1
fi

# 4e. Required death fields present
for field in died_on died_in killed_by turns_survived final_hp; do
    if ! grep -q "^${field}:" "$GRAVE"; then
        echo "FAIL: missing field $field"
        EXIT=1
    fi
done

# 4f. Epitaph section present
if ! grep -q '^## 墓志铭' "$GRAVE"; then
    echo "FAIL: missing epitaph section"
    EXIT=1
fi

# 4g. README updated — slug should appear in fallen list
if ! grep -q "${SLUG}-died-${TODAY}" README.md; then
    echo "FAIL: slug not in README fallen list"
    EXIT=1
fi

if [ "$EXIT" -eq 0 ]; then
    echo "OK — permadeath simulation passes all 7 invariants"
fi
exit $EXIT
