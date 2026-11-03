#!/usr/bin/env bash
# Installs claude-oof into ~/.claude/claude-oof and points Claude Code's status
# line at it. An existing status line command is kept and chained in front.
#   ./install.sh            install
#   ./install.sh uninstall  restore the previous status line
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
DIR="${HOME}/.claude/claude-oof"
SETTINGS="${HOME}/.claude/settings.json"

if [ "${1:-}" = "uninstall" ]; then
  python3 - "$SETTINGS" "$DIR" <<'PY'
import json, os, sys
settings, d = sys.argv[1], sys.argv[2]
data = json.load(open(settings)) if os.path.exists(settings) else {}
saved = os.path.join(d, "previous-statusline.json")
prev = json.load(open(saved)) if os.path.exists(saved) else None
if prev:
    data["statusLine"] = prev
else:
    data.pop("statusLine", None)
json.dump(data, open(settings, "w"), indent=2)
PY
  rm -rf "$DIR"
  echo "claude-oof removed. Your weekly limit can now drop in silence."
  exit 0
fi

mkdir -p "$DIR"
cp "$SRC/oof.py" "$DIR/oof.py"
cp "$SRC/sounds/oof.wav" "$DIR/oof.wav"
chmod +x "$DIR/oof.py"
if [ ! -f "$DIR/custom.wav" ] && ! "$SRC/get-oof.sh" "$DIR/custom.wav"; then
  echo "Couldn't get the Minecraft oof, using the bundled stand-in. Retry later with ./get-oof.sh"
fi

python3 - "$SETTINGS" "$DIR" <<'PY'
import json, os, shlex, sys
settings, d = sys.argv[1], sys.argv[2]
data = json.load(open(settings)) if os.path.exists(settings) else {}
cmd = f"python3 {shlex.quote(os.path.join(d, 'oof.py'))}"
prev = data.get("statusLine")
if prev and "claude-oof" not in prev.get("command", ""):
    json.dump(prev, open(os.path.join(d, "previous-statusline.json"), "w"))
    cmd += " --chain " + shlex.quote(prev["command"])
elif prev and os.path.exists(os.path.join(d, "previous-statusline.json")):
    old = json.load(open(os.path.join(d, "previous-statusline.json")))
    cmd += " --chain " + shlex.quote(old["command"])
data["statusLine"] = {"type": "command", "command": cmd, "padding": 0}
os.makedirs(os.path.dirname(settings), exist_ok=True)
json.dump(data, open(settings, "w"), indent=2)
PY

echo "claude-oof installed. Hear it now: python3 $DIR/oof.py --test"
