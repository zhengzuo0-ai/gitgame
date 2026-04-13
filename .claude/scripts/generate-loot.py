#!/usr/bin/env python3
"""gitgame — deterministic Loot generator.

Given a git SHA + turn + loot_index + rarity, produce the full 8-line
Loot text + YAML frontmatter, pulling from .claude/scripts/loot-seeds.json.

Usage:
    python generate-loot.py <sha> <turn> <loot_index> <rarity> [slot_override]

Output: Markdown to stdout. Redirect to game/Loot/<slug>.md.

Rarity determines how many attribute lines are included (common=3, rare=5,
legendary=7) and adds quality markers.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from datetime import date

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEEDS_PATH = os.path.join(SCRIPT_DIR, "loot-seeds.json")

RARITY_ATTR_COUNT = {
    "common": 3,
    "uncommon": 4,
    "rare": 5,
    "epic": 6,
    "legendary": 7,
}


def roll(head_sha: str, turn: int, label: str, sides: int = 20) -> int:
    key = f"{head_sha}:{turn}:{label}".encode()
    h = hashlib.sha256(key).hexdigest()
    return int(h[:8], 16) % sides + 1


def slugify(text: str) -> str:
    s = text.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def generate(head_sha: str, turn: int, loot_index: int, rarity: str, slot_override=None):
    with open(SEEDS_PATH) as f:
        seeds = json.load(f)

    label_base = f"loot-{loot_index}"

    # Pick slot (or use override)
    if slot_override and slot_override in seeds["slots"]:
        slot = slot_override
    else:
        slot_idx = roll(head_sha, turn, f"{label_base}-slot", sides=len(seeds["slots"])) - 1
        slot = seeds["slots"][slot_idx]

    # Pick prefix and suffix
    pfx_idx = roll(head_sha, turn, f"{label_base}-prefix", sides=len(seeds["prefixes"])) - 1
    sfx_idx = roll(head_sha, turn, f"{label_base}-suffix", sides=len(seeds["suffixes"])) - 1
    prefix = seeds["prefixes"][pfx_idx]
    suffix = seeds["suffixes"][sfx_idx]

    # Pick attribute lines (distinct indexes)
    attr_count = RARITY_ATTR_COUNT.get(rarity, 3)
    chosen_attrs = []
    seen = set()
    attempt = 0
    while len(chosen_attrs) < attr_count and attempt < 100:
        idx = roll(head_sha, turn, f"{label_base}-attr-{attempt}", sides=len(seeds["attribute_lines"])) - 1
        attempt += 1
        if idx in seen:
            continue
        seen.add(idx)
        chosen_attrs.append(seeds["attribute_lines"][idx])

    # Compose name for display
    # "Prefix of Something" — use the prefix as the noun, suffix as the of-clause
    name = f"{prefix} {suffix}"
    slug = slugify(name)
    today = date.today().isoformat()

    # 8 lines: Name / Suffix / up to 6 more lines (attrs + padding)
    # Loot's original format: Name / "+N" / [Attr] / {Material} / + / - / ~ / ‡
    # We approximate by listing the 8 body lines in order.
    body_lines = [f"{prefix} {suffix}"] + chosen_attrs
    # Pad to 8 lines with empty marker lines if needed, but prefer more attrs for higher rarity
    while len(body_lines) < 8 and rarity in ("epic", "legendary"):
        # Add additional marker for flavor
        body_lines.append("— untitled entry —")

    yaml = f"""---
slot: {slot}
rarity: {rarity}
seed: "{head_sha[:8]}:{turn}:{label_base}"
generated_on: {today}
source: loot-generator
tags: [relic, rarity/{rarity}, slot/{slot}, loot]
---
"""

    body = "\n".join(body_lines)
    flavor = _pick_flavor(head_sha, turn, label_base, rarity, slot, prefix, suffix)

    markdown = f"""{yaml}
# {name}

```
{body}
```

{flavor}
"""
    return slug, markdown


def _pick_flavor(head_sha, turn, label, rarity, slot, prefix, suffix):
    """Deterministic but varied flavor snippets."""
    flavor_bank = [
        f"它在被取走时没有反抗。{prefix} 的所有物大多如此。",
        f"穿戴过的人不多。{suffix} 这个名字是最后一位起的。",
        "它不怕被遗忘——它**是**遗忘。",
        "某种旧物。具体旧到哪一年，你问它也不会答。",
        "使用时会让你短暂地知道一件你本不该知道的事。代价未标明。",
        f"这件 {slot} 在雾里几乎透明。在阳光下又像刻意显形。",
    ]
    idx = roll(head_sha, turn, f"{label}-flavor", sides=len(flavor_bank)) - 1
    return flavor_bank[idx]


def _main(argv):
    if len(argv) < 5:
        print("usage: generate-loot.py <sha> <turn> <loot_index> <rarity> [slot]",
              file=sys.stderr)
        return 2
    sha = argv[1]
    turn = int(argv[2])
    loot_index = int(argv[3])
    rarity = argv[4]
    slot_override = argv[5] if len(argv) > 5 else None
    slug, md = generate(sha, turn, loot_index, rarity, slot_override)
    # Emit slug on first line (comment-style) so caller can capture
    print(f"<!-- slug: {slug} -->")
    print(md, end="")
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
