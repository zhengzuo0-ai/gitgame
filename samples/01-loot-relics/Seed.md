---
vault_id: 7f4a-3c91-2b88-de52
created: 2026-03-29
hash_algo: FNV-1a-32
---

# Vault Seed

这是这个 vault 的"身份证"。一旦设定就不再改变。

每天 `/draw` 时，会用以下输入做 FNV-1a 哈希：

```
seed_input = vault_id + "-" + YYYY-MM-DD
```

得到一个 32 位整数，然后：
- `hash & 0x7` → 决定 slot（8 个槽位之一）
- `(hash >> 8) & 0xFFFF` → 配合下表决定 rarity
- `hash >> 24` → 选择基础名字模板（从词表里挑）

## Rarity 分布表

| Rarity     | 概率   | 颜色（Obsidian tag） |
|-----------|------|--------------------|
| common    | 70%  | #rarity/common     |
| uncommon  | 18%  | #rarity/uncommon   |
| rare      | 8%   | #rarity/rare       |
| epic      | 3%   | #rarity/epic       |
| legendary | 1%   | #rarity/legendary  |

## 8 个 Slot

`weapon`, `chest`, `head`, `waist`, `foot`, `hand`, `neck`, `ring`

## 同种子可重放

任何人拿到这个 `vault_id` + 一个日期，就能离线复算出当天的遗物骨架。
**LLM 生成的风味文字不可重放**（这是设计：它是你的"灵魂签名"）。
