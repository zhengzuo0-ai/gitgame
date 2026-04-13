---
date: 2026-04-13
character: "[[aric-the-bold]]"
location: "[[crypt-of-mist]]"
seed: 7f4a3c91-2026-04-13-exp
turns: 8
outcome: survived
loot_gained: ["[[shard-of-the-mist]]", "[[ringlet-of-cold-breath]]"]
xp_gained: 65
hp_lost: 6
new_status: [bruised, mist-touched]
tags: [expedition, survived]
---

# Expedition · The Crypt of Mist

> *Aric the Bold, 2026-04-13. Eight turns. He came back, but not all of him.*

---

**GM:**
你站在 [[crypt-of-mist|雾之墓室]] 入口前。台阶向下消失在乳白色的潮气里——
不是雾，更像是某种**记不清自己原本是什么**的水。
门楣上刻着三个字符，其中一个被刮掉了。
身后的村民已经走远，只有风。

**Aric:** 我蹲下，看那个被刮掉的字符的痕迹。

**GM:** `[Mind 4 + d20=11 = 15 vs DC 13]` 成功。
凿痕很新，不到一周。被刮掉的字符比另两个深——它是**这扇门真正的名字**。
有人不希望进去的人知道自己进的是什么。

**Aric:** 我下去。慢慢走，左手扶墙。

**GM:** 第十级台阶，雾没过你的腰。第二十级，没过胸口。第三十级，你听到水声。
你站在一间圆形墓室中央——但你看不到自己的脚。
墙边的石棺只露出顶端，棺盖是**敞开的**。
雾里浮着一个人形。她背对你。

她说："你来取它，还是来还它？"

**Aric:** "我不知道我有什么要还的。"

**GM:** 她转过来。她的脸是 [[lyra-the-keeper|你年轻时见过的某个老师的脸]]——
但你确定你从没见过她。`[Luck 3 + d20=4 = 7 vs DC 12]` **失败**。
你记不起来你是不是真的没见过她。
`status += mist-touched`

她伸手指向石棺："拿走里面的，留下你刚才差一点想起来的东西。"

**Aric:** 我走过去看石棺里。

**GM:** 棺里没有尸体。只有两件东西：
- 一把没有刃的**碎刃**，金属在雾里几乎透明
- 一圈细到几乎看不见的**项圈**，呼出的气会在它表面凝成霜

她站在你身后，没有动。

**Aric:** 我两件都拿。

**GM:** `[Edge 1 + d20=18 = 19 vs DC 15]` 成功。你拿起两件，雾没有阻止你。
但你把它们收进背包的瞬间，**听到了自己十二岁时哭着喊一个名字的声音**——
然后什么都不剩。
那个名字你**再也想不起来了**。

`HP -6`（不是受伤，是**少了**）
`Inventory += [[shard-of-the-mist]], [[ringlet-of-cold-breath]]`

她说："去吧。下次来，把它们带回来，或者不用了。"

**Aric:** 我转身上台阶，不回头。

**GM:** 风重新吹回你脸上的时候，你才发现自己一直没呼吸。
村庄的灯还亮着——但天已经暗了。你不记得自己在下面待了多久。

`Expedition end. XP +65. status: bruised, mist-touched.`
`Two relics added to inventory.`
`Lyra has been added to /World/npcs/.`

---

## 这次冒险给世界带来的改变

- [[lyra-the-keeper]] 现在记得 Aric 来过。下次相遇会有 `recognized` 标记。
- [[crypt-of-mist]] 的状态从 `unexplored` → `entered`。门楣的第三个字符被记录为 `(scratched, recently)`。
- Aric 失去了某段童年记忆——之后任何涉及"童年朋友"的判定都会触发空白。
