#!/usr/bin/env bash
# Refresh the <!-- ALIVE -->...<!-- /ALIVE --> and <!-- FALLEN -->...<!-- /FALLEN --> blocks in README.md
# based on files in game/Characters/ and game/Graveyard/.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

_yaml_field() {
    # Read a top-level YAML scalar. Handles `name: foo` and `name: "foo"` and trailing whitespace.
    local file="$1" field="$2"
    awk -v f="$field" '
        BEGIN { in_yaml=0; seen=0 }
        /^---[[:space:]]*$/ { in_yaml = in_yaml ? 0 : 1; next }
        in_yaml && $0 ~ "^"f":" {
            sub("^"f":[[:space:]]*", "")
            gsub(/^"|"$/, "")
            print; seen=1; exit
        }
    ' "$file"
}

# Build ALIVE block
alive_block=""
shopt -s nullglob
for f in game/Characters/*.md; do
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    slug=$(basename "$f" .md)
    name=$(_yaml_field "$f" name)
    level=$(_yaml_field "$f" level)
    hp=$(_yaml_field "$f" hp)
    hp_max=$(_yaml_field "$f" hp_max)
    [ -z "$name" ] && name="$slug"
    [ -z "$level" ] && level="1"
    alive_block+="- [[${slug}]] · ${name} · Lv${level} · HP ${hp}/${hp_max}"$'\n'
done
if [ -z "$alive_block" ]; then
    alive_block="_(无人在世。\`/roll-character\` 开始新人生。)_"$'\n'
fi

# Build FALLEN block (newest first)
fallen_block=""
for f in $(ls -t game/Graveyard/*.md 2>/dev/null || true); do
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    slug=$(basename "$f" .md)
    died_on=$(_yaml_field "$f" died_on)
    died_in=$(_yaml_field "$f" died_in)
    [ -z "$died_on" ] && died_on="?"
    [ -z "$died_in" ] && died_in="?"
    fallen_block+="- [[${slug}]] · died ${died_on} in ${died_in}"$'\n'
done
if [ -z "$fallen_block" ]; then
    fallen_block="_(无人殒命。)_"$'\n'
fi

# Replace markers via python (handles multiline + special chars safely)
python3 - "$alive_block" "$fallen_block" <<'PYEOF'
import sys, re, pathlib
alive, fallen = sys.argv[1], sys.argv[2]
p = pathlib.Path("README.md")
t = p.read_text()
t = re.sub(
    r"(<!-- ALIVE -->)(.*?)(<!-- /ALIVE -->)",
    lambda m: f"{m.group(1)}\n{alive}{m.group(3)}",
    t, flags=re.DOTALL,
)
t = re.sub(
    r"(<!-- FALLEN -->)(.*?)(<!-- /FALLEN -->)",
    lambda m: f"{m.group(1)}\n{fallen}{m.group(3)}",
    t, flags=re.DOTALL,
)
p.write_text(t)
PYEOF

echo "README.md updated."
