# Playtest Report: {{RUN_ID}}

## Meta

- **Date**: {{YYYY-MM-DD}}
- **Tier**: skirmish | expedition | saga
- **Location**: {{location slug}}
- **Character**: {{name}} ({{class}})
- **Outcome**: survived | died | retreated
- **Turns played**: {{N}}
- **Loot gained**: {{list or "none"}}
- **XP gained**: {{N}}

---

## Dice Mechanics

- Total rolls observed: {{N}}
- Format correct (`[Attr N + d20=N = N vs DC N] 成功|失败`): yes | no (details)
- DC range appropriate for tier: yes | no (details)
- Attribute bonuses applied correctly: yes | no (details)
- Dice labels followed namespace convention: yes | no (details)
- Any duplicate labels handled with `-2`, `-3` suffix: N/A | yes | no

## Narrative Quality

- Scene descriptions within 3-6 sentences: yes | mostly | no
- NPC dialog uses `「」`: yes | N/A | no
- No emoji in narrative: yes | no
- No player mind-reading ("你感到..."): yes | no
- Prose tone matches dark fantasy: yes | mostly | no
- End-of-turn options displayed: yes | no (which turns missed)

## Commit Discipline

- One commit per turn: yes | no (details)
- Commit message format `turn N: <desc>`: yes | no
- SHA rotated each turn (new entropy): yes | no

## Character & State Management

- Character card created correctly: yes | no (details)
- HP updated after damage/healing: yes | no | N/A
- Status effects tracked: yes | no | N/A
- Inventory updated on loot gain: yes | no | N/A

## Death Handling (if applicable)

- Death triggered at HP <= 0: yes | no | N/A
- `## DEATH` section appended: yes | no | N/A
- `/graveyard` flow invoked: yes | no | N/A
- No resurrection offered: yes | no | N/A
- Tags changed to `[character, dead]`: yes | no | N/A

## Loot (if applicable)

- 8-line format followed: yes | no | N/A
- Flavor text <= 80 chars: yes | no | N/A
- Loot file written to `game/Loot/`: yes | no | N/A
- Rarity appropriate for tier: yes | no | N/A
- Floor rule applied (expedition/saga): yes | no | N/A

## Bugs Found

List any rule violations, crashes, inconsistencies, or unexpected behavior:

1. {{description}}

## Friction Points

Things that technically work but feel wrong or confusing:

1. {{description}}

## Positive Observations

What worked well or felt good:

1. {{description}}

## Raw Notes

Free-form observations captured during play:

{{notes}}
