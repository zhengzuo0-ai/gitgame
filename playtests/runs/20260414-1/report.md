# Playtest Report: 20260414-1

## Meta

- **Date**: 2026-04-14
- **Tier**: skirmish
- **Location**: ember-pass
- **Character**: 沈渡 (Mist-Bound)
- **Outcome**: survived
- **Turns played**: 5
- **Loot gained**: none (loot-drop d20=1)
- **XP gained**: 20

---

## Dice Mechanics

- Total rolls observed: 6
- Format correct (`[Attr N + d20=N = N vs DC N] 成功|失败`): yes
- DC range appropriate for tier: yes (DCs used: 10, 11, 12, 13 — all within skirmish 10-13 range)
- Attribute bonuses applied correctly: yes (Mind 3 for perception, Body 2 for attack/intimidate, Edge 2 for defense, Luck 4 for creative action)
- Dice labels followed namespace convention: yes (perceive-cart, talk-wolves, attack-alpha-wolf-1, defend-alpha-wolf-1, save-herbs-distract, perceive-alpha-wolf, attack-alpha-wolf-2)
- Any duplicate labels handled with `-2`, `-3` suffix: N/A — no duplicate labels occurred

**Note**: The `save-herbs-distract` label is a reasonable creative interpretation of the namespace rules (`save-<situation>`), though `save-` is described as "回避（陷阱、毒、崩塌）" in CLAUDE.md. Could argue it should be a different label type.

## Narrative Quality

- Scene descriptions within 3-6 sentences: yes
- NPC dialog uses `「」`: N/A (no NPC dialog occurred — wolves don't talk)
- No emoji in narrative: yes
- No player mind-reading ("你感到..."): yes
- Prose tone matches dark fantasy: yes — understated, cold, sensory-focused
- End-of-turn options displayed: yes (all 5 turns showed `行动 · 对话 · 观察`)

## Commit Discipline

- One commit per turn: yes (5 turn commits + start + end = 7 total)
- Commit message format `turn N: <desc>`: yes (turns 1-5 all follow format)
- SHA rotated each turn (new entropy): yes — verified 5 distinct SHAs used for dice rolls

## Character & State Management

- Character card created correctly: yes — all YAML fields present, HP = 10 + body = 12, Mist-Bound +1 luck applied
- HP updated after damage/healing: yes — updated to 8 after turn 3 (-4 damage)
- Status effects tracked: yes — `wounded` added in turn 3, cleared at resolution
- Inventory updated on loot gain: N/A (no loot)

## Death Handling (if applicable)

- Death triggered at HP <= 0: N/A
- `## DEATH` section appended: N/A
- `/graveyard` flow invoked: N/A
- No resurrection offered: N/A
- Tags changed to `[character, dead]`: N/A

## Loot (if applicable)

- 8-line format followed: N/A
- Flavor text <= 80 chars: N/A
- Loot file written to `game/Loot/`: N/A
- Rarity appropriate for tier: N/A
- Floor rule applied (expedition/saga): N/A (skirmish has no floor rule; loot-drop=1 correctly resulted in no loot)

## Bugs Found

1. **Location file not updated on first entry**: CLAUDE.md specifies "玩家首次进入某地点 → 读 `game/World/locations/<loc>.md`，更新 `state: entered`" and filling `first_entered_by`. The ember-pass location file was never updated during the skirmish — `state` remains `unexplored` and `first_entered_by` remains `null`.

2. **No wandering-herbalist encounter**: The ember-pass location lists `inhabitants: ["[[wandering-herbalist]]"]` and "可能的遭遇" includes the wandering herbalist NPC. Over 5 turns no NPC encounter was triggered. Not necessarily a bug (it's "possible" not "guaranteed"), but worth noting the NPC system was untested.

3. **Damage amount not derived from dice**: The 4 HP damage from the wolf bite in turn 3 was assigned narratively rather than through a mechanical system. CLAUDE.md doesn't specify a damage formula, but this could lead to inconsistent damage across sessions. The GM chose the damage amount without a dice roll.

## Friction Points

1. **No damage system documented**: CLAUDE.md and the skirmish command don't specify how much damage enemies deal. The GM improvised 4 damage for a wolf bite, but there's no table or formula. This could vary wildly between sessions.

2. **`wounded` status effect unclear**: The character was given a `wounded` status in turn 3 but it had no mechanical effect. No rules exist for what status effects do beyond being labels.

3. **Herb pickup had no formal check**: In turn 2, the player picked up herbs as part of their action. The perception check in turn 1 revealed them, but no separate check was required to grab them. Minor — feels natural in play, but could be inconsistent.

4. **End-of-turn options for skirmish**: The options shown were `行动 · 对话 · 观察` per spec, but talking to wolves doesn't really make sense. The spec says skirmish options are fixed, so this is by design, but it felt slightly odd.

## Positive Observations

1. **Dice system works smoothly**: The SHA-based deterministic dice produce varied results. Getting both low (4) and high (19) rolls across 5 turns felt natural and created real tension.

2. **Narrative restraint is effective**: The 3-6 sentence limit forces concise, evocative prose. The standoff at the end (turn 5) was particularly good — minimal words, maximum tension.

3. **Commit-per-turn creates auditable history**: Every turn is a discrete git commit with a new SHA. This means any roll can be verified after the fact. Good design for trust.

4. **Character creation is fast and flavorful**: Rolling attributes from SHA, getting a rare class (Mist-Bound), and generating a 3-sentence origin took under a minute. The origin story ("burnt the boat, walked into the mountains") felt earned despite being auto-generated.

5. **Creative player actions rewarded**: Using the herbs offensively (turn 4) was rewarded with a Luck check, showing the system can handle improvised actions gracefully.

## Raw Notes

- Character: 沈渡, Mist-Bound, b2/m3/e2/l4, HP 12
- SHA rotation: 5a34307 → c78bbe1 → 3f1218b → bfededc → 7ff6d27 → 14cd8dc (all unique, confirmed)
- Rolls: 17(perceive), 11(talk), 4(attack), 8(defend), 19(save), 14(attack), 8(perceive) — good spread
- Turn 3 was the most dramatic: double failure, took damage. Felt like a real setback.
- Turn 4 reversal felt earned — creative use of environment + good roll.
- Turn 5 restraint: player chose not to pursue. GM handled this gracefully as a perception/standoff rather than forcing combat.
- Skirmish pacing is good at 5 turns — enough for a story arc (setup, escalation, crisis, reversal, resolution).
- No loot on d20=1 is correct for skirmish tier (no floor rule). Feels slightly anticlimactic but rules-correct.
- The `readme-update.sh` script ran without issues on both character creation and skirmish end.
- Edge case NOT tested: `/rest` during skirmish (should be refused), death/permadeath, NPC dialog with `「」` marks.
- The Mist-Bound class +1 luck was applied correctly (base 3 → 4).
- Attribute derivation formula `((d-1) % 5) + 1` applied correctly for all four attributes.
