#!/usr/bin/env python3
"""Synthesize the bundled oof.wav: a short, low "uhh" grunt.

It is an original sound made from a sawtooth voice pushed through two vowel
formant filters, so the repo ships no game assets. Run: python3 generate.py
"""
import math
import os
import random
import struct
import wave

RATE = 44100
LENGTH = 0.32


def bandpass(samples, freq, q):
    # RBJ biquad band-pass (constant 0 dB peak gain).
    w = 2 * math.pi * freq / RATE
    alpha = math.sin(w) / (2 * q)
    b0, b2 = alpha, -alpha
    a0, a1, a2 = 1 + alpha, -2 * math.cos(w), 1 - alpha
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for x in samples:
        y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def main():
    random.seed(7)
    n = int(RATE * LENGTH)
    phase = 0.0
    voice = []
    for i in range(n):
        t = i / RATE
        pitch = 210 * math.exp(-t * 2.2) + 95  # quick downward "oof" glide
        phase = (phase + pitch / RATE) % 1.0
        saw = 2 * phase - 1
        breath = random.uniform(-1, 1) * 0.25
        attack = min(1.0, t / 0.008)
        decay = math.exp(-t * 9)
        voice.append((saw + breath) * attack * decay)

    vowel = [
        a + b * 0.6 + c * 0.25
        for a, b, c in zip(bandpass(voice, 350, 4), bandpass(voice, 800, 5), bandpass(voice, 2400, 6))
    ]
    peak = max(abs(s) for s in vowel) or 1
    frames = b"".join(struct.pack("<h", int(s / peak * 0.85 * 32767)) for s in vowel)

    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "oof.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(out)


if __name__ == "__main__":
    main()
