---
description: Rest at a base location — restore HP to max, clear temporary status effects, keep permanent ones.
---

# /rest

Arguments: $ARGUMENTS (optional — specify base location; defaults to current `last_seen_at`)

## Preconditions

1. Must have exactly one alive character.
2. Character must be at a `type: location` file with `tag: safe` (in `game/World/locations/*.md`),
   OR the location file has `inhabitants: [innkeeper-brann]` (any NPC marked as innkeeper counts as safe).
3. If in the middle of an `/expedition` with `status: in-progress`, resting **completes** that expedition early with outcome `retreated`.

If preconditions fail → explain and suggest nearest safe location based on `exits` from current one.

## Steps

1. **Read alive character card.**

2. **Restore HP**: `hp = hp_max`.

3. **Clear temporary statuses**. Temporary = anything not in this permanent list:
   - `mist-touched`
   - `oath-bound`
   - `ember-marked`
   - `lyra-recognized`
   - any custom status with YAML sub-field `permanent: true`

   Typical temporary ones (to remove):
   - `bruised`, `poisoned`, `exhausted`, `cold`, `thirsty`, `shaken`

4. **If any in-progress expedition exists** (`game/Expeditions/*.md` with `status: in-progress`):
   - Append `## 撤退` section: 2 sentences describing the retreat.
   - Change YAML to `status: retreated`, `outcome: survived-retreat`.
   - Note: retreated expeditions do NOT give normal loot/xp. Partial XP = floor(xp_potential / 2).

5. **Read the base location's NPCs** before narrating. For every entry in `inhabitants:`,
   open `game/World/npcs/<slug>.md` and pick up their voice, quirks, and `disposition`.
   At least one of them should appear in the rest scene (briefly), but **the NPC must speak ≤ 3 sentences total** —
   a single line of dialog plus at most a small bit of stage business. The inn is not a tavern of exposition.
   If a card is missing for an inhabitant, generate it now (see CLAUDE.md 叙事触发器 first-time NPC rule).

6. **Narrate** 2–4 sentences: the inn's smell, the bed, maybe one line of NPC dialogue from the innkeeper (counting toward the ≤3-sentence NPC budget).

7. **Commit**
   ```bash
   git add -A
   git commit -m "rest: <name> recovered at <location>"
   ```

## Style

- No "you feel refreshed!" — just describe the physical setting.
- One NPC line is fine (innkeeper saying "又回来了" etc.), no exposition.
- The mood: you survived, but the weight accumulates. Rest heals HP, not memory.
