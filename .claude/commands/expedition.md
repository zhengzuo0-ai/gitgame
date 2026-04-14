---
description: 30-minute standard adventure. Max 15 turns. DC 12-16. Can /rest to retreat. 1-2 loot, 20% rare chance.
---

# /expedition

Arguments: $ARGUMENTS — location slug. Required.

## Differences from /skirmish

Read `skirmish.md` first (same structure). The deltas:

- **Max turns: 15** (instead of 5).
- **DC range: 12–16** (instead of 10–13). Generally tougher decisions.
- **Can be interrupted**: If player types `/rest` mid-expedition, the `rest` command completes this expedition early as `retreated` (half XP, no loot).
- **Loot tier**: better (survival guarantees at least 1 common — see CLAUDE.md "奖励保底")
  - `loot_d20 = python3 .claude/scripts/dice.py $SHA 99 loot-drop`
  - 1..5   → **floor to 6** (保底: 1 common/uncommon)
  - 6..14  → 1 common/uncommon
  - 15..18 → 2 items, at least 1 uncommon
  - 19..20 → 1 rare (roll second item separately at skirmish-tier)
- **XP**: 40–100 depending on turns + climax.
- **Location unlock**: 50% chance to reveal a new adjacent location:
  - `unlock_d20 = python3 .claude/scripts/dice.py $SHA 99 unlock`  — ≥ 11 means unlock
  - If unlocked: generate a new `game/World/locations/<new-slug>.md` with YAML + 3-sentence description. Add `exits: ["[[<cur-loc>]]"]` to the new one; append `"[[<new-loc>]]"` to current location's `exits`.

## Mid-expedition NPC rule

- When an NPC appears for the first time, read their `npcs/*.md` card. Capture:
  - Their `disposition` (hostile / neutral / curious / mournful)
  - Their `attributes` (for opposed rolls)
  - Their **speaking style** (e.g., Lyra is sparse and indirect)
- Keep that voice consistent throughout. If you don't have a card, generate one at the end of the expedition.

## Per-turn commit rule stays the same

**One commit per turn**, `turn N: <desc>`. This rule does not relax for longer adventures — the SHA entropy depends on it.

## Style reminders

- Because expedition is longer, you have space to vary rhythm: short combat turns, longer atmospheric turns, short dialog turns.
- Don't inflate — if a turn is just "我走过去看看"，a 3-sentence description + a single perceive-roll is correct.
- At turn ~10, tension should peak. Not a scripted climax, but a decision point.
