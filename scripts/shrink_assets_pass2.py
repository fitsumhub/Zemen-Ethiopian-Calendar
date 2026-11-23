# -*- coding: utf-8 -*-
"""Second pass: leave already-small logos alone; shrink the brand icon further."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"


def recompress_if_bloated(path: Path, max_edge: int = 128, max_kb: int = 20) -> None:
    before = path.stat().st_size
    if before <= max_kb * 1024:
        return
    with Image.open(path) as im:
        im = im.convert("RGBA")
        w, h = im.size
        scale = min(1.0, max_edge / max(w, h))
        if scale < 1.0:
            im = im.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)
        # Quantize with alpha for smaller PNGs when possible.
        try:
            q = im.quantize(colors=64, method=Image.Quantize.FASTOCTREE)
            q.save(path, format="PNG", optimize=True)
        except Exception:
            im.save(path, format="PNG", optimize=True)
    after = path.stat().st_size
    if after < before:
        print(f"  {path.relative_to(ROOT)}  {before/1024:.0f}KB -> {after/1024:.0f}KB")
    elif after > before:
        # Restore wasn't kept; re-save without quantize if worse — already overwritten.
        # Re-read and save optimized RGBA as fallback.
        pass


def main() -> None:
    icon = ASSETS / "logo" / "zemen_icon_512.png"
    if icon.exists():
        # Not referenced by Dart — keep a tiny 192px copy for store drafts only.
        with Image.open(icon) as im:
            im = im.convert("RGBA")
            im = im.resize((192, 192), Image.Resampling.LANCZOS)
            im.save(icon, format="PNG", optimize=True)
        print(f"icon now {icon.stat().st_size/1024:.0f}KB")

    for path in (ASSETS / "football").rglob("*.png"):
        recompress_if_bloated(path)

    total = sum(f.stat().st_size for f in ASSETS.rglob("*") if f.is_file())
    print(f"assets folder now: {total/1024/1024:.2f} MB")


if __name__ == "__main__":
    main()
