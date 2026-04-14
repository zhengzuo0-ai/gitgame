# gitgame

> 在 git 仓库里玩的永死文字冒险。  
> commit 是动作，SHA 是骰子，tag 是墓碑。

由 Claude Code 作 GM，三档时长（`/skirmish` 3 分钟 / `/expedition` 30 分钟 / `/saga` 60 分钟）。
角色永久死亡 — 死了就进 `game/Graveyard/`，再也不回来。

---

## 在世英雄

<!-- ALIVE -->
_(无人在世。`/roll-character` 开始新人生。)_
<!-- /ALIVE -->

## 已逝者

<!-- FALLEN -->
_(无人殒命。)_
<!-- /FALLEN -->

---

## 怎么玩

1. 把仓库 clone 到本地
2. `cd` 进去，启动 Claude Code
3. Session 开头会打招呼：在世 / 已逝 各几位
4. 没有在世角色 → `/roll-character` 孵化一位
5. 有在世角色 → `/skirmish <地点>` 出门打一场 3 分钟的

### 命令速查

| 命令 | 时长 | 回合 | 危险 |
|---|---|---|---|
| `/roll-character` | 一次 | — | — |
| `/inventory` | 即时 | — | 只读 |
| `/rest` | 一次 | — | — |
| `/skirmish <loc>` | 3 分钟 | 5 | 低 |
| `/expedition <loc>` | 30 分钟 | 15 | 中 |
| `/saga <loc>` | 60 分钟 | 40 | 高 |
| `/graveyard` | 即时 | — | 只读（死亡由别处触发） |

### 初始地点

- [[south-marches-village]] · 基地，`/rest` 触发处
- [[ember-pass]] · 狼群、商队遗骸 — `/skirmish` 友好
- [[crypt-of-mist]] · 守墓人 Lyra、空石棺、被刮掉的符文 — `/expedition` 目标

---

## 骰子是真的随机

每次判定的 seed = `<当前 HEAD SHA>:<回合数>:<label>`。
玩家可以 `git log` 查到每回合的 SHA，`python3 .claude/scripts/dice.py <SHA> <turn> <label>` 复算，必得同样的点数。
**GM 不能编骰点。**

---

## 永久死亡是铁律

HP ≤ 0 的瞬间：
1. 角色文件 `git mv` 到 `game/Graveyard/`
2. Claude 生成 80-120 字墓志铭追加到文件末尾
3. `git tag death/<slug>`（第二道锁 — revert 不会删 tag）
4. README 的"已逝者"自动更新

**不能复活。** CLAUDE.md 明文禁止 Claude 读 Graveyard 用于任何"绕过死亡"的目的。

---

## 仓库结构

```
CLAUDE.md                      # GM 规则书 (Claude 每次会话自动读)
README.md                      # 本文件
.claude/
  commands/                    # 7 个 slash command
  hooks/session-start.sh       # 进会话时打招呼
  scripts/
    dice.py                    # 确定性 d20
    generate-loot.py           # 确定性战利品生成器
    readme-update.sh           # 同步在世/已逝到 README
    loot-seeds.json            # 20 prefix × 20 suffix × 15 attr
game/
  Characters/                  # 在世角色
  Graveyard/                   # 死者，不可变
  Expeditions/                 # 每次冒险的对话日志
  Loot/                        # 8 行 Loot 格式战利品
  World/
    locations/                 # 地点卡
    npcs/                      # NPC 卡
  Journal/turns.log            # append-only 骰记录（审计用）
docs/superpowers/plans/        # 实施计划
samples/                       # 早期概念展示厅（保留，只读）
tests/                         # dice + readme-update 单元测试
```

---

## 历史

这个项目从"在 Obsidian 里玩的纯文字游戏"概念出发，走过 4 轮迭代：

1. 研究 Loot Project / Claude Buddy / Obsidian 生态 → `samples/`
2. 意识到 Obsidian 单机样例不够好玩 → 决定换成 Claude Code
3. 确定核心体验：永死 AI GM 冒险 + 3 档时长
4. 用 gstack / superpowers / autoresearch 三个 skill 工作流落地

过程记录在 `/root/.claude/plans/fluttering-baking-moonbeam.md`。
