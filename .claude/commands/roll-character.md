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
   - body  = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 attr-body`  mod 5 + 1
   - mind  = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 attr-mind`  mod 5 + 1
   - edge  = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 attr-edge`  mod 5 + 1
   - luck  = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 attr-luck`  mod 5 + 1
   - (Map dice.py's 1..20 output to 1..5 via `((d-1) % 5) + 1`.)

3. **Derive starter roll & class**
   - starter = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 starter-roll`  (1..20 directly)
   - class_roll = `bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 class-roll`
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
     `index = bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 1 starter-relic`  mod N
   - Copy it to `game/Loot/<orig-slug>.md` (overwrite `owner` YAML field if present).
   - Add to new character's `inventory: ["[[<slug>]]"]`.

5b. **Inheritance from the most recent grave** (if `game/Graveyard/` is non-empty)
   - Pick the most recently buried character: `ls -t game/Graveyard/*.md | head -1` (skip `.gitkeep`).
   - Generate **one common-tier item** via `generate-loot.py`:
     ```bash
     bash .claude/scripts/py.sh .claude/scripts/generate-loot.py $SHA 1 99 common
     ```
   - Write to `game/Loot/<slug>.md`, then patch the YAML to add:
     - `inherited_from: "[[<previous-character-slug>]]"`
     - `acquired_at: <today>`
     - `acquired_from: "graveyard"`
   - Append `[[<slug>]]` to new character's `inventory`.
   - In the origin paragraph, mention this item exists and how the new character came by it
     (a stranger pressed it into their hand at the inn / they found it tied to a marker stone /
     it was in a bundle a traveler left). **Do not** name the dead character — let the player
     find that thread themselves by reading the grave.

   This is the only allowed link between graves and new lives. It is **not** resurrection;
   it is a single common object passing forward, the way real estates do.

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

10. **Onboarding nudge — first character only**
    - Detect "first character ever" = `game/Graveyard/` is empty (only `.gitkeep`) **and** this is the only file
      in `game/Characters/` after step 6.
    - If so, after the greeting, append **exactly three short sentences** (no headers, no bullet points,
      keep the same diegetic tone — like a quiet aside, not a tutorial pop-up):

      ```
      你可以用自然语言告诉我你想做什么——「我推开门」「我朝守墓人喊一声」都行，不必背命令。
      四个属性 body / mind / edge / luck 是判定时的加成；高的那个对应你擅长的方向。
      死亡是永久的——没有读档，没有"再来一次"。
      ```

    - **Do NOT** show this for second-and-onward characters. Returning players know the rules; the inheritance
      step (5b) and the heavier session-start tone are enough signal.

## Style

- Output is terminal-rendered. Use headers, bold, bullets sparingly.
- The origin paragraph should feel like a line from a novel, not character creation tutorial.
- Don't justify the dice. Report them as fate.
