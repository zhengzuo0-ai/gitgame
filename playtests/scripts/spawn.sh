#!/usr/bin/env bash
# spawn.sh — Create worktrees and launch playtest agents.
#
# Usage:
#   ./playtests/scripts/spawn.sh [COUNT] [PARALLEL]
#
#   COUNT    — number of playtests to spawn (default: 5)
#   PARALLEL — max concurrent agents (default: 3)
#
# Each run gets:
#   - an isolated git worktree on branch playtest-<RUN_ID>
#   - a headless Claude agent that plays through a session and writes a report
#
# Requires: git ≥ 2.5, claude CLI, python3, bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
COUNT="${1:-5}"
PARALLEL="${2:-3}"
WORKTREE_DIR="${REPO_ROOT}/.worktrees"
PIDS_FILE="${REPO_ROOT}/playtests/.active-pids"
DATE="$(date +%Y%m%d)"
BASE_BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"

echo "=== gitgame playtest spawner ==="
echo "Repo:       $REPO_ROOT"
echo "Base:       $BASE_BRANCH"
echo "Count:      $COUNT"
echo "Parallel:   $PARALLEL"
echo "Worktrees:  $WORKTREE_DIR"
echo ""

mkdir -p "$WORKTREE_DIR"
mkdir -p "$REPO_ROOT/playtests/runs"
: > "$PIDS_FILE"

active=0

for i in $(seq -w 1 "$COUNT"); do
    RUN_ID="${DATE}-${i}"
    BRANCH="playtest-${RUN_ID}"
    WT_PATH="${WORKTREE_DIR}/${RUN_ID}"
    RUN_DIR="${REPO_ROOT}/playtests/runs/${RUN_ID}"

    # Skip if worktree already exists
    if [ -d "$WT_PATH" ]; then
        echo "[skip] Worktree already exists: $WT_PATH"
        continue
    fi

    # Create worktree + branch
    echo "[spawn] Creating worktree $RUN_ID on branch $BRANCH ..."
    git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PATH" "$BASE_BRANCH" 2>/dev/null

    # Prepare run output directory in the worktree
    mkdir -p "${WT_PATH}/playtests/runs/${RUN_ID}"

    # Build the agent prompt
    AGENT_PROMPT="$(cat "$REPO_ROOT/playtests/AGENT_PROMPT.md")

---
Environment: PLAYTEST_RUN_ID=${RUN_ID}
Your worktree is at: ${WT_PATH}
Write your report to: playtests/runs/${RUN_ID}/report.md

Begin by running /roll-character, then play an adventure. When done, write the report and commit it."

    # Launch claude headless in the worktree
    echo "[spawn] Launching agent for $RUN_ID ..."
    (
        cd "$WT_PATH"
        claude --print --dangerously-skip-permissions \
            -p "$AGENT_PROMPT" \
            > "playtests/runs/${RUN_ID}/agent-log.txt" 2>&1
        echo "[done] Agent $RUN_ID finished (exit=$?)"
    ) &

    echo "$! $RUN_ID" >> "$PIDS_FILE"
    active=$((active + 1))

    # Throttle parallelism
    if [ "$active" -ge "$PARALLEL" ]; then
        echo "[wait] Parallel limit ($PARALLEL) reached, waiting for one to finish..."
        wait -n 2>/dev/null || true
        active=$((active - 1))
    fi
done

echo ""
echo "[spawn] All $COUNT agents launched. Waiting for completion..."
wait
echo "[spawn] All agents finished."
echo ""
echo "Next steps:"
echo "  1. Review logs:  ls $WORKTREE_DIR/*/playtests/runs/*/agent-log.txt"
echo "  2. Harvest:      ./playtests/scripts/harvest.sh"
echo "  3. Synthesize:   ./playtests/scripts/synthesize.sh"
echo "  4. Cleanup:      ./playtests/scripts/cleanup-worktrees.sh"
