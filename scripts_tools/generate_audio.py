#!/usr/bin/env python3
"""Generates all sound effects and the music loop procedurally (pure stdlib).
The output is original work released under CC0 - no third-party audio is used.
Run:  python3 scripts_tools/generate_audio.py   (writes assets/audio/*.wav)
"""
import math, random, struct, wave, os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(7)

def save(name, samples, peak=0.85):
    m = max(1e-9, max(abs(s) for s in samples))
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s / m * peak)) * 32767)) for s in samples)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)

def note(freq, dur, vol=1.0, attack=0.005, decay=6.0, wave_fn=None, delay=0.0, total=None):
    n = int(SR * (total if total else dur + delay))
    out = [0.0] * n
    start = int(SR * delay)
    for i in range(int(SR * dur)):
        t = i / SR
        env = min(1.0, t / attack) * math.exp(-decay * t)
        ph = 2 * math.pi * freq * t
        s = wave_fn(ph) if wave_fn else (math.sin(ph) + 0.3 * math.sin(2 * ph) + 0.1 * math.sin(3 * ph))
        if start + i < n:
            out[start + i] += s * env * vol
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out

def midi(m): return 440.0 * 2 ** ((m - 69) / 12)

# --- sound effects ---------------------------------------------------------
save("click", note(1400, 0.04, decay=60, attack=0.001))
save("select", note(700, 0.07, decay=35))
save("place", mix(note(midi(72), 0.18, decay=14), note(midi(79), 0.22, decay=12, delay=0.06)))
square = lambda ph: 1.0 if math.sin(ph) >= 0 else -1.0
save("wrong", mix(note(150, 0.28, decay=7, wave_fn=square, vol=0.6), note(158, 0.28, decay=7, wave_fn=square, vol=0.6)))
noise = [random.uniform(-1, 1) * math.exp(-28 * i / SR) * min(1, i / (0.01 * SR)) for i in range(int(SR * 0.14))]
save("erase", noise, peak=0.5)
save("hint", mix(*[note(midi(m), 0.35, decay=8, delay=0.09 * k) for k, m in enumerate([76, 83, 88])]))
save("complete", mix(*[note(midi(m), 0.4, decay=7, delay=0.07 * k) for k, m in enumerate([72, 76, 79, 84])]))
save("win", mix(*[note(midi(m), 0.7, decay=3.5, delay=0.14 * k) for k, m in enumerate([72, 76, 79, 84, 88, 91])],
                *[note(midi(m), 1.2, decay=2.5, delay=0.84, vol=0.5) for m in (60, 67, 72)]))
save("lose", mix(*[note(midi(m), 0.5, decay=5, delay=0.2 * k) for k, m in enumerate([67, 63, 60, 55])]))

# --- music loop: Am - F - C - G, soft pads + slow arpeggio, seamless -----------
BAR = 8.0
chords = [(57, 60, 64), (53, 57, 60), (48, 52, 55), (55, 59, 62)]
total = int(SR * BAR * len(chords))
buf = [0.0] * total
def add_wrapped(track, start):
    for i, v in enumerate(track):
        buf[(start + i) % total] += v          # tail wraps to the start -> seamless loop
for ci, ch in enumerate(chords):
    start = int(SR * BAR * ci)
    for m in ch:
        for detune in (-0.4, 0.4):
            dur = BAR + 3.0
            pad = []
            f = midi(m) * 2 ** (detune / 12 / 10)
            for i in range(int(SR * dur)):
                t = i / SR
                env = min(1.0, t / 2.5) * (1.0 if t < BAR else math.exp(-1.6 * (t - BAR)))
                pad.append(math.sin(2 * math.pi * f * t) * env * 0.12)
            add_wrapped(pad, start)
    for k in range(8):                         # gentle arpeggio, 1 note per second
        m = ch[k % 3] + 12 + (12 if k % 4 == 3 else 0)
        add_wrapped(note(midi(m), 1.6, vol=0.22, decay=2.8, attack=0.01), start + int(SR * k))
save("music", buf, peak=0.6)
print("wrote audio to", os.path.abspath(OUT))
