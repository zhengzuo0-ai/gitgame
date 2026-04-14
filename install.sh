#!/usr/bin/env bash
# gitgame installer — bootstraps a clone for play.
# Idempotent. Run from the repo root.
set -u

cd "$(dirname "$0")"

echo "━━━━━━ gitgame install ━━━━━━"

# 1. git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  ✗ not in a git repo — initializing"
    git init -q
    git add -A
    git commit -q -m "Initial commit" || true
else
    echo "  ✓ git repo present"
fi

# 2. git config — author identity required for commits
if [ -z "$(git config user.name 2>/dev/null)" ]; then
    echo "  ! git user.name not set — using 'gitgame player'"
    git config user.name "gitgame player"
fi
if [ -z "$(git config user.email 2>/dev/null)" ]; then
    echo "  ! git user.email not set — using 'player@gitgame.local'"
    git config user.email "player@gitgame.local"
fi

# 3. line-ending normalization
if [ ! -f .gitattributes ]; then
    echo "* text=auto eol=lf" > .gitattributes
    echo "  + wrote .gitattributes"
fi

# 4. Python detection
PY=""
for cand in py python3 python; do
    command -v "$cand" >/dev/null 2>&1 || continue
    if "$cand" -c "import sys; sys.exit(0)" >/dev/null 2>&1; then
        PY="$cand"
        break
    fi
done
if [ -z "$PY" ]; then
    echo "  ✗ no working Python found."
    echo "    Windows: winget install Python.Python.3.12"
    echo "    macOS:   brew install python"
    echo "    Linux:   apt/dnf/pacman install python3"
    exit 1
else
    ver=$("$PY" -c "import sys; print(sys.version.split()[0])")
    echo "  ✓ python: $PY ($ver)"
fi

# 5. Make scripts executable (no-op on Windows but harmless)
chmod +x .claude/scripts/*.sh .claude/scripts/*.py .claude/hooks/*.sh tests/*.sh 2>/dev/null || true

# 6. Smoke test
if bash .claude/scripts/py.sh .claude/scripts/dice.py abc123 1 install-test >/dev/null 2>&1; then
    echo "  ✓ dice.py runs"
else
    echo "  ✗ dice.py smoke test failed"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Ready. In Claude Code:  /roll-character"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
