#!/usr/bin/env python3
"""claude-oof: take damage every time your Claude weekly limit drops by 1%.

Runs as a Claude Code status line command. Claude Code pipes session JSON to
stdin, including rate_limits.seven_day.used_percentage for subscribers. We keep
the last whole percent we saw and play a hurt sound for every point it went up.
"""
import fcntl
import json
import math
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "state.json")
MAX_HITS = 5  # a big jump still only gets a few oofs, not a minute of screaming


def sound_file():
    custom = os.environ.get("CLAUDE_OOF_SOUND")
    if custom and os.path.exists(custom):
        return custom
    custom = os.path.join(HERE, "custom.wav")
    if os.path.exists(custom):
        return custom
    for path in (os.path.join(HERE, "oof.wav"), os.path.join(HERE, "sounds", "oof.wav")):
        if os.path.exists(path):
            return path
    return None


def play(hits):
    path = sound_file()
    if not path or hits <= 0:
        return
    player = next((p for p in ("afplay", "paplay", "aplay") if shutil.which(p)), None)
    if not player:
        return
    one = f'{player} "{path}"'
    script = "; sleep 0.12; ".join([one] * hits)
    # Detach so the status line returns right away while the sound plays.
    subprocess.Popen(
        ["sh", "-c", script],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def track(seven_day):
    """Update the saved percent and return how many hits to play."""
    pct = math.floor(seven_day.get("used_percentage") or 0)
    resets_at = seven_day.get("resets_at")
    with open(STATE, "a+") as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        try:
            prev = json.load(f)
        except ValueError:
            prev = None
        hits = 0
        same_week = prev and abs((resets_at or 0) - (prev.get("resets_at") or 0)) < 3600
        if same_week:
            hits = max(0, pct - prev.get("pct", pct))
        # First run, a new week or a lower number: just remember it, no damage.
        f.seek(0)
        f.truncate()
        json.dump({"pct": pct, "resets_at": resets_at}, f)
    return min(hits, MAX_HITS)


def hearts(used):
    left = max(0.0, 100.0 - used)
    full = int(left // 10)
    half = 1 if left - full * 10 >= 5 else 0
    return "♥" * full + ("❥" if half else "") + "♡" * (10 - full - half)


def chained(raw, cmd):
    try:
        out = subprocess.run(cmd, shell=True, input=raw, capture_output=True, text=True, timeout=5)
        return out.stdout.rstrip("\n")
    except Exception:
        return ""


def main():
    args = sys.argv[1:]
    if args and args[0] == "--test":
        play(int(args[1]) if len(args) > 1 else 1)
        return
    chain = args[1] if len(args) > 1 and args[0] == "--chain" else None

    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except ValueError:
        data = {}
    seven_day = (data.get("rate_limits") or {}).get("seven_day")

    line = ""
    if seven_day and seven_day.get("used_percentage") is not None:
        play(track(seven_day))
        used = seven_day["used_percentage"]
        line = f"\033[31m{hearts(used)}\033[0m {100 - used:.0f}% of the week left"

    if chain:
        prev = chained(raw, chain)
        line = f"{prev}  {line}" if prev and line else prev or line
    print(line)


if __name__ == "__main__":
    main()
