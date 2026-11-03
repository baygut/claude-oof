# claude-oof

Every time your Claude weekly limit goes down by 1%, you take damage. *Oof.*

```
♥♥♥♥♥♥❥♡♡♡ 65% of the week left
```

claude-oof is a tiny [Claude Code status line](https://docs.claude.com/en/docs/claude-code/statusline)
command. Claude Code hands status line commands your subscription usage
(`rate_limits.seven_day.used_percentage`), so there are no tokens, API calls or
background daemons involved. Each time the weekly percentage crosses a whole
number, it plays a hurt sound and shows how many hearts you have left.

## Install

```bash
git clone https://github.com/baygut/claude-oof.git
cd claude-oof
./install.sh
```

Then check the sound works:

```bash
python3 ~/.claude/claude-oof/oof.py --test
```

Restart Claude Code (the CLI) and keep working. The first refresh just remembers
where you are. After that, every 1% costs you an oof (at most 5 in a row if a
big jump happens at once). When the week resets, the hearts refill silently.

If you already had a status line, the installer keeps it and puts the hearts
after it. `./install.sh uninstall` puts it back the way it was.

## The sound

You get Minecraft's classic Steve "oof" (`random/classic_hurt.ogg`), the
original player hurt sound. Mojang's sounds can't be redistributed, so it isn't
in this repo: `install.sh` runs `get-oof.sh`, which takes it from your own
Minecraft install if you have one, or else from Mojang's official asset server.
It checks the file against Mojang's hash and trims the half second of hiss that
follows the oof. This needs `ffmpeg` (`brew install ffmpeg`).

Without ffmpeg or a network connection, it falls back to an original
synthesized grunt (`sounds/oof.wav`, made by `sounds/generate.py`). Run
`./get-oof.sh` any time to try again. You can also point at any file you like:

```bash
export CLAUDE_OOF_SOUND=/path/to/whatever.wav
```

## Requirements

- Claude Code with a Claude Pro/Max subscription (the weekly limit only exists
  there)
- `python3`, plus `ffmpeg` for the Minecraft sound
- macOS (`afplay`) or Linux (`paplay`/`aplay`)

## Notes

- The usage numbers only arrive after the first API response of a session, and
  only update when the status line refreshes, so the oof lands shortly after
  the message that cost you.
- The status line is a terminal feature. Claude Code in the desktop app or an
  IDE may not run it.
- State lives in `~/.claude/claude-oof/state.json`. Delete it to reset.

MIT licensed. Not affiliated with Mojang, Microsoft or Anthropic.
