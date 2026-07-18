#!/usr/bin/env python3
"""Generate PWA icons for Rewire prototype."""
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Install Pillow: pip install pillow")
    raise

OUT = Path(__file__).parent
INK = (7, 7, 12)
CHOOSE = (139, 123, 255)
ACCEPT = (62, 221, 197)
TEXT = (244, 242, 236)


def draw_mark(draw, size, cx, cy, outer_r):
    draw.ellipse(
        (cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r),
        outline=CHOOSE + (90,),
        width=max(1, size // 180),
    )
    inner_r = outer_r * 0.55
    bbox = (cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r)
    draw.ellipse(bbox, fill=TEXT + (230,))
    draw.ellipse(bbox, fill=CHOOSE + (140,))


def render(size, filename):
    img = Image.new("RGBA", (size, size), INK + (255,))
    draw = ImageDraw.Draw(img)
    cx = cy = size // 2
    outer_r = int(size * 0.36)
    draw_mark(draw, size, cx, cy, outer_r)
    img.save(OUT / filename, "PNG")
    print(f"wrote {filename}")


if __name__ == "__main__":
    render(180, "apple-touch-icon.png")
    render(192, "icon-192.png")
    render(512, "icon-512.png")
