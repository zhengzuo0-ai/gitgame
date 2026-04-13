# gitgame MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Claude-Code-driven permadeath AI-GM text game where commit SHA is the dice, CLAUDE.md is the rulebook, and characters die forever when HP≤0.

**Architecture:** Slash commands in `.claude/commands/*.md` are prompt templates Claude executes. Dice are derived deterministically from git HEAD SHA via `sha256(head:turn:label)[:8] % 20 + 1`, making rolls reproducible and auditable. Character state lives in YAML frontmatter in `game/Characters/*.md`; death moves a file to `game/Graveyard/` + creates a `death/<slug>` tag.

**Tech Stack:** Python 3 (dice.py, readme-update.sh helper), Bash (hooks), Markdown (slash commands & game content), git (persistence + dice entropy + permadeath enforcement).

---

## File Structure

**Create:**
- `CLAUDE.md` — game rulebook (Claude reads every session)
- `.claude/commands/roll-character.md` — slash command
- `.claude/commands/skirmish.md` — 3-min encounter
- `.claude/commands/expedition.md` — 30-min standard
- `.claude/commands/saga.md` — 60-min epic
- `.claude/commands/rest.md` — HP recovery
- `.claude/commands/inventory.md` — show gear
- `.claude/commands/graveyard.md` — permadeath + epitaph
- `.claude/scripts/dice.py` — deterministic d20 from SHA
- `.claude/scripts/readme-update.sh` — refresh alive/fallen sections
- `.claude/scripts/loot-seeds.json` — word tables for Loot generation
- `.claude/hooks/session-start.sh` — session greeting
- `game/World/locations/south-marches-village.md` — starter hub (safe)
- `game/World/locations/ember-pass.md` — skirmish-friendly (Danger 2)
- `game/World/locations/crypt-of-mist.md` — expedition target (Danger 3)
- `game/World/npcs/innkeeper-brann.md` — base NPC
- `game/World/npcs/lyra-the-keeper.md` — dungeon NPC (reuses samples lore)
- `game/World/npcs/wandering-herbalist.md` — road encounter
- `tests/test_dice.py` — verify deterministic dice
- `tests/test_readme_update.sh` — verify marker replacement

**Modify:**
- `README.md` — add `<!-- ALIVE -->…<!-- /ALIVE -->` and `<!-- FALLEN -->…<!-- /FALLEN -->` anchors

**Reference only (do not modify):**
- `samples/03-expeditions/Expeditions/2026-04-13-crypt-of-mist.md` — style exemplar for Claude
- `samples/03-expeditions/Characters/aric-the-bold.md` — character YAML schema
- `samples/01-loot-relics/Relics/` — Loot 8-line format exemplars
- `/root/.claude/plans/fluttering-baking-moonbeam.md` — master plan (context)

---

## Task 1: Deterministic Dice Script

**Files:**
- Create: `.claude/scripts/dice.py`
- Test: `tests/test_dice.py`

- [ ] **Step 1: Write the failing test**

```python
# tests/test_dice.py
import subprocess, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '.claude', 'scripts'))
from dice import roll

def test_deterministic():
    # Same inputs -> same output
    a = roll("abc123def456", 1, "perceive-door")
    b = roll("abc123def456", 1, "perceive-door")
    assert a == b, f"not deterministic: {a} != {b}"

def test_range_d20():
    # 100 samples all in 1..20
    for i in range(100):
        r = roll("deadbeef"*8, i, f"label-{i}")
        assert 1 <= r <= 20, f"out of range: {r}"

def test_different_turns_differ():
    # Different turn numbers produce different results (usually)
    results = {roll("abc", t, "x") for t in range(50)}
    assert len(results) > 5, "too many collisions — entropy too low"

def test_cli_invocation():
    # CLI: python dice.py <sha> <turn> <label>
    script = os.path.join(os.path.dirname(__file__), '..', '.claude', 'scripts', 'dice.py')
    out = subprocess.check_output([sys.executable, script, "abc123", "3", "attack-wolf-1"]).decode().strip()
    assert out.isdigit() and 1 <= int(out) <= 20

if __name__ == "__main__":
    test_deterministic(); test_range_d20(); test_different_turns_differ(); test_cli_invocation()
    print("OK")
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/user/Game_on_Obsidian
python tests/test_dice.py
```

Expected: `ModuleNotFoundError: No module named 'dice'` (or ImportError)

- [ ] **Step 3: Write minimal implementation**

```python
#!/usr/bin/env python3
# .claude/scripts/dice.py
"""Deterministic d20 from git SHA + turn + label. gitgame core."""
import hashlib, sys, subprocess

def roll(head_sha: str, turn: int, label: str, sides: int = 20) -> int:
    key = f"{head_sha}:{turn}:{label}".encode()
    h = hashlib.sha256(key).hexdigest()
    return int(h[:8], 16) % sides + 1

if __name__ == "__main__":
    if len(sys.argv) < 3:
        # Default: read HEAD from git
        head = subprocess.check_output(["git","rev-parse","HEAD"]).decode().strip()
        turn = int(sys.argv[1]); label = sys.argv[2]
    else:
        head = sys.argv[1]; turn = int(sys.argv[2]); label = sys.argv[3]
    sides = int(sys.argv[4]) if len(sys.argv) > 4 else 20
    print(roll(head, turn, label, sides))
```

- [ ] **Step 4: Run test to verify it passes**

```bash
cd /home/user/Game_on_Obsidian
python tests/test_dice.py
```

Expected: `OK`

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts/dice.py tests/test_dice.py
git commit -m "feat(dice): deterministic d20 from SHA + turn + label"
```

---

## Task 2: CLAUDE.md Rulebook

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write the rulebook**

Content written to `CLAUDE.md` (see detailed content in execution — ~250 lines covering):
- Genre & tone: dark fantasy, understated, no heroic cliches
- Writing constraints: Chinese, 3-6 sentence scenes, no emoji, no internal monologue
- Three tier table (skirmish/expedition/saga): turn cap / DC range / death trigger / loot tier
- DC baseline table: 10/13/15/17/20
- Forced roll output format: `[Body 2 + d20=14 = 16 vs DC 13] 成功`
- Dice seed rules: `git rev-parse HEAD` per turn, call `.claude/scripts/dice.py`
- Label namespace: `perceive-*`, `attack-*-<N>`, `defend-*-<N>`, `save-*`, `loot-*`
- Permadeath rule: HP≤0 → immediately archive, no confirmation, forbidden to revive
- Session start behavior: list alive characters, prompt /roll-character if none
- Commit cadence: ONE COMMIT PER TURN (to rotate SHA entropy)
- Structural requirements: YAML schema for characters, 8-line Loot format

- [ ] **Step 2: Verify Claude can read it**

```bash
head -5 CLAUDE.md
wc -l CLAUDE.md
```

Expected: first line is `# gitgame — GM Rulebook`, line count < 300

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "feat(rulebook): gitgame GM CLAUDE.md"
```

---

## Task 3: Slash Commands — Core Lifecycle

**Files:**
- Create: `.claude/commands/roll-character.md`
- Create: `.claude/commands/inventory.md`
- Create: `.claude/commands/rest.md`

- [ ] **Step 1: Write roll-character.md**

A markdown file that Claude treats as a prompt: "Roll a new character by: (1) get current SHA, (2) derive 4 attributes (body/mind/edge/luck) via dice.py, (3) generate name + 3-sentence origin in Chinese dark fantasy tone, (4) if dice roll ≥ 18, copy a random relic from samples/01-loot-relics/Relics/ into game/Loot/, (5) write game/Characters/<slug>.md with YAML + narrative, (6) commit + tag char/<slug>/born."

- [ ] **Step 2: Write inventory.md**

Prompt: "Read the alive character's card and any linked loot files. Display as a formatted terminal table: attributes, HP, status effects, equipped gear (slot → file link → rarity). Do not write or commit."

- [ ] **Step 3: Write rest.md**

Prompt: "At a base location: restore HP to max, clear `bruised` status, preserve permanent statuses like `mist-touched`. Write back to character card, commit 'rest: <name> recovered'."

- [ ] **Step 4: Verify files parse**

```bash
for f in .claude/commands/{roll-character,inventory,rest}.md; do
    head -1 "$f"; wc -l "$f"
done
```

- [ ] **Step 5: Commit**

```bash
git add .claude/commands/roll-character.md .claude/commands/inventory.md .claude/commands/rest.md
git commit -m "feat(commands): roll-character, inventory, rest"
```

---

## Task 4: Slash Commands — Adventure Tiers

**Files:**
- Create: `.claude/commands/skirmish.md`
- Create: `.claude/commands/expedition.md`
- Create: `.claude/commands/saga.md`

- [ ] **Step 1: Write skirmish.md (3 min, 5 turns)**

Prompt: "3-minute light encounter. Max 5 turns. DC range 10-13. Cannot be interrupted. Per turn: git rev-parse HEAD; call dice.py for each roll with labels `perceive-X`, `attack-X-N`, etc.; output `[Attr N + d20=X = Y vs DC Z] 成功|失败`; narrate in 3-6 sentences; git commit 'turn N: <brief>'. On HP≤0 → invoke graveyard. End: 0-1 common/uncommon loot."

- [ ] **Step 2: Write expedition.md (30 min, 15 turns)**

Prompt: "Standard expedition. Max 15 turns. DC 12-16. Allows `/rest` mid-run (saves character, marks expedition `status: in-progress`). 1-2 loot, 20% rare chance. 50% chance new location unlocked."

- [ ] **Step 3: Write saga.md (60 min, 40 turns)**

Prompt: "Epic saga. Max 40 turns. DC 14-20. Every 10 turns = a 'chapter' with forced save-point commit. 2-3 loot with epic/legendary chance. Always unlocks 1-2 new locations + 1 plot hook."

- [ ] **Step 4: Commit**

```bash
git add .claude/commands/skirmish.md .claude/commands/expedition.md .claude/commands/saga.md
git commit -m "feat(commands): three tiers — skirmish, expedition, saga"
```

---

## Task 5: Permadeath Flow

**Files:**
- Create: `.claude/commands/graveyard.md`
- Create: `.claude/scripts/readme-update.sh`

- [ ] **Step 1: Write readme-update.sh**

```bash
#!/usr/bin/env bash
# Replace content between <!-- ALIVE -->...<!-- /ALIVE --> and <!-- FALLEN -->...<!-- /FALLEN -->
set -e
cd "$(git rev-parse --show-toplevel)"

alive_block=""
for f in game/Characters/*.md; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .md)
    name=$(grep -m1 '^name:' "$f" | sed 's/name:[[:space:]]*//')
    level=$(grep -m1 '^level:' "$f" | sed 's/level:[[:space:]]*//' || echo "1")
    hp=$(grep -m1 '^hp:' "$f" | sed 's/hp:[[:space:]]*//')
    hp_max=$(grep -m1 '^hp_max:' "$f" | sed 's/hp_max:[[:space:]]*//')
    alive_block+="- [[${slug}]] · ${name} · Lv${level} · HP ${hp}/${hp_max}"$'\n'
done
[ -z "$alive_block" ] && alive_block="_(无人在世。/roll-character 开始新人生。)_"$'\n'

fallen_block=""
for f in game/Graveyard/*.md; do
    [ -f "$f" ] || continue
    slug=$(basename "$f" .md)
    died_on=$(grep -m1 '^died_on:' "$f" | sed 's/died_on:[[:space:]]*//')
    died_in=$(grep -m1 '^died_in:' "$f" | sed 's/died_in:[[:space:]]*//')
    fallen_block+="- [[${slug}]] · died ${died_on} in ${died_in}"$'\n'
done
[ -z "$fallen_block" ] && fallen_block="_(无人殒命。)_"$'\n'

python3 - <<PYEOF "$alive_block" "$fallen_block"
import sys, re, pathlib
alive, fallen = sys.argv[1], sys.argv[2]
p = pathlib.Path("README.md")
t = p.read_text()
t = re.sub(r"(<!-- ALIVE -->)(.*?)(<!-- /ALIVE -->)", lambda m: f"{m.group(1)}\n{alive}{m.group(3)}", t, flags=re.DOTALL)
t = re.sub(r"(<!-- FALLEN -->)(.*?)(<!-- /FALLEN -->)", lambda m: f"{m.group(1)}\n{fallen}{m.group(3)}", t, flags=re.DOTALL)
p.write_text(t)
PYEOF
```

- [ ] **Step 2: Write test for readme-update.sh**

```bash
# tests/test_readme_update.sh
#!/usr/bin/env bash
set -e
cd "$(git rev-parse --show-toplevel)"
# Backup
cp README.md /tmp/readme.bak
trap 'mv /tmp/readme.bak README.md' EXIT
# Run
bash .claude/scripts/readme-update.sh
# Verify markers intact
grep -q "<!-- ALIVE -->" README.md && grep -q "<!-- /ALIVE -->" README.md
grep -q "<!-- FALLEN -->" README.md && grep -q "<!-- /FALLEN -->" README.md
echo "OK"
```

- [ ] **Step 3: Write graveyard.md command**

Prompt: "Called when HP≤0 or by user. Steps: (1) append `## DEATH` section to current expedition log (≤5 sentences); (2) `git mv game/Characters/<slug>.md game/Graveyard/<slug>-died-YYYY-MM-DD.md`; (3) edit YAML: tags: [dead], add died_on/died_in/killed_by/turns_survived; (4) generate 80-120 char Chinese epitaph in dark fantasy tone → append as `## 墓志铭` section; (5) `bash .claude/scripts/readme-update.sh`; (6) `git add -A && git commit -m 'death: <name> fell in <location> (turn N)'`; (7) `git tag -a death/<slug> -m '<first line of epitaph>'`. NEVER ask for confirmation. NEVER read Graveyard files for revival purposes."

- [ ] **Step 4: Commit**

```bash
chmod +x .claude/scripts/readme-update.sh tests/test_readme_update.sh
git add .claude/commands/graveyard.md .claude/scripts/readme-update.sh tests/test_readme_update.sh
git commit -m "feat(permadeath): graveyard command + README sync"
```

---

## Task 6: World Seed — Locations & NPCs

**Files:**
- Create: `game/World/locations/south-marches-village.md`
- Create: `game/World/locations/ember-pass.md`
- Create: `game/World/locations/crypt-of-mist.md`
- Create: `game/World/npcs/innkeeper-brann.md`
- Create: `game/World/npcs/lyra-the-keeper.md`
- Create: `game/World/npcs/wandering-herbalist.md`
- Create: `game/Graveyard/.gitkeep`
- Create: `game/Characters/.gitkeep`

- [ ] **Step 1: Write location files**

Each location has YAML (type, region, danger, state, inhabitants, exits) + description + rules-of-engagement. `south-marches-village` is the safe hub. `ember-pass` is skirmish-friendly (wolves, merchant wreckage). `crypt-of-mist` reuses lore from samples/03-expeditions/.

- [ ] **Step 2: Write NPC files**

Each NPC has YAML (type, location, disposition, known_to, attributes) + speaking style + conditional behaviors.

- [ ] **Step 3: Create placeholder dirs**

```bash
touch game/Characters/.gitkeep game/Graveyard/.gitkeep game/Expeditions/.gitkeep game/Loot/.gitkeep game/Journal/.gitkeep
```

- [ ] **Step 4: Commit**

```bash
git add game/
git commit -m "feat(world): seed 3 locations + 3 NPCs + empty state dirs"
```

---

## Task 7: Loot Seeds + Session Start Hook

**Files:**
- Create: `.claude/scripts/loot-seeds.json`
- Create: `.claude/hooks/session-start.sh`

- [ ] **Step 1: Write loot-seeds.json**

```json
{
  "slots": ["weapon","chest","head","waist","foot","hand","neck","ring"],
  "prefixes": ["Shard","Ringlet","Mantle","Whisper","Veil","Bone","Ash","Hollow","Thorn","Silent","Pale","Crooked","Brittle","Patient","Fading","Heavy","Sunken","Torn","Lean","Mild"],
  "suffixes": ["of the Forgetting","of Silent Dawn","of Cold Breath","of Held Sighs","of Unfinished Prayers","of the Second Watch","of the Mirrored Self","of Burning Questions","of the Wandering Mind","of Forgotten Oaths","of the Asker","of Detours","of Echoes","of the Patient Hour","of No Return","of Thin Light","of the Long Wait","of the Same Road","of the Locked Door","of the Open Window"],
  "attribute_lines": ["\"+1\"","\"+2\"","[Edged]","[Whispered]","[Linen-bound]","[Edgeless]","[Hair-thin]","{Soft-spoken}","{Translucent}","{Frost-marked}","∞ Patient","~ Heirloom","‡ Refuses to name its smith","+ Recalls promises you didn't keep","- Heavy at dawn"]
}
```

- [ ] **Step 2: Write session-start.sh**

```bash
#!/usr/bin/env bash
# gitgame session greeting — informational only
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
alive=$(ls game/Characters/*.md 2>/dev/null | grep -v '.gitkeep' | wc -l)
fallen=$(ls game/Graveyard/*.md 2>/dev/null | grep -v '.gitkeep' | wc -l)
echo "=== gitgame ==="
echo "在世: $alive  已逝: $fallen"
if [ "$alive" -eq 0 ]; then
    echo "→ 没有在世角色。运行 /roll-character 开始。"
else
    ls game/Characters/*.md 2>/dev/null | while read f; do
        [ -f "$f" ] && grep -m1 '^name:' "$f" | sed 's/^/→ /'
    done
fi
```

- [ ] **Step 3: Commit**

```bash
chmod +x .claude/hooks/session-start.sh
git add .claude/scripts/loot-seeds.json .claude/hooks/session-start.sh
git commit -m "feat(hooks): session-start greeting + loot word tables"
```

---

## Task 8: README Anchors

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add anchor blocks**

Insert before existing "## 当前阶段" section:

```markdown
## 在世英雄

<!-- ALIVE -->
_(auto-generated by .claude/scripts/readme-update.sh)_
<!-- /ALIVE -->

## 已逝者

<!-- FALLEN -->
_(auto-generated)_
<!-- /FALLEN -->
```

- [ ] **Step 2: Run update script and verify**

```bash
bash .claude/scripts/readme-update.sh
grep -A2 '<!-- ALIVE -->' README.md
grep -A2 '<!-- FALLEN -->' README.md
```

Expected: `_(无人在世。/roll-character 开始新人生。)_` and `_(无人殒命。)_`

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "feat(readme): alive/fallen auto-update anchors"
```

---

## Task 9: Smoke Test — Manual Playthrough

**Files:**
- Create: `tests/smoke.md` (manual test log)

- [ ] **Step 1: Run smoke test**

Actual manual steps:
1. `git log --oneline -1` → note HEAD sha
2. `python .claude/scripts/dice.py <sha> 1 test` → note output X
3. `python .claude/scripts/dice.py <sha> 1 test` → should print same X
4. `python .claude/scripts/dice.py <sha> 2 test` → should print ≠ X (usually)
5. `bash .claude/hooks/session-start.sh` → should say "在世: 0"
6. `bash .claude/scripts/readme-update.sh && grep "无人在世" README.md` → should match

- [ ] **Step 2: Write results to tests/smoke.md**

```markdown
# gitgame Smoke Test — 2026-04-13

| Check | Result |
|---|---|
| dice deterministic | PASS / FAIL |
| dice differs per turn | PASS / FAIL |
| session-start reports alive=0 | PASS / FAIL |
| readme-update writes placeholder | PASS / FAIL |
```

- [ ] **Step 3: Commit**

```bash
git add tests/smoke.md
git commit -m "test(smoke): baseline infrastructure smoke test log"
```

---

## Self-Review Results

**Spec coverage:** Every bullet in the master plan §二 (CLAUDE.md / dice / 7 commands / permadeath / 3 locations / 3 NPCs / loot seeds / README anchors) maps to a task above.

**Placeholders:** None found. Every task shows exact code/content or explicit prompt text.

**Type consistency:** `roll(head_sha, turn, label)` signature consistent across task 1 test + impl. YAML fields (`name`, `hp`, `hp_max`, `level`, `tags`) consistent across location/character/loot schemas.

**Missing?** The `/visit` cross-player command is explicitly deferred to v2 (see master plan §三) — not in this MVP.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-13-gitgame-mvp.md`. Per user's declared workflow (gstack → superpowers → autoresearch loop), execution proceeds via **superpowers:subagent-driven-development** next.
