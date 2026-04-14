#!/usr/bin/env python3
"""gitgame — deterministic Loot generator.

Given a git SHA + turn + loot_index + rarity, produce the full 8-line
Loot text + YAML frontmatter, pulling from .claude/scripts/loot-seeds.json.

Usage (stdout mode, legacy):
    python generate-loot.py <sha> <turn> <loot_index> <rarity> [slot_override]

Usage (write mode, preferred):
    python generate-loot.py <sha> <turn> <loot_index> <rarity> \
        --write --acquired-from <loc-slug> [--slot <slot>]

In write mode the file is created at game/Loot/<slug>.md with
acquired_at + acquired_from already filled in, and only the slug is printed
to stdout (consumable by `SLUG=$(...)`).

Rarity determines how many attribute lines are included and adds a mechanical
bonus line (`mechanical: ...`) readable by the GM for judgment bonuses.
"""
import argparse
import hashlib
import json
import os
import re
import sys
from datetime import date

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEEDS_PATH = os.path.join(SCRIPT_DIR, "loot-seeds.json")
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))

RARITY_ATTR_COUNT = {
    "common": 3,
    "uncommon": 4,
    "rare": 5,
    "epic": 6,
    "legendary": 7,
}

# Rarity → mechanical bonus pool. GM reads `mechanical:` line to decide
# whether the item is usable in a given judgment.
RARITY_BONUS = {
    "common":    [("body", 1), ("mind", 1), ("edge", 1), ("luck", 1)],
    "uncommon":  [("body", 1), ("mind", 1), ("edge", 1), ("luck", 1), ("hp_max", 1)],
    "rare":      [("body", 2), ("mind", 2), ("edge", 2), ("luck", 2), ("hp_max", 2)],
    "epic":      [("body", 2), ("mind", 2), ("edge", 2), ("hp_max", 3)],
    "legendary": [("body", 3), ("mind", 3), ("edge", 3), ("hp_max", 5)],
}


def roll(head_sha: str, turn: int, label: str, sides: int = 20) -> int:
    key = f"{head_sha}:{turn}:{label}".encode()
    h = hashlib.sha256(key).hexdigest()
    return int(h[:8], 16) % sides + 1


def slugify(text: str) -> str:
    s = text.lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    return s.strip("-")


def pick_mechanical(head_sha, turn, label_base, rarity):
    pool = RARITY_BONUS.get(rarity, RARITY_BONUS["common"])
    idx = roll(head_sha, turn, f"{label_base}-mech", sides=len(pool)) - 1
    attr, bonus = pool[idx]
    return f"{attr} +{bonus}"


def generate(head_sha: str, turn: int, loot_index: int, rarity: str,
             slot_override=None, acquired_from=None):
    with open(SEEDS_PATH) as f:
        seeds = json.load(f)

    label_base = f"loot-{loot_index}"

    if slot_override and slot_override in seeds["slots"]:
        slot = slot_override
    else:
        slot_idx = roll(head_sha, turn, f"{label_base}-slot",
                        sides=len(seeds["slots"])) - 1
        slot = seeds["slots"][slot_idx]

    pfx_idx = roll(head_sha, turn, f"{label_base}-prefix",
                   sides=len(seeds["prefixes"])) - 1
    sfx_idx = roll(head_sha, turn, f"{label_base}-suffix",
                   sides=len(seeds["suffixes"])) - 1
    prefix = seeds["prefixes"][pfx_idx]
    suffix = seeds["suffixes"][sfx_idx]

    attr_count = RARITY_ATTR_COUNT.get(rarity, 3)
    chosen_attrs = []
    seen = set()
    attempt = 0
    while len(chosen_attrs) < attr_count and attempt < 100:
        idx = roll(head_sha, turn, f"{label_base}-attr-{attempt}",
                   sides=len(seeds["attribute_lines"])) - 1
        attempt += 1
        if idx in seen:
            continue
        seen.add(idx)
        chosen_attrs.append(seeds["attribute_lines"][idx])

    mechanical = pick_mechanical(head_sha, turn, label_base, rarity)

    name = f"{prefix} {suffix}"
    slug = slugify(name)
    today = date.today().isoformat()

    body_lines = [f"{prefix} {suffix}"] + chosen_attrs
    while len(body_lines) < 8 and rarity in ("epic", "legendary"):
        body_lines.append("— untitled entry —")

    yaml_lines = [
        "---",
        f"slot: {slot}",
        f"rarity: {rarity}",
        f'seed: "{head_sha[:8]}:{turn}:{label_base}"',
        f"generated_on: {today}",
        "source: loot-generator",
        f"mechanical: {mechanical}",
        f"tags: [relic, rarity/{rarity}, slot/{slot}, loot]",
    ]
    if acquired_from:
        yaml_lines.append(f"acquired_at: {today}")
        yaml_lines.append(f'acquired_from: "[[{acquired_from}]]"')
    yaml_lines.append("---")
    yaml = "\n".join(yaml_lines) + "\n"

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
    parser = argparse.ArgumentParser(
        description="Generate deterministic Loot for gitgame.")
    parser.add_argument("sha")
    parser.add_argument("turn", type=int)
    parser.add_argument("loot_index", type=int)
    parser.add_argument("rarity")
    parser.add_argument("slot", nargs="?", default=None,
                        help="Optional slot override (legacy 5th positional).")
    parser.add_argument("--write", action="store_true",
                        help="Write file at game/Loot/<slug>.md; stdout prints slug only.")
    parser.add_argument("--acquired-from", default=None,
                        help="Location slug that becomes `acquired_from`.")
    parser.add_argument("--slot", dest="slot_flag", default=None,
                        help="Slot override (flag form).")
    args = parser.parse_args(argv[1:])

    slot_override = args.slot_flag or args.slot
    slug, md = generate(args.sha, args.turn, args.loot_index, args.rarity,
                        slot_override=slot_override,
                        acquired_from=args.acquired_from)

    if args.write:
        loot_dir = os.path.join(REPO_ROOT, "game", "Loot")
        os.makedirs(loot_dir, exist_ok=True)
        path = os.path.join(loot_dir, f"{slug}.md")
        with open(path, "w") as f:
            f.write(md)
        print(slug)
    else:
        print(f"<!-- slug: {slug} -->")
        print(md, end="")
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
