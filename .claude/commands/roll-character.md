---
description: Roll a new character — hatch attributes from SHA, ask Claude for name & origin, maybe grant a starter relic.
---

# /roll-character

Arguments: $ARGUMENTS (optional — unused for now; future: class preference)

## Steps

1. **Check preconditions**
   - If `game/Characters/` contains any file with `tags: [...alive]` → refuse:
     "还有英雄在世。用 `/graveyard` 送走他，或 `/rest` 接着玩。"
   - Run `git rev-parse HEAD` → save as `SHA`.

2. **Derive attributes deterministically**
   - body  = `python .claude/scripts/dice.py $SHA 1 attr-body`  mod 5 + 1
   - mind  = `python .claude/scripts/dice.py $SHA 1 attr-mind`  mod 5 + 1
   - edge  = `python .claude/scripts/dice.py $SHA 1 attr-edge`  mod 5 + 1
   - luck  = `python .claude/scripts/dice.py $SHA 1 attr-luck`  mod 5 + 1
   - (Map dice.py's 1..20 output to 1..5 via `((d-1) % 5) + 1`.)

3. **Derive starter roll & class**
   - starter = `python .claude/scripts/dice.py $SHA 1 starter-roll`  (1..20 directly)
   - class_roll = `python .claude/scripts/dice.py $SHA 1 class-roll`
     - 1..7  → Wandering Scholar
     - 8..13 → Lantern-Bearer
     - 14..17 → Ashen Soldier
     - 18..20 → Mist-Bound (rare class, +1 luck)

4. **Generate name + 3-sentence origin in Chinese dark fantasy tone**
   - Name: 2–3 Chinese characters OR a Western name (you choose by class feel).
   - Origin: 3 sentences max. Where they came from, what they lost, one specific memory.
   - Tone: cold, understated. No "chosen one" tropes.

5. **Grant starter relic if starter ≥ 18**
   - `ls samples/01-loot-relics/Relics/*.md` → pick one deterministically:
     `index = python .claude/scripts/dice.py $SHA 1 starter-relic`  mod N
   - Copy it to `game/Loot/<orig-slug>.md` (overwrite `owner` YAML field if present).
   - Add to new character's `inventory: ["[[<slug>]]"]`.

6. **Write character file**
   - Path: `game/Characters/<name-slug>.md`
   - slug = lowercase, spaces → hyphens, no punctuation
   - Full YAML per CLAUDE.md schema + the narrative as Markdown body
   - `level: 1, xp: 0, hp: 10 + body, hp_max: 10 + body, gold: 0, expeditions_survived: 0`
   - `created` and `last_played` = today
   - `tags: [character, alive]`

7. **Commit + tag**
   ```bash
   git add game/
   git commit -m "character: rolled <name>, <class>"
   git tag -a "char/<slug>/born" -m "<name> arrived. Attributes: b<body>/m<mind>/e<edge>/l<luck>."
   ```

8. **Update README**
   ```bash
   bash .claude/scripts/readme-update.sh
   git add README.md
   git commit --amend --no-edit
   ```
   (Amend the character commit so README sync is atomic with birth.)

9. **Greet the player in-character**
   - Show the full card (name, class, attrs, HP, origin prose)
   - Ask: "要去哪？`/skirmish [地点]` / `/expedition [地点]` / `/rest`"

## Style

- Output is terminal-rendered. Use headers, bold, bullets sparingly.
- The origin paragraph should feel like a line from a novel, not character creation tutorial.
- Don't justify the dice. Report them as fate.
