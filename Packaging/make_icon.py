#!/usr/bin/env python3
"""Draw the Reading Quest app icon into Packaging/AppIcon.iconset."""

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent / "AppIcon.iconset"

# filename, pixel size
SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]


def write_png(path: Path, size: int, pixels: bytes) -> None:
    raw = bytearray()
    row = size * 4
    for y in range(size):
        raw.append(0)
        raw.extend(pixels[y * row:(y + 1) * row])

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.write_bytes(png)


def in_round_rect(nx: float, ny: float, half: float, radius: float) -> bool:
    dx = abs(nx) - (half - radius)
    dy = abs(ny) - (half - radius)
    if dx <= 0 and dy <= 0:
        return True
    ox = max(dx, 0.0)
    oy = max(dy, 0.0)
    return ox * ox + oy * oy <= radius * radius


def in_star(nx: float, ny: float, cx: float, cy: float, outer: float) -> bool:
    # Five-point star around (cx, cy), y down.
    import math
    px = nx - cx
    py = ny - cy
    radius = math.hypot(px, py)
    if radius > outer:
        return False
    angle = math.atan2(py, px)
    # Map to a 5-point radius wobble.
    turn = (angle + math.pi / 2) % (2 * math.pi)
    spike = abs(((turn / (math.pi / 5)) % 2) - 1)
    limit = outer * (0.48 + 0.52 * spike)
    return radius <= limit


def render(size: int) -> bytes:
    buf = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            nx = (x + 0.5) / size - 0.5
            ny = (y + 0.5) / size - 0.5
            color = (0, 0, 0, 0)
            if in_round_rect(nx, ny, 0.46, 0.12):
                color = (20, 110, 74, 255)
            # cream book
            if -0.16 < nx < 0.16 and -0.02 < ny < 0.24:
                color = (248, 241, 224, 255)
            # gold spine
            if -0.015 < nx < 0.015 and -0.01 < ny < 0.22:
                color = (196, 138, 32, 255)
            # gold path under the book
            if -0.28 < nx < 0.28 and 0.28 < ny < 0.34:
                color = (255, 214, 110, 255)
            if in_star(nx, ny, 0.0, -0.20, 0.11):
                color = (255, 204, 70, 255)
            index = (y * size + x) * 4
            buf[index:index + 4] = bytes(color)
    return bytes(buf)


def main() -> None:
    ROOT.mkdir(parents=True, exist_ok=True)
    for name, size in SIZES:
        write_png(ROOT / name, size, render(size))
    print(f"Wrote {len(SIZES)} icons to {ROOT}")


if __name__ == "__main__":
    main()
