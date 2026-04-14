# gitgame 全方面评审 · 2026-04-14

基于一次 75 回合的自主游戏（薛迟弧 · 见 `samples/04-xue-chi-arc/`），从**游戏设计师**、**游戏测试师**、**开发人员**三视角出具的综合评审。

> 本文是给 owner 的决策材料，不是给玩家的文档。改动建议都附了 ROI 评估。

---

## A. 游戏设计师视角

### A.1 核心循环诊断

**当前核心循环**：`角色 → 选地点 → 掷骰 → 叙事 → 拿 Loot → 打 XP → 可能死`

这个循环优雅，但**每一步都缺少让玩家投入的钩子**：

1. **角色塑造层薄**。薛迟是"第七旗老兵"、Ashen Soldier、HP 11。这三条信息里只有第一条指向一个故事；class 和 HP 是机械数据，不推动玩家产生情感。对比 Disco Elysium 的角色表——那不是能力数值，是**人格碎片**——每一项都暗示一种失败的方式。gitgame 的角色卡应该包含至少一个**冲突点**（例："她不能原谅自己没死"、"他每天要默数一次那三十六人"）。

2. **地点是舞台，不是角色**。location 文件只有"已知信息"和"出入口"。Good locations have memory——雪山记得谁死在山脊，灯塔记得谁最后一次点亮它。薛迟重返北驿三次，每次都是"废驿站"；它本该因为他的到来而**轻微变化**——窗沿上留下他取笔记时的划痕、告示板上多了一张他没看见的便条。

3. **机械系统和叙事系统不对话**。cold-light 给 Edge -1，但叙事里从不提"薛迟手在抖"、"靴子还是湿的"、"把手藏进袖子"。机械效果应该**在每次相关判定前出现一句叙事提示**，让玩家感觉"是的，这个 -1 是有代价的"。

### A.2 叙事结构观察

**Saga 是这套系统的最佳 showcase**——40 回合 + 4 章 + boss 回合的结构给足了空间让故事有**起承转合**。灰营 saga 的成功元素：

- 一个活着但沉默了三年的老兵（霍无声）
- 一个未成年的信使（沈雀）
- 一个正在被杀害的知情人（郑绾）
- 一个比主角更有权力的对手（南境总督/内务省）

这些角色**在叙事之前就存在于世界里**，他们**不为主角等**。主角只是撞进了一场已经在进行的事。这是好 RPG 写作的标志。

**Expedition（15 回合）是最薄弱的格式**。弓石镇那场有 15 回合的篇幅，但高潮（回合 14 接触郑绾）被双失败瞬间消解。在 skirmish 里失败是"这场冒险没拿到装备"；在 saga 里失败是"这一章可以救回来"；但在 expedition 里一次关键失败意味着整场白费。需要**中段检查点**让 expedition 有可挽回空间。

### A.3 永死机制的情感经济

永死是 gitgame 的核心承诺，但**我没有体会到永死的威胁**。原因：

- 40 回合 saga 死亡概率约 22%，但薛迟从未跌破 HP 8/11
- 每次 cold 加重或受伤，叙事上是损失，但**下一次 rest 一切重置**
- 结果：永死是一个悬在头顶的理论，但每一次具体冒险都像"有惊无险"

**改进方向**：永死应该通过**无法通过 rest 清除的东西**来成为持续威胁。建议（此轮已落地部分）：

- **疤痕（scars）** [已落地]：永久降低一个属性或 HP max。10% HP 事件（跌破 max/3）触发 Luck 掷骰，失败加 scar。
- **声誉（notoriety）** [已落地]：每次在镇上被看见、每次官府见到面孔，加 1 点。到阈值触发通缉事件链。
- **心理伤（mind-scars）** [未落地]：目击特定场景（同伴死亡、灭口、背叛）会加一个永久 status，影响特定判定类型。

这三条能让"活下来"不再是终点，而是**变老、变伤、变得越来越难生存**的过程。黑色奇幻的核心是积累而不是重置。

### A.4 玩家代理感的缺失

自主模式下 GM 做了 75 回合但玩家没做任何决定。即使在有玩家的模式下，回合末的 3 选项也**往往只是同一个动作的三种表达**（"走进去"/"绕到后面"/"先观察"）。真正的代理感来自**不可逆的分叉**：

- 选 A：永久关闭 B 和 C
- 选 A：让某个 NPC 死亡/活下来
- 选 A：新增一个永久 status

目前的 3 选项更像菜单式选择，不是**命运分叉**。

---

## B. 游戏测试师视角

### B.1 发现的 Bug / 违规

**B.1.1 每回合 commit 规则被违反**
- 文件：`game/Expeditions/2026-04-14-xue-chi-south-marches-circuit.md`
- 事件：turns 2-6 合并成了一个 commit（`585b45a`）
- 根因：批处理思路与 SHA 熵规则冲突。GM 想加快节奏时倾向合并相似回合
- 后果：`dice.py` 在 turns 2-6 之间的 SHA 未轮转；实际骰点基于 turn 1 之后的 SHA 一次性生成——对玩家而言无法分辨，但对审计者是漏洞

**B.1.2 turns YAML 字段在 saga 进行中从不更新**
- 文件：`game/Expeditions/2026-04-14-xue-chi-ash-camp.md`
- 事件：`turns: 0` 写入头部 YAML 后，40 回合全程没更新，直到结算才改成 40
- 后果：中途退出时的断点字段失效

**B.1.3 `xp_to_next` 升级后手动设置**
- 文件：`game/Characters/xue-chi.md`
- 事件：薛迟升二级后 `xp_to_next: 300 → 500` 是拍脑袋的
- 根因：CLAUDE.md 未定义升级公式 [已落地规则]
- 后果：不同 GM 会给不同值，角色进度不可复现

**B.1.4 `chapter N` 章节保存的 commit message 格式**
- 约定：saga 每 10 回合 `git commit -m "saga chapter N: <title>"`
- 实际：chapter 4 未单独提交，合并在了 "saga resolution" 里
- 后果：断点检测脚本会找不到 chapter 4 的 git tag

**B.1.5 DC 边界语义不一致**
- CLAUDE.md 对"持平算 NPC 赢"只在对抗判定规定
- 实际判定：采用了 strict greater than（total = DC 为失败）
- CLAUDE.md 未明确，下一个 GM 可能不同判定

**B.1.6 战利品 Loot 格式与模板不一致**
- CLAUDE.md 指定的 8 行格式：`Name / "of ..." / [Attr] / {Material} / + / - / ~ / ‡`
- 旧 `generate-loot.py` 输出的格式不符合这个规范
- 结果：玩家无法审计 Loot 属性

**B.1.7 `last_seen_at` / `last_rested` 字段未在 schema**
- `/rest` 依赖 `last_seen_at` 但角色卡 YAML schema 没列 [已落地 schema]

### B.2 体验问题（不是 bug 但影响好玩度）

**B.2.1 自主游戏缺少"玩家时刻"**
- 整场 75 回合无玩家决策点
- 没有"要不要 push my luck"的时刻——GM 知道后续骰点也知道后果
- 自主模式应该引入**纯随机决策**：关键分叉处用 Luck 骰决定选 A 或 B

**B.2.2 金币经济缺位**
- 薛迟一路保持 3 金币，无消费场景
- 打完 4 个冒险没捡到金币
- `gold` 字段等于装饰

**B.2.3 inventory 膨胀**
- 薛迟最后持有 10 件物品，全是"某种旧物"
- 没有装备差异化，没有"用哪件"的选择
- 物品应该有**在判定中的具体加成**才有"带上哪三件"的意义 [已落地 mechanical 字段]

**B.2.4 NPC 的"一次性"感**
- 霍无声、沈雀、郑绾都是为剧情量身打造的 NPC
- 离开这场 saga 后他们是否还存在、能否重访、会不会主动再出现——规则没定

**B.2.5 世界地理模糊**
- south-marches-village → ember-pass → south-marches-circuit 距离多少？
- 去弓石镇是"两天"、去行台是"一夜"——都是临时拍的
- 没有统一地理尺度，时间消耗就是叙事方便数

**B.2.6 信息密度衰减**
- Saga 前 20 回合每回合都在揭示新东西
- 后 20 回合进入"重复既有元素+小变化"模式
- Expedition 之间的**回合质量**在下降

### B.3 回归风险

如果有人未来改 `dice.py`、`generate-loot.py`、或 CLAUDE.md，最容易隐性破坏的：

1. **SHA 熵源**：如果 commit 消息格式改了（甚至换了 GPG 签名），后续骰点会变。现有的 `Expeditions/` 记录将不再能重新推导骰点，审计链断
2. **Loot 生成种子**：一旦随机算法调整，旧角色卡 `inventory` 引用的 slug 可能无法复现
3. **locations 的 exits 图**：增加新地点没追加反向边，世界图会不对称。`gong-shi-town → south-marches-village` 是手动追加的，容易漏

---

## C. 开发人员视角

### C.1 速度和成本

**用户反馈："每次思考和加载都很慢。"**

**C.1.1 上下文膨胀**
- 每轮需读入：CLAUDE.md (450 行) + MEMORY.md + 当前角色卡 + 当前 expedition log + 引用的 loot/npc/location 文件
- Saga 进行到第 30 回合时，expedition log 本身已有 400+ 行
- 每次生成一回合都要在心里 replay 整个上下文——天然就慢

**改进建议**：
- Expedition log **分段存档**。saga chapter 1-4 各自独立文件，主文件只留 TOC + 指针
- 角色卡保留精简版（HP/status/last_5_key_events），详细历史移到 `game/Characters/<slug>/history.md`
- CLAUDE.md 拆成 `RULES.md`（机械规则）+ `STYLE.md`（文风）+ `COMMANDS.md`（命令列表）

**C.1.2 Tool call 数量**
- 每回合 commit 需要：Edit expedition → Bash dice × 2 → Edit character → Bash git add/commit →（偶尔）Write loot
- 2-3 回合 ≈ 10+ tool calls，每个 tool call 有固定延迟

**改进建议**：
- 把"一回合结算"封装成 `turn-resolver.sh`，接收 JSON（dice results + narrative），一次调用完成所有文件更新 + commit
- 引入 `batch-commit.sh`，让 GM 声明式地说"这三回合是过场"——同时保持 SHA 熵规则的审计痕迹

**C.1.3 Loot 生成器的二次加工** [已落地 --write 模式]
- 旧流程：`generate-loot.py` 输出到 stdout → 手动 Write 文件 → 手动 Edit 加 acquired_at/from → 追加叙事段
- 新流程：`generate-loot.py --write --acquired-from <loc>` 直接落盘

### C.2 工具链缺陷

**C.2.1 dice.py 的 label 命名空间没有校验**
- 规则说同回合重复 label 自动追加 `-2`
- 但 `dice.py` 本身不知道历史 label——它只根据 `SHA + turn + label` 算哈希
- GM 必须自己记忆 label 使用过没有

**改进建议**：加 `label-log.txt`，每次执行 append 一行 `<turn>\t<label>`，重复时提醒

**C.2.2 没有 `/state` 命令** [已落地]
- 需要快速看：当前在哪、HP 多少、还有哪些 in-progress 冒险
- 现在要自己 ls + cat

**C.2.3 commit message 风格不统一**
- `turn 7: 踢中铜盆，险被守卫察觉`
- `turn 28: [风暴之眼] 内务巡察伏击，左肋受伤 HP 11→8`
- `saga chapter 3: 证词`
- `rest: 薛迟 recovered at south-marches-village`

语法不一致。未来 `git log` 机器解析会困难。

**改进建议**：CLAUDE.md 补一个 commit message 的 BNF

**C.2.4 MEMORY.md 从头到尾没用上**
- 所有信息都在 game/ 下
- MEMORY.md 没有"必要角色"
- 重复制造了两套持久化层——MEMORY（会话级）和 game/（项目级）

**改进建议**：明确 MEMORY 的职责（玩家偏好、不属于世界的元信息）或彻底删除

### C.3 关键改进清单（按 ROI 排序）

| 优先级 | 项目 | 预期收益 | 实施难度 | 状态 |
|---|---|---|---|---|
| P0 | `generate-loot.py --write` | 每件 loot 省 3 次 edit | 小 | ✅ |
| P0 | Loot `mechanical` 字段 | 装备有意义 | 小 | ✅ |
| P0 | 升级机制规则 | 玩家感受进步 | 小 | ✅ |
| P0 | `/state` 命令 | 快速查状态 | 小 | ✅ |
| P0 | Scar / Notoriety schema | 永死威胁感基础 | 小 | ✅ schema |
| P1 | `turn-resolver.sh` 一次调用结算 | tool call 数减半 | 中 | ⏳ |
| P1 | 角色卡历史分离 | 上下文减重 50% | 中 | ⏳ |
| P1 | Expedition 章节制（每 5 回合存档） | 失败可挽回 | 中 | ⏳ |
| P1 | Scar 触发机制代码化 | 不靠 GM 记 | 小 | ⏳ |
| P2 | Notoriety 效应集成到判定 | 被 DC+1 真正发生 | 中 | ⏳ |
| P2 | MEMORY.md 职责明确化或删除 | 降低认知负担 | 小 | ⏳ |
| P2 | 金币消费场景（商人 NPC） | 经济循环完整 | 大 | ⏳ |
| P3 | NPC 生命周期（离开后继续存在） | 关系持久 | 大 | ⏳ |
| P3 | 地理尺度统一（小时/天） | 时间一致 | 中 | ⏳ |
| P3 | 玩家代理感（命运分叉选项） | 回合末 3 选项有重量 | 大 | ⏳ |

### C.4 具体能马上做的：慢的问题

用户反馈"思考和加载很慢"。最直接三个根因 + 解法：

1. **每回合读整个 expedition 文件**：改成只 `Read(file, offset=total-50)`。**立刻生效**
2. **Loot 生成后多步 edit**：`generate-loot.py --write` [已落地]
3. **Saga 期间的长上下文**：40 回合的 saga 第 35 回合时主文件已 600+ 行被反复引用。引入章节分文件。**一天工作**

---

## 结语

gitgame 最核心的设计洞察是**把 git 当成游戏状态机**——把一个本身就是"历史+作者+分支"的工具对齐了一个本身就是"记录+选择+永久"的游戏类型。这个契合度很高，应该守住。

但它目前是一个**只为玩家展示机械规则的游戏**，不是**一个玩家能在里面住进去的世界**。差距在：世界对玩家的持续记忆、NPC 的生命周期、装备和金币的意义、永死的累积威胁。

owner 接下来三周的路线图建议：

**第一周**：工具链减速（让一回合从 10 秒变成 2 秒）+ 升级机制 + Loot 属性化 [本轮大部分已落地]
**第二周**：Scar/Notoriety 完整集成 + Expedition 章节制
**第三周**：NPC 生命周期（离开后继续存在，可重访，可死亡）

做完这三周，gitgame 就从"一个有趣的 demo"变成"一个可长期运营的世界"。

---

*本评审基于 2026-04-14 的一次 75 回合自主游戏。commit 链从 `fc255c8` 到 `3a109df`（94 commits），sample 归档见 `samples/04-xue-chi-arc/`。*
