"""Smoke tests for gitgame dice — deterministic d20 from SHA + turn + label."""
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '.claude', 'scripts'))

from dice import roll  # noqa: E402


def test_deterministic():
    a = roll("abc123def456", 1, "perceive-door")
    b = roll("abc123def456", 1, "perceive-door")
    assert a == b, f"not deterministic: {a} != {b}"


def test_range_d20():
    for i in range(100):
        r = roll("deadbeef" * 8, i, f"label-{i}")
        assert 1 <= r <= 20, f"out of range: {r}"


def test_different_turns_differ():
    results = {roll("abc", t, "x") for t in range(50)}
    assert len(results) > 5, f"too few unique results ({len(results)}) — entropy too low"


def test_different_labels_differ():
    results = {roll("abc", 1, f"label-{i}") for i in range(50)}
    assert len(results) > 5, f"too few unique results ({len(results)}) — label variation collapsed"


def test_cli_invocation():
    script = os.path.join(os.path.dirname(__file__), '..', '.claude', 'scripts', 'dice.py')
    out = subprocess.check_output([sys.executable, script, "abc123", "3", "attack-wolf-1"]).decode().strip()
    assert out.isdigit() and 1 <= int(out) <= 20, f"cli out of range: {out}"


def test_sides_parameter():
    # d100 range
    for i in range(50):
        r = roll("abc", i, "x", sides=100)
        assert 1 <= r <= 100


def test_unicode_label():
    # Chinese labels must work
    r = roll("abc", 1, "感知-门")
    assert 1 <= r <= 20


def test_empty_label():
    # Empty label should not crash
    r = roll("abc", 1, "")
    assert 1 <= r <= 20


def test_long_sha():
    # Real git SHAs are 40 chars; also test longer strings
    r = roll("a" * 200, 1, "x")
    assert 1 <= r <= 20


def test_negative_turn():
    # Edge: negative turn number shouldn't crash (even if never used)
    r = roll("abc", -1, "x")
    assert 1 <= r <= 20


def test_large_turn():
    # Saga max is 40; test well beyond
    r = roll("abc", 10_000_000, "x")
    assert 1 <= r <= 20


if __name__ == "__main__":
    test_deterministic()
    test_range_d20()
    test_different_turns_differ()
    test_different_labels_differ()
    test_cli_invocation()
    test_sides_parameter()
    test_unicode_label()
    test_empty_label()
    test_long_sha()
    test_negative_turn()
    test_large_turn()
    print("OK — all 11 dice tests pass")
