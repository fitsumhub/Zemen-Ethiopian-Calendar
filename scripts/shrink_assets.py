# -*- coding: utf-8 -*-
"""Compress bundled images for a smaller APK.

Football logos are shown at ~24–52 logical px; 128px source is plenty.
Brand mark is shown up to ~128px; keep a small JPEG.
"""
from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"

# Max edge for football logos (displayed tiny in-app).
FOOTBALL_MAX = 128
# Brand logo used in UI (onboarding/settings).
LOGO_MAX = 256
# Play-store style icon asset if kept in assets/logo.
ICON_MAX = 512


def compress_png(path: Path, max_edge: int) -> tuple[int, int]:
    before = path.stat().st_size
    with Image.open(path) as im:
        im = im.convert("RGBA")
        w, h = im.size
        scale = min(1.0, max_edge / max(w, h))
        if scale < 1.0:
            im = im.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)
        # Flatten nearly-opaque images to RGB+palette for big savings.
        alpha = im.split()[-1]
        if alpha.getextrema()[0] >= 250:
            rgb = Image.new("RGB", im.size, (255, 255, 255))
            rgb.paste(im, mask=alpha)
            rgb.save(path, format="PNG", optimize=True)
        else:
            im.save(path, format="PNG", optimize=True)
    after = path.stat().st_size
    return before, after


def compress_jpeg(path: Path, max_edge: int, quality: int = 82) -> tuple[int, int]:
    before = path.stat().st_size
    with Image.open(path) as im:
        im = im.convert("RGB")
        w, h = im.size
        scale = min(1.0, max_edge / max(w, h))
        if scale < 1.0:
            im = im.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)
        im.save(path, format="JPEG", quality=quality, optimize=True, progressive=True)
    after = path.stat().st_size
    return before, after


def main() -> None:
    # Unused concept art — do not ship in the app bundle.
    unused = [
        ASSETS / "logo" / "ethiocal_logo_concept_a.jpg",
        ASSETS / "logo" / "ethiocal_logo_concept_b.jpg",
    ]
    archive = ROOT / "brand" / "unused-assets"
    archive.mkdir(parents=True, exist_ok=True)
    moved = 0
    for f in unused:
        if f.exists():
            dest = archive / f.name
            shutil.move(str(f), str(dest))
            moved += 1
            print(f"moved unused {f.name} -> brand/unused-assets/")

    # Test vectors are only for tests — keep on disk but out of Flutter assets.
    vectors = ASSETS / "data" / "ethiopian_calendar" / "calendar_test_vectors.json"
    test_data = ROOT / "test" / "fixtures"
    if vectors.exists():
        test_data.mkdir(parents=True, exist_ok=True)
        dest = test_data / "calendar_test_vectors.json"
        shutil.copy2(vectors, dest)
        vectors.unlink()
        print(f"moved {vectors.name} -> test/fixtures/ ({dest.stat().st_size/1024:.0f} KB)")

    saved = 0
    total_before = 0
    total_after = 0

    for folder, max_edge in (
        (ASSETS / "football" / "teams", FOOTBALL_MAX),
        (ASSETS / "football" / "leagues", FOOTBALL_MAX),
    ):
        for path in sorted(folder.glob("*.png")):
            b, a = compress_png(path, max_edge)
            total_before += b
            total_after += a
            saved += b - a
            if b != a:
                print(f"  {path.relative_to(ROOT)}  {b/1024:.0f}KB -> {a/1024:.0f}KB")

    logo = ASSETS / "logo" / "zemen_logo.jpg"
    if logo.exists():
        b, a = compress_jpeg(logo, LOGO_MAX, quality=85)
        total_before += b
        total_after += a
        saved += b - a
        print(f"  {logo.relative_to(ROOT)}  {b/1024:.0f}KB -> {a/1024:.0f}KB")

    icon = ASSETS / "logo" / "zemen_icon_512.png"
    if icon.exists():
        b, a = compress_png(icon, ICON_MAX)
        total_before += b
        total_after += a
        saved += b - a
        print(f"  {icon.relative_to(ROOT)}  {b/1024:.0f}KB -> {a/1024:.0f}KB")

    assets_total = sum(f.stat().st_size for f in ASSETS.rglob("*") if f.is_file())
    print(f"\ncompressed delta: -{saved/1024/1024:.2f} MB  ({total_before/1024/1024:.2f} -> {total_after/1024/1024:.2f})")
    print(f"assets folder now: {assets_total/1024/1024:.2f} MB")
    print(f"unused moved: {moved}")


if __name__ == "__main__":
    main()
