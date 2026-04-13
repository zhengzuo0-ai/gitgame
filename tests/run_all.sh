#!/usr/bin/env bash
# gitgame — unified invariant test runner.
# Each invariant prints "PASS: <name>" on success or "FAIL: <name>: <detail>".
# Exit code non-zero if any FAIL.
set -u
cd "$(git rev-parse --show-toplevel)"

PASS=0
FAIL=0
FAILURES=()

_pass() {
    echo "PASS: $1"
    PASS=$((PASS + 1))
}
_fail() {
    echo "FAIL: $1: ${2:-}"
    FAIL=$((FAIL + 1))
    FAILURES+=("$1")
}

# ---- 1. Dice unit tests ----
if python tests/test_dice.py > /tmp/gitgame-dice.log 2>&1; then
    _pass "dice-unit-tests"
else
    _fail "dice-unit-tests" "$(cat /tmp/gitgame-dice.log)"
fi

# ---- 1b. Dice distribution uniformity (10000 samples, χ² approximation) ----
if python3 - <<'PYEOF' > /tmp/gitgame-dist.log 2>&1
import sys, os
sys.path.insert(0, '.claude/scripts')
from dice import roll
N = 10000
counts = [0] * 21  # index 1..20
for i in range(N):
    r = roll("uniformity-test", i, "dist", sides=20)
    counts[r] += 1
# Expect ~500 per face. Max deviation check: each face within ±20% of expected.
expected = N / 20  # 500
maxdev = max(abs(c - expected) / expected for c in counts[1:])
if maxdev > 0.20:
    raise SystemExit(f"max deviation {maxdev:.2%} exceeds 20% tolerance; counts={counts[1:]}")
# Also check all 20 faces showed up
missing = [i for i in range(1, 21) if counts[i] == 0]
if missing:
    raise SystemExit(f"faces never rolled: {missing}")
PYEOF
then
    _pass "dice-distribution-uniform"
else
    _fail "dice-distribution-uniform" "$(cat /tmp/gitgame-dist.log | head -2)"
fi

# ---- 2. README update smoke ----
if bash tests/test_readme_update.sh > /tmp/gitgame-readme.log 2>&1; then
    _pass "readme-update-script"
else
    _fail "readme-update-script" "$(cat /tmp/gitgame-readme.log)"
fi

# ---- 3. CLAUDE.md exists and is non-trivial ----
if [ -f CLAUDE.md ] && [ "$(wc -l < CLAUDE.md)" -gt 50 ]; then
    _pass "claude-md-exists-and-substantial"
else
    _fail "claude-md-exists-and-substantial" "missing or <50 lines"
fi

# ---- 4. All 7 slash commands exist ----
cmd_missing=()
for c in roll-character skirmish expedition saga rest inventory graveyard; do
    [ -f ".claude/commands/${c}.md" ] || cmd_missing+=("$c")
done
if [ ${#cmd_missing[@]} -eq 0 ]; then
    _pass "slash-commands-all-present"
else
    _fail "slash-commands-all-present" "missing: ${cmd_missing[*]}"
fi

# ---- 5. Each slash command has proper frontmatter ----
cmd_bad=()
for f in .claude/commands/*.md; do
    head -1 "$f" | grep -q '^---$' || cmd_bad+=("$(basename "$f")")
done
if [ ${#cmd_bad[@]} -eq 0 ]; then
    _pass "slash-commands-have-frontmatter"
else
    _fail "slash-commands-have-frontmatter" "no frontmatter: ${cmd_bad[*]}"
fi

# ---- 6. dice.py runs with CLI forms ----
if python .claude/scripts/dice.py abc123 1 test > /tmp/gitgame-cli.log 2>&1; then
    OUT=$(cat /tmp/gitgame-cli.log)
    if [[ "$OUT" =~ ^[0-9]+$ ]] && [ "$OUT" -ge 1 ] && [ "$OUT" -le 20 ]; then
        _pass "dice-cli-4arg-form"
    else
        _fail "dice-cli-4arg-form" "bad output: $OUT"
    fi
else
    _fail "dice-cli-4arg-form" "crash"
fi

# ---- 7. Session-start hook runs without error ----
if bash .claude/hooks/session-start.sh > /tmp/gitgame-hook.log 2>&1; then
    if grep -q 'gitgame' /tmp/gitgame-hook.log; then
        _pass "session-start-hook-runs"
    else
        _fail "session-start-hook-runs" "no 'gitgame' in output"
    fi
else
    _fail "session-start-hook-runs" "nonzero exit"
fi

# ---- 8. All world/location files have required YAML fields ----
loc_bad=()
for f in game/World/locations/*.md; do
    [ -f "$f" ] || continue
    for field in slug type danger; do
        grep -q "^${field}:" "$f" || loc_bad+=("$(basename "$f"):$field")
    done
done
if [ ${#loc_bad[@]} -eq 0 ]; then
    _pass "location-yaml-required-fields"
else
    _fail "location-yaml-required-fields" "${loc_bad[*]}"
fi

# ---- 9. All NPC files have required YAML fields ----
npc_bad=()
for f in game/World/npcs/*.md; do
    [ -f "$f" ] || continue
    for field in slug type disposition; do
        grep -q "^${field}:" "$f" || npc_bad+=("$(basename "$f"):$field")
    done
done
if [ ${#npc_bad[@]} -eq 0 ]; then
    _pass "npc-yaml-required-fields"
else
    _fail "npc-yaml-required-fields" "${npc_bad[*]}"
fi

# ---- 10. loot-seeds.json is valid JSON with required keys ----
if python3 -c "
import json, sys
d = json.load(open('.claude/scripts/loot-seeds.json'))
for k in ('slots', 'prefixes', 'suffixes', 'attribute_lines'):
    if k not in d:
        sys.exit(f'missing key: {k}')
    if len(d[k]) == 0:
        sys.exit(f'empty: {k}')
assert len(d['slots']) == 8, 'need 8 slots'
assert len(d['prefixes']) >= 10, 'need >= 10 prefixes'
assert len(d['suffixes']) >= 10, 'need >= 10 suffixes'
assert len(d['attribute_lines']) >= 10, 'need >= 10 attrs'
" 2>/tmp/gitgame-loot.log; then
    _pass "loot-seeds-json-schema"
else
    _fail "loot-seeds-json-schema" "$(cat /tmp/gitgame-loot.log)"
fi

# ---- 11. README has the 4 required anchors ----
anchors_missing=()
for a in '<!-- ALIVE -->' '<!-- /ALIVE -->' '<!-- FALLEN -->' '<!-- /FALLEN -->'; do
    grep -qF "$a" README.md || anchors_missing+=("$a")
done
if [ ${#anchors_missing[@]} -eq 0 ]; then
    _pass "readme-anchors-all-present"
else
    _fail "readme-anchors-all-present" "${anchors_missing[*]}"
fi

# ---- 11a. CLAUDE.md references all 7 slash commands (docs-impl drift) ----
cmd_missing_in_rulebook=()
for c in roll-character skirmish expedition saga rest inventory graveyard; do
    grep -qE "/${c}\b" CLAUDE.md || cmd_missing_in_rulebook+=("$c")
done
if [ ${#cmd_missing_in_rulebook[@]} -eq 0 ]; then
    _pass "rulebook-mentions-all-commands"
else
    _fail "rulebook-mentions-all-commands" "missing: ${cmd_missing_in_rulebook[*]}"
fi

# ---- 11b. No TODO/FIXME/placeholder in CLAUDE.md, commands, game/World ----
placeholder_hits=()
for f in CLAUDE.md .claude/commands/*.md game/World/locations/*.md game/World/npcs/*.md; do
    [ -f "$f" ] || continue
    # Match common placeholder markers. Allow "TODO:" inside code comments if needed — but we flag all for now.
    if grep -nE '\b(TODO|FIXME|XXX|占位|待办|TBD)\b' "$f" > /dev/null 2>&1; then
        placeholder_hits+=("$(basename "$f")")
    fi
done
if [ ${#placeholder_hits[@]} -eq 0 ]; then
    _pass "no-placeholder-markers"
else
    _fail "no-placeholder-markers" "${placeholder_hits[*]}"
fi

# ---- 11c. samples/ is clean (no uncommitted drift in the read-only reference dir) ----
drift=$(git status --porcelain samples/ 2>/dev/null | head -5)
if [ -z "$drift" ]; then
    _pass "samples-dir-no-drift"
else
    _fail "samples-dir-no-drift" "$drift"
fi

# ---- 12a. Wiki link integrity in game/World/ ----
broken_links=()
for f in game/World/locations/*.md game/World/npcs/*.md; do
    [ -f "$f" ] || continue
    # Extract all [[slug]] references — strip aliases after |
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        slug=$(echo "$link" | sed 's/|.*//; s/\.md$//')
        # Search for a file with this slug (as filename base) in known locations
        found=0
        for base in game/World/locations game/World/npcs game/Characters game/Graveyard game/Loot; do
            [ -f "${base}/${slug}.md" ] && found=1 && break
        done
        # Also allow matches against samples/ loot files (legacy refs)
        if [ "$found" -eq 0 ]; then
            find samples -name "${slug}.md" 2>/dev/null | grep -q . && found=1
        fi
        [ "$found" -eq 0 ] && broken_links+=("$(basename "$f")→[[${slug}]]")
    done < <(grep -oE '\[\[[^]]+\]\]' "$f" | sed 's/\[\[//; s/\]\]//')
done
if [ ${#broken_links[@]} -eq 0 ]; then
    _pass "world-wiki-link-integrity"
else
    _fail "world-wiki-link-integrity" "${broken_links[*]:0:5}..."
fi

# ---- 12b. Permadeath end-to-end simulation (move + tag + README + epitaph) ----
if bash tests/test_permadeath_sim.sh > /tmp/gitgame-perma.log 2>&1; then
    _pass "permadeath-simulation"
else
    _fail "permadeath-simulation" "$(cat /tmp/gitgame-perma.log | head -3)"
fi

# ---- 12c. Loot generator runs deterministically ----
if python3 - <<'PYEOF' > /dev/null 2>&1
import subprocess
out_a = subprocess.check_output(['python', '.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'rare'])
out_b = subprocess.check_output(['python', '.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'rare'])
assert out_a == out_b, 'not deterministic'
out_c = subprocess.check_output(['python', '.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'legendary'])
assert b'legendary' in out_c
PYEOF
then
    _pass "loot-generator-deterministic"
else
    _fail "loot-generator-deterministic" "see test"
fi

# ---- 12. Graveyard is empty or only has .gitkeep (no alive characters should be there) ----
grave_bad=$(find game/Graveyard -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' 2>/dev/null | xargs -I{} grep -L '^tags:.*dead' {} 2>/dev/null)
if [ -z "$grave_bad" ]; then
    _pass "graveyard-only-dead-tags"
else
    _fail "graveyard-only-dead-tags" "$grave_bad"
fi

# ---- summary ----
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PASS: $PASS   FAIL: $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0
