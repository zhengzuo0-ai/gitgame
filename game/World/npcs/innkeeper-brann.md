---
type: npc
slug: innkeeper-brann
location: "[[south-marches-village]]"
disposition: neutral-friendly
role: innkeeper
known_to: ["[[xue-chi]]"]
first_met_on: 2026-04-14
attributes:
  patience: 7
  insight: 5
  mercy: 6
tags: [npc, innkeeper, base]
---

# 酒馆老板 Brann

> *看似五十多岁，左手无名指的指节特别大*

## 形象

- 村里唯一一家客栈的老板，兼做饭、开门、关门
- 酒馆叫"只剩三张桌子"——从前有五张
- 面对陌生人先看手、再看眼、最后才开口
- 对从北边 [[crypt-of-mist]] 回来的人一律不问

## 对话风格

- 极少主动开口
- 称呼客人为"你"——从不问名字，除非你告诉他
- 句子短。"先睡。" "明早再说。" "那桌坐过人。"
- 开玩笑只用一个词的反问

## 功能（玩家交互）

- `/rest` 在此触发——HP 回满 + 清除临时状态
- 描述角色 `bruised` 等状态时，Brann 会在叙事里被动注意到（不必主动问）
- 如果玩家有 `mist-touched`，Brann 绝不提起北边
- 未来（不在 MVP）：交易低阶物资

## 记忆行为

- 每次玩家在此 `/rest`，append 一行到 `known_to` 字段
- 如果在世角色已死亡，Brann 会在下一位新角色进店时有一句"上一个从北边回来的，再没走出门"
