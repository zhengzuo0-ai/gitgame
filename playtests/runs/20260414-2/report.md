# Playtest Report: 20260414-2

## Meta

- **Date**: 2026-04-14
- **Tier**: skirmish
- **Location**: ember-pass
- **Character**: 沈霭 (Mist-Bound)
- **Outcome**: survived
- **Turns played**: 5
- **Loot gained**: Ringlet of the Wandering Mind (common, waist)
- **XP gained**: 25

---

## Dice Mechanics

- Total rolls observed: 9
- Format correct (`[Attr N + d20=N = N vs DC N] 成功|失败`): yes
- DC range appropriate for tier: yes (DC 10 for perception, DC 13 for combat — within skirmish 10-13 range)
- Attribute bonuses applied correctly: yes (Body 2 for melee/defense, Mind 3 for perception, Edge 2 for dodge)
- Dice labels followed namespace convention: mostly — `talk-wolves` was used for an intimidation/body check against animals, which stretches the `talk-<npc>` namespace since wolves are not NPCs. No dedicated `intimidate-*` label exists in the spec.
- Any duplicate labels handled with `-2`, `-3` suffix: partially — `defend-wolves-1` and `defend-wolves-2` used incrementing suffixes correctly. `attack-wolf-1` and `attack-wolf-2` also correct. However the numbering was across turns rather than within a single turn, which is an edge case the spec doesn't clearly address.

## Narrative Quality

- Scene descriptions within 3-6 sentences: yes
- NPC dialog uses `「」`: N/A (no NPC dialog in this encounter)
- No emoji in narrative: yes
- No player mind-reading ("你感到..."): yes
- Prose tone matches dark fantasy: yes — understated, sensory, no melodrama
- End-of-turn options displayed: yes (shown between turns in player-facing output)

## Commit Discipline

- One commit per turn: **no** — turns 1-4 each had their own commit, but turn 5 was merged into the "skirmish end" resolution commit instead of being committed separately first. This violates the "one commit per turn" rule.
- Commit message format `turn N: <desc>`: yes for turns 1-4. Turn 5 was absorbed into `skirmish end:` message.
- SHA rotated each turn (new entropy): yes for turns 1-4. Turn 5 used the same SHA as turn 4's end state since there was no intervening commit.

## Character & State Management

- Character card created correctly: yes — YAML schema matches spec, HP = 10 + body = 12, all fields present
- HP updated after damage/healing: yes (12 → 8 after turn 2, 8 → 5 after turn 3)
- Status effects tracked: N/A (no status effects applied)
- Inventory updated on loot gain: yes (added `[[ringlet-of-the-wandering-mind]]` at resolution)

## Death Handling (if applicable)

- Death triggered at HP <= 0: N/A
- `## DEATH` section appended: N/A
- `/graveyard` flow invoked: N/A
- No resurrection offered: N/A
- Tags changed to `[character, dead]`: N/A

## Loot (if applicable)

- 8-line format followed: yes
- Flavor text <= 80 chars: yes (38 chars Chinese)
- Loot file written to `game/Loot/`: yes
- Rarity appropriate for tier: yes (common, loot_d20=13 → common/uncommon range)
- Floor rule applied (expedition/saga): N/A (skirmish has no floor rule)

## Bugs Found

1. **Turn 5 commit discipline violation**: Turn 5 narration was committed together with the resolution in a single "skirmish end" commit, rather than having a separate `turn 5:` commit followed by a resolution commit. This means turn 5's dice used the same SHA as turn 4's end state, reducing entropy isolation.

2. **Label namespace gap**: The spec defines `talk-<npc>` for dialog but provides no label for non-verbal intimidation/confrontation with animals. The GM had to shoehorn "scaring wolves by looking big" into `talk-wolves`, which is semantically wrong — it was a Body check, not a dialog.

3. **Wandering Herbalist not encountered**: The location file lists `[[wandering-herbalist]]` as an inhabitant, but the NPC never appeared during the skirmish. The skirmish flow doesn't specify whether listed NPCs should have a chance to appear — this may be by design (random encounters) but there's no roll to determine NPC presence.

## Friction Points

1. **Damage calculation is ad-hoc**: The rules specify DC and roll mechanics but have no formula for damage on failed defense rolls. The GM improvised 4 HP and 3 HP damage for wolf attacks with no mechanical basis. This could lead to inconsistent difficulty across sessions.

2. **Attribute for intimidation unclear**: The spec maps attributes to broad categories (body → "体力与近战") but physical intimidation (making yourself big, shouting) is ambiguous — is it Body (physical presence), Edge (precise action), or something else?

3. **Loot attribute lines are a grab-bag**: The 8-line format mixes mechanical bonuses (`+2`), flavor text (`[Linen-bound]`), and narrative hooks (`- Heavy at dawn`). It's unclear which lines have mechanical effects vs. being purely narrative.

## Positive Observations

1. **Dramatic dice arc**: The rolls naturally created a compelling narrative — terrible luck early (d20 rolls of 3, 1, 4) building to a climactic natural 20 on the final turn. The deterministic dice system doesn't feel "rigged" even when it produces drama.

2. **Scene-setting is strong**: The opener at Ember Pass immediately established atmosphere (burnt earth, wrecked cart, distant movement) with sensory details and no wasted words.

3. **Tactical options feel real**: Using the cart for cover in turn 4 was a genuine decision that changed the encounter's dynamics. The environment interacted meaningfully with combat.

4. **Character creation is fast and flavorful**: The SHA-seeded attributes + class roll produces a character quickly. The Mist-Bound class (+1 luck) feels earned by the rare roll.

5. **Loot generation produces evocative names**: "Ringlet of the Wandering Mind" from mechanical seed tables is surprisingly atmospheric.

## Raw Notes

- The `dice.py` script was called correctly every time and returned values in expected 1-20 range.
- `readme-update.sh` ran without errors on both character creation and skirmish resolution.
- Location file was updated with `first_entered_by` and `state: entered` as the trigger spec requires.
- Git tagging worked for character birth (`char/shen-ai/born`).
- The playtest ran a full skirmish (5 turns) without any crashes or blocking errors.
- Total git commits in session: 1 (character) + 1 (skirmish start) + 4 (turns 1-4) + 1 (turn 5 + resolution) = 7 commits. Should ideally be 8 (separate turn 5 and resolution).
- No attempt was made to `/rest` during skirmish (should be refused per rules) — this edge case was not tested.
- No attempt to re-roll dice was made — anti-cheat was not tested.
