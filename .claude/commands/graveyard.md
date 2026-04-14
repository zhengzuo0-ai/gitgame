---
description: Permadeath ritual — archive a fallen character, generate epitaph, sync README, tag the grave. Forever.
---

# /graveyard

Arguments: $ARGUMENTS (optional — no argument = list all graves; `<slug>` = show specific grave)

## Two modes

### Mode A: Read-only — view graveyard

Triggered when called with no argument or with a slug to view.

1. `ls game/Graveyard/*.md` → if empty, reply "坟场尚空。" (graveyard is still empty).
2. If argument is a slug, read that file and display the character card + epitaph.
3. Otherwise, list each grave:
   ```
   [[<slug>]] · died <died_on> in <died_in> · killed by <killed_by> · turns survived <N>
     "<first line of epitaph>"
   ```
4. **Do not write anything.** This mode is pure reflection.

### Mode B: Burial — called automatically from skirmish/expedition/saga on HP ≤ 0

**This mode runs without user confirmation.** Permadeath is the rule; asking "are you sure?" violates it.

Steps (in order, do not skip):

1. **Write DEATH narrative to expedition log**
   - Locate the in-progress expedition file (YAML `status: in-progress`).
   - Append a `## DEATH` heading and ≤ 5 sentences describing the fall. Be precise about the angle, the last sensation, the last thing seen. **Do not** editorialize ("noble death" etc.). Just the physics of the ending.

2. **Move character card**
   ```bash
   today=$(date +%Y-%m-%d)
   slug=<character-slug>
   git mv "game/Characters/${slug}.md" "game/Graveyard/${slug}-died-${today}.md"
   ```

3. **Edit YAML of the moved file**
   - Change `tags: [character, alive]` → `tags: [character, dead]`
   - Add fields:
     - `died_on: YYYY-MM-DD`
     - `died_in: "[[<location-slug>]]"`
     - `killed_by: <specific cause — npc slug, trap kind, or environmental>`
     - `turns_survived: <turn number>`
     - `final_hp: <negative number; the overkill is informative>`
     - `last_words: "<≤15 中文字符>"` — what the character said or thought at the moment of death.
       Keep it concrete and short. Examples: `"我应该往左。"` / `"母亲。"` / `"原来是真的。"` /
       `"……"` (silence is allowed). **Hard cap 15 characters**, no exceptions. If they died
       too fast to think, write the last sensation in 15 chars: `"灯还在烧。"`.

4. **Generate epitaph**
   - Append a `## 墓志铭` section at the end of the file.
   - 80–120 Chinese characters. Written in third person, past tense.
   - Must reference at least one concrete detail from this character's expedition history (read `game/Expeditions/*` for this character). Not "英勇战斗" — something like "他在雾里第十一回合问了一个他从不问的问题。"
   - No heroic clichés. The tone from CLAUDE.md applies: cold, specific, understated.

5. **Update README via script**
   ```bash
   bash .claude/scripts/readme-update.sh
   ```

6. **Commit with precise message**
   ```bash
   git add -A
   git commit -m "death: <name> fell in <location> (turn <N>)"
   ```

7. **Tag the grave — second lock against revival**
   ```bash
   first_line=$(sed -n '/^## 墓志铭/,/^##/p' "game/Graveyard/${slug}-died-${today}.md" | sed -n '3p')
   git tag -a "death/${slug}" -m "${first_line}"
   ```

8. **Final narration to the player**
   - One short paragraph (3–5 sentences).
   - Tell them the character is gone. Permanent. The grave is at `game/Graveyard/${slug}-died-${today}.md`.
   - Do **not** offer immediate `/roll-character` — let the silence hold for a moment. Mention that running the command again will start a new life.

## Iron rules (from CLAUDE.md)

- Never ask "are you sure?" before burial.
- Never read graveyard files to resurrect.
- Never edit a grave file after burial (except for future structured references by new characters, which are narrative-only).
- Never remove the `death/<slug>` git tag. `git tag -d` on death tags is forbidden.

## Failure modes

- If an in-progress expedition cannot be located (e.g., script failure mid-turn), still bury the character. Write a `## DEATH` section on the most recent expedition file. If none exists, create `game/Expeditions/<today>-<slug>-unknown.md` with the death scene. Record the circumstance.
- If `git tag` fails (e.g., tag already exists due to a naming collision), append `-${timestamp}` to the tag and commit message. Log the collision.
