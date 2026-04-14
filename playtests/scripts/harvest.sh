#!/usr/bin/env bash
# harvest.sh — Collect reports from playtest worktrees into main repo.
#
# Usage:
#   ./playtests/scripts/harvest.sh
#
# For each worktree in .worktrees/<RUN_ID>/:
#   - Copies playtests/runs/<RUN_ID>/report.md into main repo
#   - Copies the agent log for reference
#   - Copies the expedition log (if any) as evidence
#
# Does NOT merge game data (characters, loot) — each run's world is its own.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKTREE_DIR="${REPO_ROOT}/.worktrees"
RUNS_DIR="${REPO_ROOT}/playtests/runs"

if [ ! -d "$WORKTREE_DIR" ]; then
    echo "[error] No worktree directory found at $WORKTREE_DIR"
    echo "        Run spawn.sh first."
    exit 1
fi

echo "=== gitgame report harvester ==="
echo ""

harvested=0
failed=0

for wt in "$WORKTREE_DIR"/*/; do
    [ -d "$wt" ] || continue
    RUN_ID="$(basename "$wt")"
    RUN_OUT="${RUNS_DIR}/${RUN_ID}"

    mkdir -p "$RUN_OUT"

    # Harvest report
    REPORT="${wt}playtests/runs/${RUN_ID}/report.md"
    if [ -f "$REPORT" ]; then
        cp "$REPORT" "${RUN_OUT}/report.md"
        echo "[ok]   ${RUN_ID}: report.md harvested"
        harvested=$((harvested + 1))
    else
        echo "[miss] ${RUN_ID}: no report.md found"
        failed=$((failed + 1))
    fi

    # Harvest agent log
    LOG="${wt}playtests/runs/${RUN_ID}/agent-log.txt"
    if [ -f "$LOG" ]; then
        cp "$LOG" "${RUN_OUT}/agent-log.txt"
    fi

    # Harvest expedition logs as evidence
    EXPED_DIR="${wt}game/Expeditions"
    if [ -d "$EXPED_DIR" ] && [ "$(ls -A "$EXPED_DIR" 2>/dev/null)" ]; then
        mkdir -p "${RUN_OUT}/evidence"
        cp "$EXPED_DIR"/*.md "${RUN_OUT}/evidence/" 2>/dev/null || true
    fi

    # Harvest character card (snapshot)
    CHAR_DIR="${wt}game/Characters"
    if [ -d "$CHAR_DIR" ] && [ "$(ls -A "$CHAR_DIR" 2>/dev/null)" ]; then
        mkdir -p "${RUN_OUT}/evidence"
        cp "$CHAR_DIR"/*.md "${RUN_OUT}/evidence/" 2>/dev/null || true
    fi

    # Harvest graveyard entries
    GRAVE_DIR="${wt}game/Graveyard"
    if [ -d "$GRAVE_DIR" ] && [ "$(ls -A "$GRAVE_DIR" 2>/dev/null)" ]; then
        mkdir -p "${RUN_OUT}/evidence"
        cp "$GRAVE_DIR"/*.md "${RUN_OUT}/evidence/" 2>/dev/null || true
    fi
done

echo ""
echo "=== Harvest summary ==="
echo "Reports harvested: $harvested"
echo "Runs without report: $failed"
echo ""

if [ "$harvested" -gt 0 ]; then
    echo "Committing harvested reports..."
    cd "$REPO_ROOT"
    git add playtests/runs/
    git commit -m "playtest: harvest $harvested reports"
    echo ""
    echo "Next: ./playtests/scripts/synthesize.sh"
else
    echo "Nothing to harvest. Check agent logs for errors:"
    echo "  ls $WORKTREE_DIR/*/playtests/runs/*/agent-log.txt"
fi
