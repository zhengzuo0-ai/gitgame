# Sample 04 — 薛迟 弧

这个 sample 不是规则示例，是一份**完整的玩家弧**：一位角色（薛迟，Ashen Soldier）从孵化到第 5 次冒险结束的全部留档。用来做什么：

1. 给新 GM 看一套**前后一致的世界**——10+ 件 Loot、8 个地点、4 个 NPC、4 条流言，彼此互相引用。
2. 给系统开发者看**每回合 commit 在 git 里长什么样**——真实的 commit 链、真实的 dice 种子、真实的 Saga 章节断点。
3. 给设计师看**黑色奇幻中端剧情**如何通过 75 回合逐步展开而不崩坏。

## 场景地图

```
crypt-of-mist  ←  south-marches-village  →  gong-shi-town
                  /      |      \
         ember-pass  north-relay  (rest base)
              |           |
      waypost-records   ash-camp ←(sealed by Huo Wusheng)
              |
     south-marches-circuit → [zhu-yan-vault] (未踏入)
```

## 弧线

1. **Skirmish → Expedition 北驿**：在告示板上取线索，井里取到副本文书，见黄铜纽扣
2. **Expedition 焰隘/记录所**：问出旗主之死真相，焰隘被狼困，走水巷
3. **Saga 灰营（40 回合 · boss）**：找到霍无声，得知解散令为伪造；找到沈雀，获「联络官证词」，内务巡察伏击受伤归村
4. **Expedition 弓石镇**：找到被调离的郑绾，但他已被监视，当面无法交换证词
5. **Expedition 南境行台**：潜入档房，对照原件与副本，发现「烛焰」密库代号，真件已被转移

## 关键数据完整性链

- 角色文件 `Characters/xue-chi.md` 的 `inventory` 数组，每一项都在 `Loot/` 下有对应文件
- 每件 Loot 的 `acquired_from` 指向一个在 `World/locations/` 里存在的地点
- 每个在世 NPC（`tags: [npc, alive]`）的 `known_to` 数组包含其记住的角色
- 每条 rumor 的 `source` 指向一个存在的地点

如果你在未来修改生成器或命令，可以把这 35 个文件当作一个**冒烟测试**——读一遍不应该出现孤立引用。
