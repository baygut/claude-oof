#!/usr/bin/env bash
# Fetch Minecraft's classic Steve "oof" (random/classic_hurt.ogg) and trim the
# hiss after it. Mojang's sounds can't be shipped in this repo, so it comes from
# your own Minecraft install if there is one, otherwise from Mojang's official
# asset server. Needs ffmpeg to convert the .ogg.
set -euo pipefail

DEST="${1:-${HOME}/.claude/claude-oof/custom.wav}"
HASH="9d485556b89bf776042080774679c37300bc744b"
URL="https://resources.download.minecraft.net/${HASH:0:2}/${HASH}"

command -v ffmpeg >/dev/null || { echo "ffmpeg is needed to convert the sound (brew install ffmpeg)" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -f "$TMP/classic_hurt.ogg"; rmdir "$TMP"' EXIT
OGG="$TMP/classic_hurt.ogg"

for mc in "${MINECRAFT_DIR:-}" "$HOME/Library/Application Support/minecraft" "$HOME/.minecraft"; do
  if [ -n "$mc" ] && [ -f "$mc/assets/objects/${HASH:0:2}/$HASH" ]; then
    cp "$mc/assets/objects/${HASH:0:2}/$HASH" "$OGG"
    break
  fi
done
[ -f "$OGG" ] || curl -sSf -o "$OGG" "$URL"

echo "$HASH  $OGG" | shasum -c --status || { echo "Downloaded sound doesn't match Mojang's hash" >&2; exit 1; }

# The oof is over by ~330 ms; the rest of the file is quiet hiss.
mkdir -p "$(dirname "$DEST")"
ffmpeg -loglevel error -y -i "$OGG" -af "atrim=0:0.36,afade=t=out:st=0.28:d=0.08" "$DEST"
echo "Classic oof saved to $DEST"
