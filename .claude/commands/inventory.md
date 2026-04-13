---
description: Display the current alive character's full card — attributes, status, equipped gear. Read-only.
---

# /inventory

Arguments: $ARGUMENTS (optional — character slug; defaults to the only alive character)

## Steps

1. **Find the alive character**
   - Scan `game/Characters/*.md`, match YAML `tags: [...alive]`.
   - If argument given, look for that slug specifically.
   - If 0 alive → "无人在世。`/roll-character` 开始新人生。"
   - If ≥2 alive (future state) → ask which one.

2. **Read the card**
   - Parse YAML frontmatter.
   - For each entry in `inventory`, read the corresponding `game/Loot/<slug>.md` and extract its 8-line text + rarity.

3. **Display** (don't write anything, don't commit)

Format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
  <name>
  <class> · Lv<level> · <expeditions_survived> 次冒险
━━━━━━━━━━━━━━━━━━━━━━━━━━━

  HP:     <hp> / <hp_max>
  XP:     <xp> / <xp_to_next>
  Gold:   <gold>

  Body:   <body>      Mind:  <mind>
  Edge:   <edge>      Luck:  <luck>

  状态:   <status list or "—">

━━━━━━ 装备 ━━━━━━
  [<slot>]  <item name>  · <rarity>
             "<one-line excerpt>"

  ... (repeat for each equipped item)

  空槽位: <list of unfilled slots>

━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

4. **Offer no suggestions unless asked.** This command is read-only, don't push player toward next action.

## Style

- Use em dashes and box-drawing characters (already shown above).
- Show only equipped items (those in `inventory`). Loot sitting in `game/Loot/` but not in inventory is storage — note count at bottom if > 0.
- Rarity color cues (just text): `common` / `uncommon` / `rare` · **epic** · ★ legendary
