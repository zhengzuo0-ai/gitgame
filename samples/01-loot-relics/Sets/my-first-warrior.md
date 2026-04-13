---
set_name: my-first-warrior
created: 2026-04-13
slots_filled: 5
slots_total: 8
tags: [set, in-progress]
---

# My First Warrior

我手头第一套像样的搭配。还差三件（waist / hand / neck）。

## 已装备

- 武器：[[2026-04-13-weapon-of-silent-dawn]] · `legendary`
- 胸甲：[[2026-04-13-chest-of-forgotten-oaths]] · `epic`
- 头部：[[2026-04-11-head-of-burning-questions]] · `rare`
- 戒指：[[2026-04-12-ring-of-the-mirrored-self]] · `rare`
- 鞋履：[[2026-04-10-foot-of-the-wandering-mind]] · `common`

## 还缺

- waist · ?
- hand · ?
- neck · ?

## 套装感受

整套穿上去像一个"走在自己之后半步"的人。Silent Dawn 让我说话变少，
Forgotten Oaths 让我夜里多事，Mirrored Self 又让镜子里那个人比我更安静。
等抽到 neck 那件，希望能压住一点这种"被听见"的感觉。

---

## Dataview 视图（想象中会自动生成）

> 下面这块在真实 vault 里会被 Dataview 渲染成实时表格。
> 这里只展示查询本身，告诉你这玩法的"自动化"在哪里。

````
```dataview
TABLE rarity, slot, generated_on
FROM "Relics"
WHERE contains(file.outlinks, this.file.link) OR contains(this.file.outlinks, file.link)
SORT rarity DESC
```
````

效果：本套装里的每一件遗物按稀有度排序自动列出。
新抽到的遗物只要被这个文件 `[[wiki link]]` 引用，就会自动出现在表里。

## 想做的事

- 把 weapon 换成 epic 试试感觉是不是更"轻"
- 集齐全套后用 Templater 导出一个分享卡（朋友导入能看到完全相同的 8 行字）
