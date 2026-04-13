# 方向 2 — Codex Familiar

> vault 里住着一只**由你的笔记习惯喂养**的文字精灵。
> 它会读你最近的 daily note，以自己的口吻在末尾留一两句话，
> 长期陪你写作。灵感源自 Claude Buddy 的双层架构。

## 玩家一段时间的体验

```
首次打开 vault
  ↓
运行 /hatch
  ↓
基于 vault UUID 哈希
  → 决定 species（18 种之一，例如 "Dust Owl"）
  → 决定 rarity（1% legendary, ...）
  → 决定 5 个属性的初始值
  ↓
Claude 读这些骨架，生成名字 + 个性段
  ↓
写到 /.familiar/soul.md
  ↓
（之后每天）
  你写完 daily note → 文件 hook 触发
  → Claude 读 soul.md + 最近 3-7 天笔记摘要
  → 在 daily note 末尾追加精灵评论
  → 在 /.familiar/diary/ 写一段宠物视角的"今天主人怎么样"
  → 更新 mood / hp / bond
```

## 这个目录里有什么

- `.familiar/soul.md` — 精灵的"身份"：物种、稀有度、名字、5 属性、当前心情
- `.familiar/memories.md` — 重要事件 append-only 日志
- `.familiar/diary/2026-04-1[1-3].md` — 精灵视角的三天日记
- `Daily/2026-04-1[1-3].md` — 用户三天 daily note，**末尾分割线之后是精灵的评论**

打开 `Daily/` 里任何一天，滚到底部那条 `---` 分割线后，就是它今天对你说的话。

## AI 在哪里？

**核心、但低频**。
- 首次孵化：1 次 LLM 调用生成名字+个性
- 每天写 daily note 后：1-2 次调用生成评论 + 更新日记
- 主动 `/ask-familiar` 时：以宠物口吻回答你

它不是 GM、不推动剧情，是被动的陪伴者。

## 为什么这个方向有意思

- **情感粘性最强**：养成 + 长期记忆，符合 Obsidian 用户"笔记即生活"文化
- **市面真空**：没有同类产品
- **技术边界干净**：一只宠物、一组文件、单线运行

## 风险

- 强依赖 AI 质量——评论一旦无聊或重复，体验就崩
- 隐私敏感：精灵要读你的 daily note，需要明确边界（默认只读最近 3-7 天，黑名单标签可屏蔽）
- 没有失败条件，可能被觉得"缺紧张感"——但这正是设计：陪伴 ≠ 挑战

## 想象中的下一步

1. 写 SessionStart hook（Claude Code 端）：`hatch` / `feed` / `ask`
2. 设计 18 物种 + 词表
3. 实现"精灵会忘记很久没翻的笔记"的衰减机制（保护隐私 + 增加沉浸）
4. 探索"两只精灵相遇"的社交玩法（导出一份 soul.md 给朋友）
