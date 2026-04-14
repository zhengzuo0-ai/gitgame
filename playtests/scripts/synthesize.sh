#!/usr/bin/env bash
# synthesize.sh — Feed harvested reports to an analyst agent.
#
# Usage:
#   ./playtests/scripts/synthesize.sh
#
# Reads all playtests/runs/*/report.md, concatenates them, and passes them
# to a Claude agent with the analyst prompt. Output goes to
# playtests/synthesis/<date>-patterns.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNS_DIR="${REPO_ROOT}/playtests/runs"
SYNTH_DIR="${REPO_ROOT}/playtests/synthesis"
DATE="$(date +%Y-%m-%d)"
OUTPUT="${SYNTH_DIR}/${DATE}-patterns.md"

mkdir -p "$SYNTH_DIR"

# Collect all reports
REPORTS=""
COUNT=0
for report in "$RUNS_DIR"/*/report.md; do
    [ -f "$report" ] || continue
    RUN_ID="$(basename "$(dirname "$report")")"
    REPORTS="${REPORTS}
---
## Run: ${RUN_ID}

$(cat "$report")
"
    COUNT=$((COUNT + 1))
done

if [ "$COUNT" -eq 0 ]; then
    echo "[error] No reports found in $RUNS_DIR/*/report.md"
    echo "        Run harvest.sh first."
    exit 1
fi

echo "=== gitgame playtest synthesizer ==="
echo "Reports found: $COUNT"
echo "Output:        $OUTPUT"
echo ""

# Build analyst prompt with reports inlined
ANALYST_PROMPT="$(cat "$REPO_ROOT/playtests/ANALYST_PROMPT.md")

---

## Reports to analyze ($COUNT total)

$REPORTS

---

Write your synthesis to stdout. Follow the template in the analyst prompt exactly.
Today's date is ${DATE}."

echo "[synth] Launching analyst agent..."

claude --print \
    -p "$ANALYST_PROMPT" \
    > "$OUTPUT" 2>/dev/null

echo "[synth] Synthesis written to $OUTPUT"
echo ""

# Commit the synthesis
cd "$REPO_ROOT"
git add playtests/synthesis/
git commit -m "playtest: synthesis ${DATE} ($COUNT reports)"

echo ""
echo "Done. Review the synthesis:"
echo "  cat $OUTPUT"
echo ""
echo "Then decide which proposals to implement before the next batch."
