---
type: index
tags: [graveyard]
---

# Graveyard

死亡角色归档处。目前**空的**——[[aric-the-bold]] 还活着。

## 一个角色死亡时会发生什么

1. 角色卡从 `/Characters/` 移动到这里
2. Claude 自动生成 **墓志铭**（约 100–200 字，根据角色经历的 expedition 提取关键事件）
3. 角色装备的所有 relic 进入"遗物"状态——可被下一个角色继承（如果剧情合理）
4. 角色参与过的 NPC 会在世界笔记里更新 `remembers_dead: [name]` 字段

## 想象中的样例

```markdown
---
name: Vesper Quill
class: Lantern-Bearer
died_on: 2026-03-22
died_at: "[[hollowed-spire]]"
expeditions_survived: 7
final_words: "把灯留给下一个人。"
buried_relics:
  - "[[wick-of-unfinished-prayers]]"
  - "[[mantle-of-the-second-watch]]"
tags: [character, dead]
---

# Vesper Quill (2026-01-08 — 2026-03-22)

她在七次出门里没说过一句重要的话。
第八次，她说了——然后火灭了。
```

## 设计意图

死亡不是"游戏结束"，是**世界记得你的方式**。
墓志铭会被未来的 NPC 引用、被新角色在地图边缘看见、被你自己在某个深夜重读。

vault 里的死亡角色，是这个世界**真正的连续性**。
