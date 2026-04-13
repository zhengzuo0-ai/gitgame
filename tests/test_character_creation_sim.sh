#!/usr/bin/env bash
# gitgame — simulated character creation test.
# Derives attributes from a fake SHA, builds a character card, verifies it
# matches the schema CLAUDE.md demands.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

FAKE_SHA="deadbeef1234567890abcdef1234567890abcdef"
SLUG="testchar-rolled-$(date +%s)"
TODAY=$(date +%Y-%m-%d)
CARD="game/Characters/${SLUG}.md"

cleanup() {
    set +e
    rm -f "$CARD"
}
trap cleanup EXIT

# 1. Derive attributes via dice.py from fake SHA
BODY=$(python .claude/scripts/dice.py "$FAKE_SHA" 1 attr-body)
MIND=$(python .claude/scripts/dice.py "$FAKE_SHA" 1 attr-mind)
EDGE=$(python .claude/scripts/dice.py "$FAKE_SHA" 1 attr-edge)
LUCK=$(python .claude/scripts/dice.py "$FAKE_SHA" 1 attr-luck)

# Map 1..20 to 1..5 per CLAUDE.md rule
BODY_MAPPED=$(( (BODY - 1) % 5 + 1 ))
MIND_MAPPED=$(( (MIND - 1) % 5 + 1 ))
EDGE_MAPPED=$(( (EDGE - 1) % 5 + 1 ))
LUCK_MAPPED=$(( (LUCK - 1) % 5 + 1 ))

HP_MAX=$((10 + BODY_MAPPED))

# 2. Write character card matching the schema
cat > "$CARD" <<EOF
---
name: Test Character Rolled
slug: ${SLUG}
class: Wandering Scholar
level: 1
xp: 0
xp_to_next: 300
hp: ${HP_MAX}
hp_max: ${HP_MAX}
status: []
attributes:
  body: ${BODY_MAPPED}
  mind: ${MIND_MAPPED}
  edge: ${EDGE_MAPPED}
  luck: ${LUCK_MAPPED}
inventory: []
gold: 0
expeditions_survived: 0
created: ${TODAY}
last_played: ${TODAY}
tags: [character, alive]
---

# Test Character Rolled

南境某处来的游学者。没人记得他是谁的学生。背包里有一封没拆的信。
EOF

# 3. Verify invariants
EXIT=0

# 3a. Card is in the right place
if [ ! -f "$CARD" ]; then
    echo "FAIL: card not created"; EXIT=1
fi

# 3b. Required YAML fields present
for field in name slug class level hp hp_max attributes inventory gold expeditions_survived created last_played tags; do
    if ! grep -q "^${field}:" "$CARD"; then
        echo "FAIL: missing field: $field"; EXIT=1
    fi
done

# 3c. Attributes all in range 1..5
for attr in body mind edge luck; do
    val=$(awk "/^  ${attr}:/{sub(/.*${attr}:[[:space:]]*/,\"\"); print; exit}" "$CARD")
    if [ -z "$val" ] || [ "$val" -lt 1 ] || [ "$val" -gt 5 ]; then
        echo "FAIL: attribute ${attr} out of 1..5 range: $val"; EXIT=1
    fi
done

# 3d. HP == hp_max (freshly rolled = full health)
hp=$(awk '/^hp:/{sub(/^hp:[[:space:]]*/,""); print; exit}' "$CARD")
hp_max=$(awk '/^hp_max:/{sub(/^hp_max:[[:space:]]*/,""); print; exit}' "$CARD")
if [ "$hp" != "$hp_max" ]; then
    echo "FAIL: rolled character has hp ($hp) != hp_max ($hp_max)"; EXIT=1
fi

# 3e. Tags include character + alive
if ! grep -q 'tags:.*character.*alive' "$CARD"; then
    echo "FAIL: tags must include [character, alive]"; EXIT=1
fi

# 3f. Determinism: same SHA produces same attributes
BODY2=$(python .claude/scripts/dice.py "$FAKE_SHA" 1 attr-body)
if [ "$BODY" != "$BODY2" ]; then
    echo "FAIL: dice non-deterministic ($BODY vs $BODY2)"; EXIT=1
fi

if [ "$EXIT" -eq 0 ]; then
    echo "OK — character creation simulation passes all 6 invariants"
fi
exit $EXIT
