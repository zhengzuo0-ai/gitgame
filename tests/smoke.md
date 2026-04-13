# gitgame Smoke Test Log

## 2026-04-13 · MVP v1 baseline

HEAD at time of test: `93d2e89` (will drift after this commit).

| Check | Expected | Actual | Result |
|---|---|---|---|
| dice deterministic | same SHA+turn+label → same result | Run 1 = Run 2 = 19 | ✅ PASS |
| dice differs per turn | turn=1 vs turn=2 ≠ | 19 vs 8 | ✅ PASS |
| `dice.py` CLI form | 3-arg and 4-arg forms both work | both returned valid 1-20 int | ✅ PASS |
| session-start.sh hook | echoes counts + suggests /roll-character | "在世: 0  已逝: 0 → /roll-character" | ✅ PASS |
| readme-update.sh | writes "无人在世" / "无人殒命" placeholders | both present | ✅ PASS |
| readme anchors | survive update | 4 anchors intact | ✅ PASS |
| test_dice.py | 6/6 tests pass | 6/6 | ✅ PASS |
| test_readme_update.sh | exit 0, placeholders present | OK | ✅ PASS |
| 7 commands registered | as Claude Code skills | all 7 shown in skill list | ✅ PASS |
| 3 locations + 3 NPCs exist | with valid YAML | all 6 present | ✅ PASS |
| `samples/` untouched | preserved as read-only reference | unchanged | ✅ PASS |

## What's NOT tested here

These can only be tested in a live Claude Code session:

- `/roll-character` actually generates a character with coherent YAML
- `/skirmish <loc>` runs a GM session with forced roll format
- HP≤0 actually triggers `/graveyard` flow
- `git tag death/<slug>` gets created on death
- README gets live-updated after death

These become **autoresearch loop** targets (Phase 3).

## Next: autoresearch loop

The smoke test passes. The infrastructure exists. The remaining question is whether the **narrative quality** and the **end-to-end flow** work when Claude actually plays as GM. That's what the iteration loop validates.
