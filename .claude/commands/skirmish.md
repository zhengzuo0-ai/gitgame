---
description: 3-minute light encounter. Max 5 turns. DC 10-13. No retreat. 0-1 common/uncommon loot.
---

# /skirmish

Arguments: $ARGUMENTS — location slug (e.g., `ember-pass`). Required.

## Preconditions

1. Exactly one alive character in `game/Characters/`.
2. Location file exists at `game/World/locations/<slug>.md`. If not → refuse or offer to generate one (with user confirmation).
3. No in-progress expedition. If there is, tell user to `/rest` first.

## Initialization

1. Read the alive character card (slug, hp, hp_max, attributes, inventory).
2. Read the location card. Note `danger`, `inhabitants`, any `triggers` (first-visit events).
3. Generate expedition filename: `game/Expeditions/<YYYY-MM-DD>-<char-slug>-<loc-slug>.md`.
4. Write initial YAML to expedition file:
   ```yaml
   ---
   date: YYYY-MM-DD
   tier: skirmish
   character: "[[<char-slug>]]"
   location: "[[<loc-slug>]]"
   turns: 0
   max_turns: 5
   status: in-progress
   ---
   ```
5. **Scene opener** — 3–6 sentences in CLAUDE.md style. Set the place, the immediate sensory detail. End with implicit choice (don't explicitly ask "what do you do" — just pause).
6. Commit: `git commit -m "skirmish start: <name> at <loc>"`.

## Per-turn loop (repeat until end condition)

**Turn N (starting at 1):**

1. `SHA=$(git rev-parse HEAD)` — save for this turn.
2. Wait for player input (their action).
3. Decide what judgments are needed. Typical encounter: 1–3 rolls per turn.
4. For each roll:
   - Choose label from namespace: `perceive-<obj>` / `attack-<enemy>-<N>` / `defend-<enemy>-<N>` / `save-<situation>` / `talk-<npc>`.
   - `d20 = bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA $N <label>`
   - Total = d20 + relevant attribute.
   - DC from CLAUDE.md table (10 simple, 13 standard — skirmish stays in this range).
   - Output forced line: `` `[<Attr> <val> + d20=<d20> = <total> vs DC <dc>] 成功|失败` ``
5. Narrate outcome in 2–4 sentences. Update character card if HP/status changed.
6. **State sync (mandatory pre-commit checklist)**:
   - HP / status / inventory changed → write character card.
   - Anything in the location changed (door opened, sarcophagus emptied, guard killed, statue toppled) → write `game/World/locations/<loc>.md` (`state` field or new `events: [...]`).
   - First-time NPC encountered with no card → generate `game/World/npcs/<slug>.md` now.
   - Item picked up → `game/Loot/<slug>.md` exists (see Resolution step 2).
7. **End-of-turn commit**:
   - Append dialogue block (player action + rolls + narration) to expedition file.
   - `git add -A && git commit -m "turn $N: <brief description>"`

## End conditions

- **HP ≤ 0** → jump to DEATH flow (see below).
- **Turn count reaches 5** → forced resolution.
- **Narrative climax** (enemy defeated, escape successful, mystery resolved) → natural end.

## DEATH flow

1. Append `## DEATH` section to expedition file (≤ 5 sentences — the angle of the fall, what the character saw last).
2. Invoke `/graveyard` flow (see `.claude/commands/graveyard.md`).

## Resolution (if survived)

1. Write `## 结算` section with: turns survived, HP remaining, summary.
2. **Loot roll**: `loot_d20 = bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 99 loot-drop`
   - 1..5  → **no loot, but a rumor is guaranteed** (see step 2b)
   - 6..10 → no loot, no rumor
   - 11..18 → 1 common item
   - 19..20 → 1 uncommon item
   - For each item, **call the loot generator** (do NOT hand-write the 8 lines):
     ```bash
     bash .claude/scripts/py.sh .claude/scripts/generate-loot.py $SHA 99 <idx> <rarity>
     ```
     Capture stdout (the `<!-- slug: ... -->` first line gives you the filename slug). Write the rest to
     `game/Loot/<slug>.md`, then patch the YAML to add `acquired_at: YYYY-MM-DD` and
     `acquired_from: "[[<loc-slug>]]"`. Append `[[<slug>]]` to the character's `inventory`.
   - **Skipping the file write is forbidden.** "你拾起一把生锈的短剑" without `game/Loot/*.md` is a data-integrity bug.

2b. **Rumor on dry roll** (loot_d20 ∈ 1..5):
   - `rumor_d20 = bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 99 rumor`
   - Generate `game/World/rumors/<slug>.md` — a short YAML (`slug`, `heard_at: "[[<loc>]]"`, `heard_from: <npc-slug or "wind">`, `tags: [rumor]`) + 1–2 sentences hinting at a distant location, NPC, or faction. This is the "出行必有所得" floor: even a failed expedition yields *something*.

3. **XP**: use the formula in CLAUDE.md (`turns*2 + successes*3 + discoveries*5`). Skirmish typically lands at 15–35.
4. Update character card: `xp`, `expeditions_survived`, `last_played`, potentially `status`.
5. Change expedition YAML: `status: survived`, `outcome: <brief>`, fill `turns`, `loot_gained: [...]`, `xp_gained`.
6. Commit: `git commit -m "skirmish end: <name> survived <loc> (turn N)"`.
7. Run `.claude/scripts/readme-update.sh` then `git commit --amend --no-edit`.
8. In narration: tell the player what happened, what they found, ask "接下来？".

## Style reminders (see CLAUDE.md)

- 3–6 sentence scenes. Less is more.
- NPC dialog in `「」`.
- Roll output format is **forced**.
- One commit per turn, always.
