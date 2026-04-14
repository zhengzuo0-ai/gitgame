---
description: 60-minute epic. Max 40 turns. DC 14-20. Chapter saves every 10 turns. 2-3 loot with epic/legendary chance.
---

# /saga

Arguments: $ARGUMENTS — location slug. Required.

## Differences from /expedition

Read `expedition.md` first. The deltas:

- **Max turns: 40**.
- **DC range: 14–20**. Even trivial rolls in a saga tend toward 13+.
- **Death probability**: ~35% (compared to ~15% for expedition, ~5% for skirmish). The Saga is **dangerous**.
- **Boss turn**: at least one designated "boss turn" mid-saga. On this turn, any damage dealt **doubles**, and any failed save can knock HP in one roll from full to lethal. The GM declares the boss turn with a short line like `[风暴之眼]` before narrating it.
- **Cannot be interrupted by /rest** — but every 10 turns you must write a `## 章节 N` section and `git commit -m "saga chapter N: <title>"`. This is a **forced save-point**. If the player exits mid-saga, resuming means loading the last chapter's state.
- **Loot tier**: generous. Always use `generate-loot.py`; never hand-write the 8 lines.
  - `loot_d20 = bash .claude/scripts/py.sh .claude/scripts/dice.py $SHA 999 loot-drop`
  - 1..3   → 1 uncommon (saga floor: even bad rolls give *something*; rumor too if narratively appropriate)
  - 4..12  → 2 items (mix of uncommon + rare)
  - 13..18 → 2 items, at least 1 rare, maybe epic
  - 19..20 → 1 legendary ★ (rare event, write epic flavor)
  - Each item: `bash .claude/scripts/py.sh .claude/scripts/generate-loot.py $SHA 999 <idx> <rarity>` →
    write `game/Loot/<slug>.md` + `acquired_at` + `acquired_from`, append to `inventory`.
- **XP**: per CLAUDE.md formula. Saga turns + many successes + many discoveries → typically 180–420.
- **Location unlocks**: always 1, often 2. Plus a **plot hook** (a new NPC or a 1-line rumor about a distant location) — write as `game/World/rumors/<slug>.md`.

## Chapter save structure

At turn 10, 20, 30, write:

```markdown
## 章节 <N>: <chapter title>

**状态快照** (turn <N>):
- HP: <hp>/<hp_max>
- 状态: <status>
- 本章节发生: <2 sentences>
- 下一章悬念: <1 sentence>
```

Then: `git add -A && git commit -m "saga chapter <N>: <title>"`.

## Saga-specific design notes

- Sagas should feel like **novellas** — pacing matters. Don't let every turn be combat.
- A typical pacing: ch1 set-up + discovery, ch2 travel + one encounter, ch3 climax + aftermath, ch4 (if reached) resolution.
- The boss turn is usually in chapter 3. But in a cruel saga, the GM can call it earlier without warning.
- Saga completion with the character alive is **rare and memorable**. Treat it accordingly in the final narration.

## Permadeath caveat

Permadeath is still iron law. A saga death is more narratively valuable than a skirmish death — the墓志铭 should reflect everything the character went through. But **do not adjust the judgment** because "it would be sad to die here". The dice decide.
