# 方向 1 — Vault of Relics

> 每天在 vault 里**抽取 / 合成 / 展示**一件确定性生成的文字遗物。
> 灵感源自 Loot Project（2021）的 8 行纯文本装备。

## 玩家一天的体验

```
打开 Obsidian
  ↓
点击 Templater 按钮：/draw
  ↓
基于（你的 vault ID + 今天日期）FNV-1a 哈希
  → 决定 slot（武器/护甲/戒指/...）
  → 决定 rarity（common ~ legendary）
  → 决定一个"骨架"种子（决定基础名字模板）
  ↓
（可选）调用 Claude 生成 50 字风味文字
  ↓
落到 /Relics/2026-04-13-<slot>-of-<name>.md
  ↓
打开 /Sets/ 拼装套装、用 Dataview 看收藏
```

**关键性质**：同一个 vault + 同一天 → 必然抽到同一件遗物。换 vault 或换日期就完全不同。
社区可以基于同一种子规则做"今天大家都抽到了什么"页面。

## 这个目录里有什么

- `Seed.md` — vault 种子文件（演示哈希逻辑）
- `Relics/` — 5 件示例遗物，覆盖不同稀有度
  - 1 legendary、1 epic、2 rare、1 common
- `Sets/my-first-warrior.md` — 用 wiki link 把遗物拼成套装 + 一段 Dataview 查询示意

## AI 在哪里？

**几乎不在**。玩法主体是确定性哈希；Claude 只在你想要"鉴定 / 写风味文字"时被调用一次。
关掉 AI 也能玩——你拥有的是**收藏**，不是**对话**。

## 为什么这个方向有意思

- **离线、零成本、可 Git 同步**：遗物文件是真正的资产
- **bottom-up 二创空间最大**：别人可以基于同一格式写自己的"扩展包"（新 slot、新词表）
- **MVP 最快**：1–2 周就能跑通

## 风险

- 单机玩法循环短——没有"打怪、变强"的目标
- 强依赖社交层（互看收藏、交易、合成挑战），第一版就需要想清楚怎么"分享"

## 想象中的下一步

1. 写 Templater 脚本实现 `/draw`（FNV-1a + 词表）
2. 写 Dataview 查询：rarity 分组、slot 缺什么、套装完成度
3. 设计"合成"规则（4 件 common 换 1 件 rare？）
4. 设计"分享"格式（导出一个套装的 markdown，朋友导入能看到一样的字）
