#!/usr/bin/env bash
# gitgame — unified invariant test runner.
# Each invariant prints "PASS: <name>" on success or "FAIL: <name>: <detail>".
# Exit code non-zero if any FAIL.
set -u
cd "$(git rev-parse --show-toplevel)"

PY="bash $(git rev-parse --show-toplevel)/.claude/scripts/py.sh"

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
if $PY tests/test_dice.py > /tmp/gitgame-dice.log 2>&1; then
    _pass "dice-unit-tests"
else
    _fail "dice-unit-tests" "$(cat /tmp/gitgame-dice.log)"
fi

# ---- 1b. Dice distribution uniformity (10000 samples, χ² approximation) ----
if $PY - <<'PYEOF' > /tmp/gitgame-dist.log 2>&1
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

# ---- 1c. All *.sh scripts in .claude/ and tests/ are executable ----
non_exec=()
while IFS= read -r script; do
    [ -f "$script" ] || continue
    [ -x "$script" ] || non_exec+=("$(basename "$script")")
done < <(find .claude tests -type f -name '*.sh' 2>/dev/null)
if [ ${#non_exec[@]} -eq 0 ]; then
    _pass "shell-scripts-executable"
else
    _fail "shell-scripts-executable" "${non_exec[*]}"
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
if $PY .claude/scripts/dice.py abc123 1 test > /tmp/gitgame-cli.log 2>&1; then
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
if $PY -c "
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

# ---- 11a00. All .md files with frontmatter have STRICTLY valid YAML ----
if $PY - <<'PYEOF' > /tmp/gitgame-yaml.log 2>&1
import sys, os, re
# Lightweight YAML validator without PyYAML dep — uses a subset parser.
# For strictness, try PyYAML first; fall back to basic sanity if unavailable.
try:
    import yaml
    yaml_available = True
except ImportError:
    yaml_available = False

def extract_frontmatter(path):
    with open(path) as f:
        content = f.read()
    m = re.match(r'^(?:<!--[^>]*-->\s*)?---\n(.*?)\n---', content, re.DOTALL)
    if not m:
        return None
    return m.group(1)

bad = []
targets = []
for root, dirs, files in os.walk('.'):
    # Skip external / staged dirs
    if any(s in root for s in ('.git', 'node_modules', 'samples', '/tmp', 'staging')):
        continue
    for fn in files:
        if fn.endswith('.md'):
            targets.append(os.path.join(root, fn))

for p in targets:
    fm = extract_frontmatter(p)
    if fm is None:
        continue
    if yaml_available:
        try:
            d = yaml.safe_load(fm)
            if not isinstance(d, dict):
                bad.append(f"{p}: frontmatter not a mapping")
        except yaml.YAMLError as e:
            bad.append(f"{p}: {e}")
    else:
        # Fallback: ensure every non-empty line starts with space or `key:` or `-`
        for lineno, line in enumerate(fm.split('\n'), 1):
            if not line.strip():
                continue
            if not re.match(r'^(\s+|-\s|[A-Za-z_][\w-]*:)', line):
                bad.append(f"{p}:{lineno}: suspicious line: {line!r}")
                break

if bad:
    print("\n".join(bad[:5]))
    sys.exit(1)
PYEOF
then
    _pass "all-frontmatter-valid-yaml"
else
    _fail "all-frontmatter-valid-yaml" "$(cat /tmp/gitgame-yaml.log | head -3)"
fi

# ---- 11a0. All relative paths mentioned in CLAUDE.md actually exist ----
claude_paths_bad=()
# Extract paths like .claude/... or game/... from CLAUDE.md
while IFS= read -r path; do
    [ -z "$path" ] && continue
    # Trim trailing punctuation
    path="${path%\`}"
    path="${path%.}"
    # Accept both exact paths and patterns with <slug> / <name> placeholders
    if [[ "$path" == *"<"* ]]; then
        # Skip templated paths — they're docs, not literal paths
        continue
    fi
    # Also skip directory references ending in /
    if [[ "$path" == */ ]]; then
        # Check that the directory exists
        dir_to_check="${path%/}"
        [ -d "$dir_to_check" ] || claude_paths_bad+=("$path")
    else
        # Literal file — must exist
        [ -e "$path" ] || claude_paths_bad+=("$path")
    fi
done < <(grep -oE '(\.claude/[A-Za-z0-9/_.-]+|game/[A-Za-z0-9/_.-]+|samples/[A-Za-z0-9/_.-]+)' CLAUDE.md | sort -u)
if [ ${#claude_paths_bad[@]} -eq 0 ]; then
    _pass "rulebook-paths-exist"
else
    _fail "rulebook-paths-exist" "${claude_paths_bad[*]:0:5}"
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

# ---- 11d. location.exits and npc.location reference valid location files ----
xref_bad=()
# Build set of valid location slugs
valid_locs=""
for f in game/World/locations/*.md; do
    [ -f "$f" ] || continue
    valid_locs+="$(basename "$f" .md) "
done

# Check every NPC's location field
for f in game/World/npcs/*.md; do
    [ -f "$f" ] || continue
    loc_ref=$(awk '/^location:/{sub(/^location:[[:space:]]*/,""); gsub(/^"\[\[|\]\]"$/,""); print; exit}' "$f")
    if [ -n "$loc_ref" ]; then
        case " $valid_locs " in
            *" $loc_ref "*) ;;
            *) xref_bad+=("$(basename "$f"):location→$loc_ref") ;;
        esac
    fi
done

# Check every location's exits field — extract each wiki-linked slug
for f in game/World/locations/*.md; do
    [ -f "$f" ] || continue
    # exits can be on one line or multi-line. Just grep for [[...]] inside the exits: line.
    exits_line=$(awk '/^exits:/{print; exit}' "$f")
    [ -z "$exits_line" ] && continue
    while IFS= read -r slug; do
        [ -z "$slug" ] && continue
        case " $valid_locs " in
            *" $slug "*) ;;
            *) xref_bad+=("$(basename "$f"):exits→$slug") ;;
        esac
    done < <(echo "$exits_line" | grep -oE '\[\[[^]]+\]\]' | sed 's/\[\[//; s/\]\]//; s/|.*//')
done

if [ ${#xref_bad[@]} -eq 0 ]; then
    _pass "world-xref-integrity"
else
    _fail "world-xref-integrity" "${xref_bad[*]:0:5}"
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

# ---- 12a2. Character creation simulation (derives attrs from SHA, builds valid card) ----
if bash tests/test_character_creation_sim.sh > /tmp/gitgame-charsim.log 2>&1; then
    _pass "character-creation-simulation"
else
    _fail "character-creation-simulation" "$(cat /tmp/gitgame-charsim.log | head -3)"
fi

# ---- 12b. Permadeath end-to-end simulation (move + tag + README + epitaph) ----
if bash tests/test_permadeath_sim.sh > /tmp/gitgame-perma.log 2>&1; then
    _pass "permadeath-simulation"
else
    _fail "permadeath-simulation" "$(cat /tmp/gitgame-perma.log | head -3)"
fi

# ---- 12c. Loot generator runs deterministically + output is valid structure ----
if $PY - <<'PYEOF' > /tmp/gitgame-loot-structure.log 2>&1
import subprocess, re, sys
PY = sys.executable
def _run(*args):
    return subprocess.check_output([PY, *args]).decode().replace('\r\n', '\n')
out_a = _run('.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'rare')
out_b = _run('.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'rare')
assert out_a == out_b, 'not deterministic'
out_c = _run('.claude/scripts/generate-loot.py', 'abc123', '5', '1', 'legendary')
assert 'legendary' in out_c

# Structure validation across all rarities
for rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary'):
    out = _run('.claude/scripts/generate-loot.py', 'deadbeef', '7', '3', rarity)
    # Must have YAML frontmatter (may be preceded by slug comment)
    assert re.search(r'^---\n.*?\n---\n', out, re.DOTALL | re.MULTILINE), f'{rarity}: no YAML block'
    # Must include required YAML fields
    for f in ('slot:', 'rarity:', 'seed:', 'generated_on:', 'tags:'):
        assert f in out, f'{rarity}: missing YAML field {f}'
    # Must have a code block for the 8-line Loot text
    assert '```' in out, f'{rarity}: no code block'
    # Must include rarity string
    assert f'rarity: {rarity}' in out, f'{rarity}: wrong rarity'
    # Slug comment should be first line
    assert out.startswith('<!-- slug: '), f'{rarity}: no slug comment'
PYEOF
then
    _pass "loot-generator-output-valid"
else
    _fail "loot-generator-output-valid" "$(cat /tmp/gitgame-loot-structure.log | head -2)"
fi

# ---- 12. Graveyard is empty or only has .gitkeep (no alive characters should be there) ----
grave_bad=$(find game/Graveyard -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' 2>/dev/null | xargs -I{} grep -L '^tags:.*dead' {} 2>/dev/null)
if [ -z "$grave_bad" ]; then
    _pass "graveyard-only-dead-tags"
else
    _fail "graveyard-only-dead-tags" "$grave_bad"
fi

# ---- 13. Recent commits follow conventional format ----
# Allowed prefixes: feat/fix/test/docs/chore/refactor/experiment/character/death/rest/turn/
#                   skirmish/expedition/saga/build/style/perf/ci/revert  (with optional scope)
# Or Merge commits, or "turn N:" / "saga chapter N:" / "Initial commit" patterns.
_allowed_prefix='^(feat|fix|test|docs|chore|refactor|experiment|character|death|rest|turn|skirmish|expedition|saga|build|style|perf|ci|revert|P-?[0-9])(\([^)]+\))?:[[:space:]]'
_allowed_freeform='^(Merge|Initial commit)|^(turn|skirmish|expedition|saga)[[:space:]][0-9]*'

bad_commits=""
bad_commits=$(git log -20 --format='%s' | grep -vE "$_allowed_prefix" 2>/dev/null | grep -vE "$_allowed_freeform" 2>/dev/null | head -3 2>/dev/null) || bad_commits=""

if [ -z "$bad_commits" ]; then
    _pass "commit-message-conventions"
else
    _fail "commit-message-conventions" "$(echo "$bad_commits" | tr '\n' '|' )"
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
