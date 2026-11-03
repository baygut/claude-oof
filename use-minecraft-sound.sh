#!/usr/bin/env bash
# Swap the bundled oof for the real player hurt sound from YOUR OWN Minecraft
# Java install. Nothing is downloaded; the file is converted locally with ffmpeg.
set -euo pipefail

DEST="${HOME}/.claude/claude-oof/custom.wav"
MC="${MINECRAFT_DIR:-}"
if [ -z "$MC" ]; then
  for d in "$HOME/Library/Application Support/minecraft" "$HOME/.minecraft"; do
    [ -d "$d/assets/indexes" ] && MC="$d" && break
  done
fi
[ -n "$MC" ] || { echo "Minecraft install not found. Set MINECRAFT_DIR=/path/to/.minecraft" >&2; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg is needed to convert .ogg (brew install ffmpeg)" >&2; exit 1; }

INDEX=$(ls -t "$MC"/assets/indexes/*.json | head -1)
HASH=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["objects"]["minecraft/sounds/damage/hit1.ogg"]["hash"])' "$INDEX")
SRC="$MC/assets/objects/${HASH:0:2}/$HASH"

mkdir -p "$(dirname "$DEST")"
ffmpeg -loglevel error -y -i "$SRC" "$DEST"
echo "Using $DEST. Test it: python3 ~/.claude/claude-oof/oof.py --test"
