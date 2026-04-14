# /state

Arguments: none

Quick read-only status dump for the active character and any in-progress adventure. Use this when the player asks "where am I?" or when the GM needs a one-screen summary.

## Steps

1. **Find alive character(s)**
   ```bash
   grep -l 'tags: \[character, alive\]' game/Characters/*.md
   ```

2. **For each alive character, print**:
   - `name` / `class` / `level` / `xp / xp_to_next`
   - `hp / hp_max` + any `status: [...]` entries
   - `last_seen_at` (location)
   - `inventory` item count
   - Most recent `expeditions_survived`

3. **Find in-progress expeditions**
   ```bash
   grep -l 'status: in-progress' game/Expeditions/*.md
   ```
   - Print file name, `tier`, current turn count (count `## 回合` headings minus saga chapter headings)

4. **Print last 3 commits** (for recent-context awareness)
   ```bash
   git log --oneline -3
   ```

5. **Output format** — keep it terminal-width friendly:

```
=== 薛迟 · Ashen Soldier · Lv 2 ===
HP 11/11   XP 249/500   Status: []
在 [[south-marches-village]]   5 次冒险过后
装备 10 件

无进行中冒险。

recent:
  e259042 turn 15: 县城遇捕快，面孔被记
  ed46f6c turns 13-14: 退档房、出外墙
  138bd3f turn 12: 登记簿见「烛焰」二字
```

## Style

- Read-only. Never writes files or commits.
- If multiple alive characters (shouldn't happen but future-proof), print each section separately.
- If zero alive, print `没有在世角色。` and suggest `/roll-character`.
