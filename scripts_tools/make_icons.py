#!/usr/bin/env python3
"""Draws the app icons with pure Python (no dependencies).
Outputs (original artwork, CC0):
  assets/icons/icon_192.png, icon_foreground.png, icon_background.png, icon_monochrome.png
  store/icon_512.png, store/feature_art.png (background art for the feature graphic)
Run:  python3 scripts_tools/make_icons.py
"""
import os, struct, zlib

ROOT = os.path.join(os.path.dirname(__file__), "..")
SS = 3  # supersampling per axis

# --- tiny PNG writer ---------------------------------------------------------
def write_png(path, w, h, buf):  # buf: list of (r,g,b,a) floats 0..1, row-major
    raw = bytearray()
    for y in range(h):
        raw.append(0)
        for x in range(w):
            r, g, b, a = buf[y * w + x]
            raw += bytes((int(max(0, min(1, r)) * 255 + .5), int(max(0, min(1, g)) * 255 + .5),
                          int(max(0, min(1, b)) * 255 + .5), int(max(0, min(1, a)) * 255 + .5)))
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "wb").write(png)

# --- canvas with SDF shapes --------------------------------------------------
class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.aspect = w / h   # canvas units: x in widths, y in heights; shapes are drawn in width units
        self.buf = [(0.0, 0.0, 0.0, 0.0)] * (w * h)

    def gradient(self, c1, c2):
        for y in range(self.h):
            for x in range(self.w):
                t = (x / self.w + y / self.h) / 2
                self.buf[y * self.w + x] = tuple(c1[i] + (c2[i] - c1[i]) * t for i in range(3)) + (1.0,)

    def fill(self, color):
        self.buf = [color] * (self.w * self.h)

    def shape(self, inside, bbox, color):
        """inside(u,v) in 0..1 canvas units; bbox=(u0,v0,u1,v1)."""
        x0 = max(0, int(bbox[0] * self.w)); x1 = min(self.w, int(bbox[2] * self.w) + 2)
        y0 = max(0, int(bbox[1] * self.h)); y1 = min(self.h, int(bbox[3] * self.h) + 2)
        n = SS * SS
        for y in range(y0, y1):
            for x in range(x0, x1):
                hit = 0
                for sy in range(SS):
                    for sx in range(SS):
                        if inside((x + (sx + .5) / SS) / self.w, (y + (sy + .5) / SS) / self.h):
                            hit += 1
                if hit:
                    a = hit / n * color[3]
                    br, bg, bb, ba = self.buf[y * self.w + x]
                    oa = a + ba * (1 - a)
                    if oa > 0:
                        self.buf[y * self.w + x] = tuple(
                            (color[i] * a + (br, bg, bb)[i] * ba * (1 - a)) / oa for i in range(3)) + (oa,)

    def rrect(self, cx, cy, w, h, r, color):
        aspect = self.aspect
        # coordinates are in canvas-width units; y scaled by aspect (w/h of canvas)
        def inside(u, v):
            x = abs(u - cx) - (w / 2 - r); y = abs((v - cy) / aspect) - (h / 2 - r)
            if x < 0 and y < 0: return True
            return max(x, 0) ** 2 + max(y, 0) ** 2 <= r * r
        self.shape(inside, (cx - w / 2, cy - h / 2 * aspect, cx + w / 2, cy + h / 2 * aspect), color)

    def capsule(self, x1, y1, x2, y2, r, color):
        a = self.aspect
        def inside(u, v):
            dx, dy = x2 - x1, (y2 - y1) / a
            l2 = dx * dx + dy * dy
            pu, pv = u - x1, (v - y1) / a
            t = 0 if l2 == 0 else max(0, min(1, (pu * dx + pv * dy) / l2))
            return (pu - t * dx) ** 2 + (pv - t * dy) ** 2 <= r * r
        ry = r * a
        self.shape(inside, (min(x1, x2) - r, min(y1, y2) - ry, max(x1, x2) + r, max(y1, y2) + ry), color)

# 7-segment digits: segments a(top) b(top-right) c(bottom-right) d(bottom) e(bottom-left) f(top-left) g(middle)
SEG = {1: "bc", 2: "abged", 3: "abgcd", 4: "fgbc", 5: "afgcd", 6: "afgedc", 7: "abc", 8: "abcdefg", 9: "abcdfg"}
def digit(c, d, cx, cy, size, thick, color):
    hw, hh = size * 0.32, size * 0.5 * c.aspect
    P = {"a": (-hw, -hh, hw, -hh), "d": (-hw, hh, hw, hh), "g": (-hw, 0, hw, 0),
         "f": (-hw, -hh, -hw, 0), "b": (hw, -hh, hw, 0), "e": (-hw, 0, -hw, hh), "c": (hw, 0, hw, hh)}
    for s in SEG[d]:
        x1, y1, x2, y2 = P[s]
        c.capsule(cx + x1, cy + y1, cx + x2, cy + y2, thick, color)

TOP, SIDE = (0.97, 0.97, 1.0, 1.0), (0.62, 0.69, 0.88, 1.0)
BLUE, DARK = (0.12, 0.38, 0.85, 1.0), (0.10, 0.12, 0.18, 1.0)
GRID = [[5, 3, 0], [0, 7, 2], [8, 0, 4]]
COLORS = [[DARK, DARK, 0], [0, BLUE, DARK], [BLUE, 0, DARK]]

def draw_tiles(c, cx, cy, extent, mono=False, digits=True):
    """3x3 grid of raised rounded tiles centred at (cx,cy); extent = grid width in canvas units."""
    pitch = extent / 3
    s = pitch * 0.88
    depth = s * 0.16
    for r in range(3):
        for k in range(3):
            x = cx + (k - 1) * pitch
            y = cy + ((r - 1) * pitch - depth / 2) * c.aspect
            if mono:
                c.rrect(x, y + depth / 2 * c.aspect, s, s, s * 0.2, (1, 1, 1, 1))
                continue
            c.rrect(x, y + depth * c.aspect, s, s, s * 0.2, (0.05, 0.12, 0.35, 0.35))      # soft shadow
            c.rrect(x, y + depth * 0.55 * c.aspect, s, s, s * 0.2, SIDE)                    # tile side (3D thickness)
            c.rrect(x, y, s, s, s * 0.2, TOP)                                    # tile top
            if digits and GRID[r][k]:
                digit(c, GRID[r][k], x, y, s * 0.56, s * 0.045, COLORS[r][k])

def icon(size, bg=True, fg=True, mono=False, extent=0.66):
    c = Canvas(size, size)
    if bg:
        c.gradient((0.30, 0.58, 0.99), (0.08, 0.24, 0.66))
    if fg:
        draw_tiles(c, 0.5, 0.5, extent, mono=mono)
    return c

if __name__ == "__main__":
    out = lambda *p: os.path.join(ROOT, *p)
    write_png(out("store", "icon_512.png"), 512, 512, icon(512).buf)
    write_png(out("assets", "icons", "icon_192.png"), 192, 192, icon(192).buf)
    # Adaptive icon layers (432px). Content must sit inside the central 66% safe zone.
    write_png(out("assets", "icons", "icon_background.png"), 432, 432, icon(432, fg=False).buf)
    write_png(out("assets", "icons", "icon_foreground.png"), 432, 432, icon(432, bg=False, extent=0.50).buf)
    write_png(out("assets", "icons", "icon_monochrome.png"), 432, 432, icon(432, bg=False, mono=True, extent=0.50).buf)
    # Feature graphic background art (1024x500): gradient + tile grid on the right.
    fa = Canvas(1024, 500)
    fa.gradient((0.30, 0.58, 0.99), (0.08, 0.24, 0.66))
    draw_tiles(fa, 820 / 1024, 0.5, 370 / 1024, digits=True)
    # aspect: canvas is non-square, so tile geometry above is in width units; correct y spacing
    write_png(out("store", "feature_art_raw.png"), 1024, 500, fa.buf)
    print("icons written")
