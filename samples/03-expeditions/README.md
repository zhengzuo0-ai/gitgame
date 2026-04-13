# 方向 3 — Obsidian Expeditions

> 每次"出门探险"是一场**与 Claude GM 的真实会话**。
> 战斗、对话、抉择、战利品——全部实时落地为 vault 里的 MD 文件。
> 死了就归档成英雄墓志铭，重开下一位。

## 玩家一次出门的体验

```
打开 Obsidian + Claude Code
  ↓
（首次）/roll-character → 哈希生成职业 + 初始属性 → /Characters/<name>.md
  ↓
/expedition <地点>
  ↓
Claude 读取：
  - 角色卡（HP / 装备 / 等级）
  - 地点笔记（场景描述、可能的 NPC、危险等级）
  - 世界大事年表（保持连续性）
  ↓
GM 描述场景（300–500 字）
  ↓
玩家输入行动 → GM 判定（哈希骰，可审计） → 叙述结果
  ↓
（循环 5–20 轮）
  ↓
会话结束时 Claude 自动：
  - append 完整对话到 /Expeditions/<日期>-<地点>.md
  - 更新角色卡（HP / XP / 装备 / 状态）
  - 生成战利品文件（复用方向 1 的 Loot 格式）→ /Loot/
  - 把 NPC / 新地点写到 /World/
  ↓
（如果死了）
  - 角色归档到 /Graveyard/
  - 自动生成墓志铭（LLM）
```

## 这个目录里有什么

- `Characters/aric-the-bold.md` — 角色卡，YAML 含 hp / level / xp / 装备槽
- `Expeditions/2026-04-13-crypt-of-mist.md` — 一次完整冒险的对话日志，含哈希骰记录
- `Loot/*.md` — 这次冒险颁发的两件战利品（注意：和方向 1 是**完全相同的 Loot 格式**）
- `World/locations/crypt-of-mist.md` — 地点笔记
- `World/npcs/lyra-the-keeper.md` — 这次遇到的 NPC
- `Graveyard/README.md` — 死亡角色归档说明

## AI 在哪里？

**核心、高频、深度参与**。
- 全程 GM：场景、对话、判定叙事、NPC 人格
- 哈希骰：保证可审计——任何人拿到种子能复算骰点（叙事不能复算，这是设计）
- 会话结束总结：把零散的对话压成"世界笔记"+"战利品"+"角色更新"

## 为什么这个方向有意思

- **游戏性最强**：清晰的"出门 → 战利品 → 变强 → 再出门"循环
- **充分发挥 Claude 长文本叙事能力**：单 vault 里能跑出一个连续的英雄列传
- **天然包含方向 1**：战利品就是 relic，所以这条路也包含了 Loot 的玩法
- **天然可包含方向 2**：基地 NPC 可以是个 Familiar，出门归来时迎接你

## 风险

- **工程量大**：MVP 至少 4–6 周
- **跨会话一致性是经典难题**：NPC 人设漂移、世界设定遗忘
- **AI 成本高**：每次会话几千到几万 token
- **与 Claude-Code-Game-Master 等已有 AI DM 工具有重叠**——差异化护城河靠"MD 一级存档 + Loot 子系统 + Obsidian 原生 UI"

## 想象中的下一步

1. 设计角色卡 schema（多职业？技能树？还是只有"装备 + HP"极简化？）
2. 决定哈希骰怎么暴露（要不要让玩家看到种子？信任 vs 沉浸的 trade-off）
3. 设计世界笔记的"压缩 / 召回"机制（不能每次都把整个 World/ 喂给 Claude）
4. 第一个"小型本"（2–3 个地点 + 1 条主线）作为可玩 demo
