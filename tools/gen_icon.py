"""Generate the WOD Timer launcher icon (resources/drawables/launcher_icon.png).

Pure standard library so it runs anywhere: shapes are rasterized with 4x
supersampling and written as an RGBA PNG. The Connect IQ resource compiler
rescales the 70 px source to each device's launcher size.

Usage (from the project root):
    python3 tools/gen_icon.py
"""

from __future__ import annotations

import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "resources", "drawables", "launcher_icon.png")

SIZE = 70
SUPERSAMPLE = 4

BACKGROUND = (18, 18, 18)
WORK_GREEN = (0, 214, 110)
REST_RED = (255, 64, 64)
WHITE = (255, 255, 255)

Color = tuple[int, int, int]


def _angle_deg(dx: float, dy: float) -> float:
    """Clockwise angle from 12 o'clock, in degrees [0, 360)."""
    return (math.degrees(math.atan2(dx, -dy)) + 360.0) % 360.0


def _pixel_color(x: float, y: float) -> Color | None:
    """Return the icon color at a point in icon units, or None if transparent."""
    c = SIZE / 2.0
    dx, dy = x - c, y - c + 2.0
    r = math.hypot(dx, dy)
    outer = SIZE * 0.40

    # Stopwatch crown and side button sit outside the dial.
    if abs(x - c) <= 4.0 and 3.0 <= y <= 8.0:
        return WHITE
    if abs(x - c) <= 7.0 and 1.0 <= y <= 4.0:
        return WHITE

    if r > outer:
        return None

    ring_inner = outer - 6.5
    if r >= ring_inner:
        angle = _angle_deg(dx, dy)
        return WORK_GREEN if angle <= 270.0 else REST_RED

    # Hand pointing at the end of the work arc (9 o'clock) and a hub.
    if r <= 3.2:
        return WHITE
    if -dx >= 0 and abs(dy) <= 1.8 and -dx <= ring_inner - 6.0:
        return WHITE
    return BACKGROUND


def _render() -> list[bytes]:
    """Rasterize the icon into PNG scanlines (filter byte + RGBA pixels)."""
    rows: list[bytes] = []
    step = 1.0 / SUPERSAMPLE
    samples = SUPERSAMPLE * SUPERSAMPLE
    for py in range(SIZE):
        row = bytearray([0])
        for px in range(SIZE):
            acc = [0, 0, 0]
            hits = 0
            for sy in range(SUPERSAMPLE):
                for sx in range(SUPERSAMPLE):
                    color = _pixel_color(px + (sx + 0.5) * step, py + (sy + 0.5) * step)
                    if color is not None:
                        hits += 1
                        for i in range(3):
                            acc[i] += color[i]
            if hits == 0:
                row.extend((0, 0, 0, 0))
            else:
                rgb = [v // hits for v in acc]
                row.extend((*rgb, round(255 * hits / samples)))
        rows.append(bytes(row))
    return rows


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    """Encode one PNG chunk with its CRC."""
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))


def write_png(path: str) -> None:
    """Render the icon and write it to `path`."""
    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0)
    pixels = zlib.compress(b"".join(_render()), 9)
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(_png_chunk(b"IHDR", header))
        handle.write(_png_chunk(b"IDAT", pixels))
        handle.write(_png_chunk(b"IEND", b""))


if __name__ == "__main__":
    write_png(OUT)
