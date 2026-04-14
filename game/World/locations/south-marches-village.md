---
type: location
slug: south-marches-village
region: South Marches
danger: 0
state: safe
tag: safe
inhabitants: ["[[innkeeper-brann]]"]
exits: ["[[ember-pass]]", "[[crypt-of-mist]]", "[[north-relay]]"]
first_entered_by: null
first_entered_on: null
tags: [location, base]
---

# 南境边村

> *South Marches · 安全基地 · 危险 0*

## 已知信息

- 南境官道尽头的小村，不在主流地图上
- 只有一家客栈、一眼井、一条没人修的石墙
- 客栈店主是 [[innkeeper-brann]]，知道所有路过的人的面孔
- 村里没人提起北边的 [[crypt-of-mist]]，但所有人都知道它在哪里

## 作为基地

- `/rest` 在此触发：HP 回满、清除临时状态
- 临时物品交易（未来实现）：innkeeper 收/卖低阶物资
- 基地 NPC 会记住每一个从 [[crypt-of-mist]] 回来的人——包括他们回来时缺了什么

## 出入口

- [[ember-pass]] · 东北方向，一天脚程，路过狼群 territories
- [[crypt-of-mist]] · 北方向，半天脚程，雾常年不散

## 鉴定规则

- 任何进入此地的角色，`status` 里的 `bruised` 会在描述中被 innkeeper 注意到
- 如果角色有 `mist-touched`，innkeeper 不会问他在北边做了什么
