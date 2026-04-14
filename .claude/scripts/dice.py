#!/usr/bin/env python3
"""gitgame deterministic dice — SHA + turn + label → d20.

Same inputs always produce the same output. Players can audit any roll by
recomputing from `git log` and the turn/label recorded in the expedition log.
"""
import hashlib
import subprocess
import sys


def roll(head_sha: str, turn: int, label: str, sides: int = 20) -> int:
    """Return integer in [1, sides]. Deterministic for given inputs."""
    key = f"{head_sha}:{turn}:{label}".encode()
    h = hashlib.sha256(key).hexdigest()
    return int(h[:8], 16) % sides + 1


def _main(argv):
    # Forms:
    #   dice.py <turn> <label>               → uses current HEAD
    #   dice.py <sha> <turn> <label> [sides] → explicit
    if len(argv) == 3:
        head = subprocess.check_output(["git", "rev-parse", "HEAD"]).decode().strip()
        turn = int(argv[1])
        label = argv[2]
        sides = 20
    elif len(argv) >= 4:
        head = argv[1]
        turn = int(argv[2])
        label = argv[3]
        sides = int(argv[4]) if len(argv) > 4 else 20
    else:
        print("usage: dice.py <turn> <label>  |  dice.py <sha> <turn> <label> [sides]",
              file=sys.stderr)
        return 2
    print(roll(head, turn, label, sides))
    return 0


if __name__ == "__main__":
    sys.exit(_main(sys.argv))
