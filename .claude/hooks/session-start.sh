#!/usr/bin/env bash
# gitgame session greeting. Informational only — no writes, no commits.
set -u
# Don't set -e: we want the hook to be lenient. A broken hook must never block a session.

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
    # Self-repair: not in a git repo. Init silently if a CLAUDE.md is present
    # (so we know this is a gitgame checkout, not just any random cwd).
    if [ -f "CLAUDE.md" ] && [ -d ".claude" ]; then
        git init -q 2>/dev/null || exit 0
        [ -z "$(git config user.name 2>/dev/null)" ] && git config user.name "gitgame player"
        [ -z "$(git config user.email 2>/dev/null)" ] && git config user.email "player@gitgame.local"
        git add -A 2>/dev/null
        git commit -q -m "Initial commit" 2>/dev/null || true
        repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
    else
        exit 0
    fi
fi
cd "$repo_root" || exit 0

# Count alive + fallen (ignore .gitkeep)
alive_count=$(find game/Characters -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')
fallen_count=$(find game/Graveyard -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "━━━━━━ gitgame ━━━━━━"
echo "  在世: ${alive_count}   已逝: ${fallen_count}"

if [ "$alive_count" -eq 0 ]; then
    if [ "$fallen_count" -gt 0 ]; then
        # Recent death — slightly heavier tone
        last_grave=$(ls -t game/Graveyard/*.md 2>/dev/null | head -1)
        if [ -n "$last_grave" ]; then
            name=$(awk '/^---/{i++; next} i==1 && /^name:/{sub(/^name:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$last_grave")
            echo ""
            echo "  上一位：${name:-$(basename "$last_grave" .md)}"
            echo "  没有在世的英雄。"
            echo "  → /roll-character  开始新的人生"
        fi
    else
        echo ""
        echo "  还没有英雄。"
        echo "  → /roll-character  孵化第一位"
    fi
else
    # List alive characters
    for f in game/Characters/*.md; do
        [ -f "$f" ] && [ "$(basename "$f")" != ".gitkeep" ] || continue
        name=$(awk '/^---/{i++; next} i==1 && /^name:/{sub(/^name:[[:space:]]*/,""); gsub(/^"|"$/,""); print; exit}' "$f")
        level=$(awk '/^---/{i++; next} i==1 && /^level:/{sub(/^level:[[:space:]]*/,""); print; exit}' "$f")
        hp=$(awk '/^---/{i++; next} i==1 && /^hp:/{sub(/^hp:[[:space:]]*/,""); print; exit}' "$f")
        hp_max=$(awk '/^---/{i++; next} i==1 && /^hp_max:/{sub(/^hp_max:[[:space:]]*/,""); print; exit}' "$f")
        echo "  → ${name:-?} · Lv${level:-1} · HP ${hp:-?}/${hp_max:-?}"
    done
fi

echo "━━━━━━━━━━━━━━━━━━━━"
echo ""
