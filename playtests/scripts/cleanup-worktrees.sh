#!/usr/bin/env bash
# cleanup-worktrees.sh — Remove playtest worktrees and their branches.
#
# Usage:
#   ./playtests/scripts/cleanup-worktrees.sh [--dry-run]
#
# Removes all worktrees under .worktrees/ and deletes their playtest-* branches.
# Use --dry-run to preview without deleting.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKTREE_DIR="${REPO_ROOT}/.worktrees"
DRY_RUN=false

if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    echo "=== DRY RUN — no changes will be made ==="
    echo ""
fi

if [ ! -d "$WORKTREE_DIR" ]; then
    echo "No worktree directory at $WORKTREE_DIR. Nothing to clean."
    exit 0
fi

echo "=== gitgame worktree cleanup ==="
echo ""

cleaned=0

for wt in "$WORKTREE_DIR"/*/; do
    [ -d "$wt" ] || continue
    RUN_ID="$(basename "$wt")"
    BRANCH="playtest-${RUN_ID}"

    if $DRY_RUN; then
        echo "[dry] Would remove worktree: $wt"
        echo "[dry] Would delete branch:   $BRANCH"
    else
        echo "[rm]  Removing worktree: $wt"
        git -C "$REPO_ROOT" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"

        echo "[rm]  Deleting branch: $BRANCH"
        git -C "$REPO_ROOT" branch -D "$BRANCH" 2>/dev/null || true
    fi

    cleaned=$((cleaned + 1))
done

if ! $DRY_RUN; then
    # Prune worktree metadata
    git -C "$REPO_ROOT" worktree prune 2>/dev/null || true

    # Remove the worktree dir if empty
    rmdir "$WORKTREE_DIR" 2>/dev/null || true

    # Clean up pids file
    rm -f "$REPO_ROOT/playtests/.active-pids"
fi

echo ""
echo "Cleaned: $cleaned worktrees"
if $DRY_RUN; then
    echo "(Dry run — re-run without --dry-run to execute)"
fi
