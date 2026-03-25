#!/usr/bin/env python3
"""
Resize all 4:3 PNGs in a folder to 640x480, overwriting the originals.

Usage:
    py compress_3x4_pngs.py              # uses current folder
    py compress_3x4_pngs.py <folder>     # uses specified folder
"""

import sys
from pathlib import Path
from PIL import Image

TARGET_WIDTH = 640
TARGET_HEIGHT = 480
TARGET_RATIO = 4 / 3
RATIO_TOLERANCE = 0.02


def is_4x3(width: int, height: int) -> bool:
    if height == 0:
        return False
    return abs((width / height) - TARGET_RATIO) <= RATIO_TOLERANCE


def main():
    folder = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()

    if not folder.is_dir():
        print(f"ERROR: '{folder}' is not a valid directory.")
        sys.exit(1)

    png_files = sorted(folder.glob("*.png"))
    total = len(png_files)

    if total == 0:
        print(f"No PNG files found in '{folder}'.")
        sys.exit(0)

    print(f"Found {total} PNG file(s) in '{folder}'")
    print(f"Target: 640x480 — overwriting originals\n")

    done = 0
    skipped = 0
    errors = 0

    for i, src in enumerate(png_files, 1):
        print(f"[{i}/{total}] {src.name}", end=" ... ", flush=True)

        try:
            with Image.open(src) as img:
                w, h = img.size

                if not is_4x3(w, h):
                    print(f"SKIPPED (not 4:3, size is {w}x{h})")
                    skipped += 1
                    continue

                if w == TARGET_WIDTH and h == TARGET_HEIGHT:
                    print(f"SKIPPED (already 640x480)")
                    skipped += 1
                    continue

                orig_kb = src.stat().st_size / 1024
                resized = img.resize((TARGET_WIDTH, TARGET_HEIGHT), Image.LANCZOS)

            resized.save(src, format="PNG", compress_level=6, optimize=True)

            new_kb = src.stat().st_size / 1024
            savings = (1 - new_kb / orig_kb) * 100
            print(f"OK  {w}x{h} -> 640x480 | {orig_kb:.1f} KB -> {new_kb:.1f} KB ({savings:.1f}% smaller)")
            done += 1

        except Exception as e:
            print(f"ERROR — {e}")
            errors += 1

    print(f"\n--- Done ---")
    print(f"  Resized:  {done}")
    print(f"  Skipped:  {skipped}")
    print(f"  Errors:   {errors}")


if __name__ == "__main__":
    main()
