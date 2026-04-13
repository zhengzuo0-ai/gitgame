# gitgame · Session Status (2026-04-13)

> Built autonomously overnight using the gstack → superpowers → autoresearch loop pattern.

## Metric trajectory

| Stage | PASS | Delta | What was added |
|---|---|---|---|
| Baseline | **12** | — | structural invariants after Tasks 1-9 |
| ar1.1 | 13 | +1 | wiki-link integrity (caught bogus `[[character]]` placeholder) |
| ar1.2 | 14 | +1 | no-placeholder-markers |
| ar1.3 | 15 | +1 | rulebook-mentions-all-commands |
| sp-batch1 | **17** | +2 | session-start hook registered, loot generator, permadeath-sim test |
| ar2.1 | 18 | +1 | dice-distribution-uniform (10k samples, ±20% tol) |
| ar2.2 | 19 | +1 | samples/ read-only drift check |
| ar2.3 | 20 | +1 | world-xref-integrity (exits/location → valid files) |
| sp-batch2 | **22** | +2 | character-creation-simulation, rulebook-paths-exist, dice edge cases |
| ar3.1 | 22 | — | loot-generator-output-valid (strictened existing check) |
| ar3.2 | 23 | +1 | shell-scripts-executable |
| ar3.3 | 24 | +1 | commit-message-conventions |
| ar3.4 | **25** | +1 | all-frontmatter-valid-yaml (strict PyYAML parse) |

**From 12 to 25 top-level invariants.** Inner `dice-unit-tests` assertion expanded from 6 to 11 sub-assertions.

## What exists now

### Infrastructure
- `CLAUDE.md` (224 lines) — GM rulebook, Claude auto-reads every session
- `.claude/commands/` — **7 slash commands** (all registered as Claude Code skills)
- `.claude/scripts/dice.py` — deterministic d20 from SHA+turn+label
- `.claude/scripts/generate-loot.py` — deterministic 8-line Loot generator
- `.claude/scripts/readme-update.sh` — live-sync alive/fallen to README
- `.claude/hooks/session-start.sh` — terminal greeting with alive/dead counts
- `.claude/settings.json` — registers the SessionStart hook

### World content
- 3 locations: `south-marches-village`, `ember-pass`, `crypt-of-mist`
- 3 NPCs: `innkeeper-brann`, `lyra-the-keeper`, `wandering-herbalist`
- Empty state dirs: `Characters/`, `Graveyard/`, `Expeditions/`, `Loot/`, `Journal/`

### Tests
- `tests/test_dice.py` — 11 unit tests (deterministic, d20 range, unicode labels, empty labels, long SHAs, negative turns, large turns, etc.)
- `tests/test_readme_update.sh` — marker preservation + placeholder output
- `tests/test_character_creation_sim.sh` — simulated `/roll-character`, 6 schema invariants
- `tests/test_permadeath_sim.sh` — simulated death: mv + tag + README sync + epitaph, 7 invariants
- `tests/run_all.sh` — orchestrator, 25 top-level invariants green

## Run it

```bash
cd /home/user/Game_on_Obsidian
bash tests/run_all.sh        # all 25 invariants
python tests/test_dice.py    # 11 dice tests

claude                       # starts session; SessionStart hook greets you
# → "没有在世的英雄。运行 /roll-character 开始。"

# In Claude Code:
/roll-character              # first character
/skirmish ember-pass         # 3-min encounter
# ...
```

## Loop structure used this session

As requested: **(autoresearch × 3) → gstack retro → superpowers execute → repeat**

- **Iteration 1** (cycle 1): ar ×3 added 3 invariants → gstack retro identified 3 P1 gaps → superpowers built them
- **Iteration 2** (cycle 2): same pattern, 3 more invariants → 3 more P1 items
- **Iteration 3**: 4 ar runs for extra robustness

Every "experiment" commit uses `experiment(arN.M): ...` prefix so you can audit the loop history via `git log --oneline | grep experiment`.

## What's NOT tested (requires live play)

These can only be validated in a real Claude Code session with a human:
- Narrative quality (tone matches CLAUDE.md)
- NPC voice consistency within a session
- Saga chapter pacing
- `rest` correctly completing an in-progress expedition as "retreated"
- `Graveyard` entries actually surviving `git reset` / `git revert` attempts

Those are the **next natural iteration target**: play one `/skirmish` from start to death, note what's awkward, fix CLAUDE.md + command prompts.

## Branch status

- Branch: `claude/research-text-game-e8Swe`
- Pushed: yes (last push: after ar3.3)
- PR: **not created** (per repo policy — only on explicit request)

## Commits from this session (reverse-chronological highlights)

```
experiment(ar3.4)  strict YAML validation
experiment(ar3.3)  commit-message conventions audit
experiment(ar3.2)  shell-scripts-executable
experiment(ar3.1)  loot output structure validation
feat(superpowers-batch2)  char creation sim + rulebook paths + dice edge cases
experiment(ar2.3)  world-xref-integrity
experiment(ar2.2)  samples/ drift check
experiment(ar2.1)  dice distribution uniformity
feat(superpowers-batch)   hook registration + loot generator + permadeath sim
experiment(ar1.3)  rulebook-mentions-all-commands
experiment(ar1.2)  no-placeholder-markers
experiment(ar1.1)  wiki-link integrity (caught a bug)
test(runner)       unified run_all.sh baseline
test(smoke)        11 baseline checks
feat(readme)       rewrite as gitgame README
feat(permadeath)   graveyard ritual + readme sync
feat(world)        3 locations + 3 NPCs
feat(hooks)        session-start + loot word tables
feat(commands)     skirmish + expedition + saga
feat(commands)     roll-character + inventory + rest
feat(rulebook)     CLAUDE.md
feat(dice)         SHA-derived d20
```

## Where to resume

1. Actually play one `/skirmish` — see what's awkward
2. After that, likely iterate on CLAUDE.md tone guidance + command prompts
3. Then consider v2 (GitHub social layer — `/visit`, Wall of Fallen, automated push hooks)

The infrastructure is done. The game is ready to be played.
