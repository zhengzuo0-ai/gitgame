#!/usr/bin/env bash
# gitgame cross-platform Python launcher.
# Picks the first interpreter that actually runs (skips Microsoft Store stubs).
# Also probes common Windows install dirs in case PATH is unhelpful.
# Forces UTF-8 I/O so Chinese characters don't crash on Windows cp1252.
# Usage: bash .claude/scripts/py.sh <script.py> [args...]
set -u

export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

_works() {
    "$1" -c "import sys; sys.exit(0)" >/dev/null 2>&1
}

# 1. Try PATH-resolvable names
for cand in py python3 python; do
    command -v "$cand" >/dev/null 2>&1 || continue
    if _works "$cand"; then
        exec "$cand" "$@"
    fi
done

# 2. Probe common Windows install locations (handles MS Store stub PATH trap)
USERPROFILE_UNIX="${USERPROFILE:-$HOME}"
USERPROFILE_UNIX="${USERPROFILE_UNIX//\\//}"
case "$USERPROFILE_UNIX" in
    [A-Za-z]:*) USERPROFILE_UNIX="/$(echo "${USERPROFILE_UNIX:0:1}" | tr 'A-Z' 'a-z')${USERPROFILE_UNIX:2}" ;;
esac

_probe() {
    for v in 313 312 311 310 39 38; do
        for p in \
            "$USERPROFILE_UNIX/AppData/Local/Programs/Python/Python$v/python.exe" \
            "/c/Python$v/python.exe" \
            "/c/Program Files/Python$v/python.exe" \
            "/c/Program Files (x86)/Python$v/python.exe"; do
            [ -x "$p" ] && _works "$p" && { echo "$p"; return 0; }
        done
    done
    return 1
}

if found=$(_probe); then
    exec "$found" "$@"
fi

cat >&2 <<'EOF'
gitgame: no working Python interpreter found.
Tried: py, python3, python (Microsoft Store stubs are skipped) and common Windows install dirs.

Install one of:
  Windows : winget install Python.Python.3.12
  macOS   : brew install python
  Linux   : sudo apt install python3   (or your package manager)
EOF
exit 127
