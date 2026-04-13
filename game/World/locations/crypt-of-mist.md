---
type: location
slug: crypt-of-mist
region: South Marches
danger: 3
state: unexplored
inhabitants: ["[[lyra-the-keeper]]"]
exits: ["[[south-marches-village]]"]
first_entered_by: null
first_entered_on: null
tags: [location, dungeon]
---

# 雾之墓室

> *South Marches · 地下墓穴 · 危险 3 · expedition 目标*

## 已知信息

- 入口在 [[south-marches-village]] 北方半天脚程的山脚
- 台阶向下没入乳白色的雾里——不是雾，更像**记不清自己原本是什么**的水
- 门楣上原本有三个符文，**第三个最近被人用凿子刮掉**
- 村里无人主动提起，但所有人都知道它的方向
- 守护者：[[lyra-the-keeper]]

## 内部规则

- 第一次进入时，任何角色必定触发 `mist-touched` 状态（永久）
- 中央圆形墓室有一具**敞开的**石棺
- 棺内会出现物品（SHA 决定内容），取走 = 失去一段记忆
- [[lyra-the-keeper]] 不阻止取走，也不解释代价
- **可归还** — 把物品还回石棺，[[lyra-the-keeper]] 会记住

## 作为 expedition 目标

- 回合数中等（8-15 回合），死亡概率 ~15%
- 典型战利品：1-2 件 rare，偶见 epic
- 谜题层面：凑齐被刮掉的符文需要多次进入（跨角色累积）

## 出入口

- [[south-marches-village]] · 半天脚程
- 未知出口（传闻石棺下方有甬道，未经证实）

## 永久状态

- `mist-touched` · luck 判定 -1、未来面对雾时触发记忆回响
- `lyra-recognized` · 第二次见到 [[lyra-the-keeper]] 时她会说"你回来了"

## 跨角色的持久变化

- 如果某个角色把物品**还给**石棺，一周内该物品不再掉落
- 被刮掉的符文的痕迹每次 `perceive-door` 成功时暴露一些，成功 3 次后玩家知道它是什么字
