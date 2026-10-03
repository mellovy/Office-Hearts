"""Chiptune SFX + BGM generator for Office Hearts.

Writes 16-bit mono 22050 Hz WAVs into assets/audio/. No external deps.
Run:  python tools/gen_audio.py
"""

import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")


# ------------------------------------------------------------------ synthesis

def midi(m):
    return 440.0 * (2.0 ** ((m - 69) / 12.0))


class Buf:
    """Float sample buffer with helpers."""

    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.data = [0.0] * self.n

    def add(self, i, v):
        if 0 <= i < self.n:
            self.data[i] += v

    def write(self, path, peak=0.85, fade_edges=0):
        m = max(1e-9, max(abs(x) for x in self.data))
        scale = peak / m
        frames = bytearray()
        for i, x in enumerate(self.data):
            v = x * scale
            if fade_edges:
                if i < fade_edges:
                    v *= i / fade_edges
                elif i > self.n - fade_edges:
                    v *= (self.n - i) / fade_edges
            s = int(max(-1.0, min(1.0, v)) * 32767)
            frames += struct.pack("<h", s)
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(bytes(frames))


def adsr(t, dur, a=0.005, d=0.06, s=0.6, r=0.06):
    if t < a:
        return t / a
    if t < a + d:
        return 1.0 - (1.0 - s) * (t - a) / d
    if t < max(a + d, dur - r):
        return s
    left = dur - t
    return s * max(0.0, left / r) if left > 0 else 0.0


def osc(kind, phase, duty=0.5):
    p = phase % 1.0
    if kind == "square":
        return 1.0 if p < duty else -1.0
    if kind == "tri":
        return 4.0 * abs(p - 0.5) - 1.0
    if kind == "saw":
        return 2.0 * p - 1.0
    return 0.0


def tone(buf, start, dur, freq, amp=0.25, kind="square", duty=0.5,
         a=0.004, d=0.05, s=0.7, r=0.05, slide=None, vib=0.0, vib_hz=5.0):
    n0 = int(start * SR)
    n1 = int((start + dur) * SR)
    phase = 0.0
    for i in range(n0, n1):
        t = (i - n0) / SR
        f = slide(t) if slide else freq
        if vib:
            f *= 1.0 + vib * math.sin(2 * math.pi * vib_hz * t)
        phase += f / SR
        v = osc(kind, phase, duty)
        buf.add(i, v * adsr(t, dur, a, d, s, r) * amp)


def kick(buf, start, amp=0.5):
    n0 = int(start * SR)
    dur = 0.14
    n1 = n0 + int(dur * SR)
    phase = 0.0
    for i in range(n0, n1):
        t = (i - n0) / SR
        f = 130.0 * math.exp(-t * 22) + 45.0
        phase += f / SR
        env = math.exp(-t * 18)
        buf.add(i, math.sin(2 * math.pi * phase) * env * amp)


def snare(buf, start, amp=0.3, rng=None):
    rng = rng or random
    n0 = int(start * SR)
    dur = 0.11
    n1 = n0 + int(dur * SR)
    phase = 0.0
    for i in range(n0, n1):
        t = (i - n0) / SR
        env = math.exp(-t * 34)
        phase += 190.0 / SR
        body = math.sin(2 * math.pi * phase) * 0.4
        buf.add(i, (rng.uniform(-1, 1) * 0.8 + body) * env * amp)


def hat(buf, start, amp=0.11, dur=0.035, rng=None):
    rng = rng or random
    n0 = int(start * SR)
    n1 = n0 + int(dur * SR)
    prev = 0.0
    for i in range(n0, n1):
        t = (i - n0) / SR
        env = math.exp(-t * 90)
        x = rng.uniform(-1, 1)
        hp = x - prev          # crude high-pass
        prev = x
        buf.add(i, hp * env * amp)


def whoosh(buf, start, dur=0.4, amp=0.5, rng=None, up=False):
    rng = rng or random
    n0 = int(start * SR)
    n1 = n0 + int(dur * SR)
    lp = 0.0
    for i in range(n0, n1):
        t = (i - n0) / SR
        p = t / dur
        cut = (0.06 + 0.55 * (p if not up else 1 - p))
        x = rng.uniform(-1, 1)
        lp += (x - lp) * cut
        env = math.sin(math.pi * p) ** 1.5
        buf.add(i, lp * env * amp)


# ----------------------------------------------------------------------- SFX

def gen_sfx():
    # text blip — the classic VN typing tick
    b = Buf(0.09)
    tone(b, 0.0, 0.055, 1250, amp=0.32, kind="square", duty=0.25,
         a=0.002, d=0.02, s=0.4, r=0.03, slide=lambda t: 1300 - 900 * t)
    b.write(os.path.join(OUT, "sfx_blip.wav"), peak=0.55, fade_edges=40)

    # UI click
    b = Buf(0.09)
    tone(b, 0.0, 0.04, 1750, amp=0.3, kind="square", duty=0.5,
         a=0.001, d=0.012, s=0.3, r=0.02)
    tone(b, 0.0, 0.03, 880, amp=0.18, kind="square", duty=0.5, a=0.001, d=0.01, s=0.2, r=0.02)
    b.write(os.path.join(OUT, "sfx_click.wav"), peak=0.5, fade_edges=40)

    # transition whoosh (page/scene change)
    rng = random.Random(11)
    b = Buf(0.55)
    whoosh(b, 0.0, 0.5, amp=0.6, rng=rng)
    tone(b, 0.02, 0.35, 300, amp=0.12, kind="tri", a=0.02, d=0.15, s=0.3, r=0.15,
         slide=lambda t: 220 + 500 * t)
    b.write(os.path.join(OUT, "sfx_whoosh.wav"), peak=0.6, fade_edges=200)

    # choice reveal stinger — impact + rising arpeggio
    rng = random.Random(23)
    b = Buf(1.1)
    kick(b, 0.0, amp=0.6)
    whoosh(b, 0.0, 0.3, amp=0.35, rng=rng, up=True)
    for k, m in enumerate([64, 67, 71, 76]):          # E-G-B-E ascending
        tone(b, 0.04 + k * 0.075, 0.5, midi(m), amp=0.2, kind="square", duty=0.5,
             a=0.003, d=0.08, s=0.45, r=0.25)
    tone(b, 0.34, 0.6, midi(76) + 0, amp=0.16, kind="square", duty=0.25,
         a=0.004, d=0.1, s=0.4, r=0.3, vib=0.006)
    tone(b, 0.34, 0.6, midi(71), amp=0.12, kind="square", duty=0.5,
         a=0.004, d=0.1, s=0.4, r=0.3)
    b.write(os.path.join(OUT, "sfx_choice.wav"), peak=0.72, fade_edges=200)

    # affection chime — bright two-note bell
    b = Buf(0.7)
    tone(b, 0.0, 0.35, midi(88), amp=0.26, kind="tri", a=0.002, d=0.1, s=0.35, r=0.22)
    tone(b, 0.0, 0.35, midi(88) * 2, amp=0.1, kind="tri", a=0.002, d=0.08, s=0.3, r=0.2)
    tone(b, 0.12, 0.45, midi(93), amp=0.24, kind="tri", a=0.002, d=0.12, s=0.35, r=0.3)
    tone(b, 0.12, 0.45, midi(93) * 2, amp=0.09, kind="tri", a=0.002, d=0.1, s=0.3, r=0.28)
    b.write(os.path.join(OUT, "sfx_chime.wav"), peak=0.6, fade_edges=200)

    # ending fanfare
    rng = random.Random(37)
    b = Buf(2.6)
    prog = [(60, 64, 67), (65, 69, 72), (67, 71, 74), (60, 64, 67)]
    for k, ch in enumerate(prog):
        t0 = k * 0.42
        for m in ch:
            tone(b, t0, 0.38, midi(m), amp=0.17, kind="square", duty=0.5,
                 a=0.006, d=0.1, s=0.6, r=0.12)
        tone(b, t0, 0.4, midi(ch[0] - 24), amp=0.22, kind="tri", a=0.004, d=0.12, s=0.5, r=0.14)
        kick(b, t0, amp=0.35)
    for k, m in enumerate([72, 76, 79, 84]):
        tone(b, 1.68 + k * 0.11, 0.9, midi(m), amp=0.19, kind="square", duty=0.25,
             a=0.004, d=0.15, s=0.5, r=0.35)
    for m in [60, 64, 67, 72]:
        tone(b, 2.12, 0.55, midi(m), amp=0.15, kind="square", duty=0.5,
             a=0.004, d=0.15, s=0.4, r=0.3)
    snare(b, 1.68, amp=0.25, rng=rng)
    b.write(os.path.join(OUT, "sfx_ending.wav"), peak=0.78, fade_edges=300)


# ----------------------------------------------------------------------- BGM

SCALE_MAJOR = [0, 2, 4, 5, 7, 9, 11]
SCALE_MINOR = [0, 2, 3, 5, 7, 8, 10]


def gen_track(name, bpm, bars, prog, kind="square", swing=0.0, style="upbeat",
              seed=1, lead_oct=12, dense=1, lead_amp=0.22, duty=0.5):
    """prog: list of (chord_root_midi, [chord_tone_offsets], scale)."""
    rng = random.Random(seed)
    beat = 60.0 / bpm
    dur = bars * 4 * beat
    b = Buf(dur)

    for bar in range(bars):
        root, tones, scale = prog[bar % len(prog)]
        t0 = bar * 4 * beat

        # ---- bass: root/fifth pulses
        bass_pattern = [(0.0, 1), (2.0, 1)] if style != "sad" else [(0.0, 1), (2.5, 1)]
        if style == "upbeat":
            bass_pattern = [(0.0, 1), (1.5, 0), (2.0, 1), (3.5, 0)]
        for off, is_root in bass_pattern:
            m = root - 24 + (0 if is_root else 7)
            tone(b, t0 + off * beat, beat * 0.9, midi(m), amp=0.26, kind="tri",
                 a=0.005, d=0.08, s=0.6, r=0.1)

        # ---- drums
        if style != "sad":
            kick(b, t0 + 0, amp=0.4)
            kick(b, t0 + 2 * beat, amp=0.36)
            snare(b, t0 + 1 * beat, amp=0.26, rng=rng)
            snare(b, t0 + 3 * beat, amp=0.26, rng=rng)
            for k in range(8):
                hat(b, t0 + k * beat / 2 + (beat * swing if k % 2 else 0),
                    amp=0.1 if k % 2 else 0.07, rng=rng)
        else:
            kick(b, t0, amp=0.3)
            snare(b, t0 + 2 * beat, amp=0.18, rng=rng)

        # ---- lead melody: chord tones on strong beats, scale steps between
        steps = int(8 * dense)
        for k in range(steps):
            pos = k * (4.0 / steps)
            strong = (k % (steps // 2) == 0) if steps >= 2 else True
            if kind == "tri" and not strong and rng.random() < 0.4:
                continue                                    # calmer sparse lead
            if strong:
                deg = rng.choice(tones)
            else:
                deg = rng.choice([d % 12 for d in tones] + [s for s in scale])
            m = root + lead_oct + (deg if strong else deg)
            if not strong and rng.random() < 0.35:
                m += 12
            length = (4.0 / steps) * beat * (1.7 if strong else 1.1)
            tone(b, t0 + pos * beat, length, midi(m), amp=lead_amp, kind=kind, duty=duty,
                 a=0.006, d=0.08, s=0.6 if strong else 0.45, r=0.12, vib=0.004)

        # ---- chord stab on the backbeat for the bouncy tracks
        if style == "upbeat" or style == "tense":
            for m in tones:
                tone(b, t0 + 2.5 * beat, beat * 0.45, midi(root + m - 12 + 12), amp=0.09,
                     kind="square", duty=0.25, a=0.004, d=0.06, s=0.35, r=0.08)

    b.write(os.path.join(OUT, name), peak=0.8, fade_edges=0)


# midi roots
C4, D4, E4, F4, G4, A4, B4 = 60, 62, 64, 65, 67, 69, 71


def gen_bgm():
    # upbeat bright jazz-ish: C - Am - F - G
    gen_track("bgm_upbeat.wav", 152, 8, [
        (C4, [0, 4, 7], SCALE_MAJOR),
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
        (F4, [0, 4, 7], SCALE_MAJOR),
        (G4, [0, 4, 7], SCALE_MAJOR),
    ], kind="square", style="upbeat", seed=3, duty=0.5, lead_amp=0.2)

    # tense strings-ish: Am - F - G - E(harmonic minor)
    gen_track("bgm_tense.wav", 146, 8, [
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
        (F4, [0, 4, 7], SCALE_MAJOR),
        (G4, [0, 4, 7], SCALE_MAJOR),
        (E4, [0, 4, 8], [0, 1, 4, 5, 7, 8, 11]),
    ], kind="square", style="tense", seed=5, duty=0.25, lead_amp=0.21)

    # mystery / sneaky: Am - Dm - E - Am with swing
    gen_track("bgm_mystery.wav", 118, 8, [
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
        (D4, [0, 3, 7], SCALE_MINOR),
        (E4, [0, 4, 8], [0, 1, 4, 5, 7, 8, 11]),
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
    ], kind="tri", style="mystery", seed=7, swing=0.08, lead_amp=0.24)

    # warm / romantic: Fmaj7 - C - Am - G
    gen_track("bgm_warm.wav", 96, 8, [
        (F4, [0, 4, 7, 11], SCALE_MAJOR),
        (C4, [0, 4, 7], SCALE_MAJOR),
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
        (G4, [0, 4, 7], SCALE_MAJOR),
    ], kind="tri", style="calm", seed=11, dense=1, lead_amp=0.23, lead_oct=12)

    # sad / ending: Am - Em - F - C, sparse and slow
    gen_track("bgm_sad.wav", 74, 8, [
        (A4 - 12, [0, 3, 7], SCALE_MINOR),
        (E4, [0, 3, 7], SCALE_MINOR),
        (F4, [0, 4, 7], SCALE_MAJOR),
        (C4, [0, 4, 7], SCALE_MAJOR),
    ], kind="tri", style="sad", seed=13, dense=0.5, lead_amp=0.25)


def main():
    os.makedirs(OUT, exist_ok=True)
    gen_sfx()
    gen_bgm()
    for f in sorted(os.listdir(OUT)):
        print("%-22s %7.1f KB" % (f, os.path.getsize(os.path.join(OUT, f)) / 1024))


if __name__ == "__main__":
    main()
