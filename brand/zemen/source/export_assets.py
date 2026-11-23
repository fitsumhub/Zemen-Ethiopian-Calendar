# -*- coding: utf-8 -*-
"""Rasterise the ZEMEN vector masters into production PNGs.

Builds the SVG masters first (zemen_brand.build), renders each one with a
headless Chromium-based browser, then derives every size with Pillow.

Usage: python -I export_assets.py <fonts_dir> <out_dir>
Set CHROME to a browser executable if it is not found automatically.
"""
import os
import re
import site
import subprocess
import sys

site.addsitedir(site.getusersitepackages())
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from PIL import Image, ImageDraw  # noqa: E402

import zemen_brand as z  # noqa: E402

OUT = z.OUT
CANDIDATES = [
    os.environ.get('CHROME', ''),
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    '/usr/bin/google-chrome', '/usr/bin/chromium',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
]
CHROME = next((c for c in CANDIDATES if c and os.path.exists(c)), None)
LANCZOS = Image.Resampling.LANCZOS


def viewbox(svg_path):
    with open(svg_path, encoding='utf-8') as fh:
        m = re.search(r'viewBox="([-\d. ]+)"', fh.read(2000))
    x, y, w, h = [float(v) for v in m.group(1).split()]
    return w, h


def render(svg_name, width):
    """Render out/svg/<svg_name>.svg at `width` px wide (transparent)."""
    src = os.path.join(OUT, 'svg', svg_name + '.svg')
    vw, vh = viewbox(src)
    w, h = int(round(width)), int(round(width * vh / vw))
    tmp = os.path.join(OUT, '_tmp')
    os.makedirs(tmp, exist_ok=True)
    page = os.path.join(tmp, svg_name + '.html')
    png = os.path.join(tmp, svg_name + '.png')
    with open(page, 'w', encoding='utf-8') as fh:
        fh.write('<!doctype html><html><body style="margin:0;background:transparent;overflow:hidden">'
                 '<img src="file:///%s" style="display:block;width:%dpx;height:%dpx"></body></html>'
                 % (src.replace('\\', '/'), w, h))
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    '--force-device-scale-factor=1', '--user-data-dir=' + os.path.join(OUT, '_chrome'),
                    '--window-size=%d,%d' % (w, h), '--default-background-color=00000000',
                    '--screenshot=' + png, 'file:///' + page.replace('\\', '/')],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    im = Image.open(png).convert('RGBA')
    assert im.size == (w, h), (svg_name, im.size, (w, h))
    return im


def save(im, rel):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)
    return rel


def scaled(im, size):
    return im.resize((size, int(round(size * im.height / im.width))), LANCZOS)


def on_solid(im, color):
    bg = Image.new('RGBA', im.size, color)
    bg.alpha_composite(im)
    return bg.convert('RGB')


def shaped(icon, size, kind):
    """Legacy launcher bitmap: the icon inside a baked rounded square or circle."""
    ss = 4
    box = size * ss
    shape = int(round(box * 44 / 48))
    off = (box - shape) // 2
    mask = Image.new('L', (box, box), 0)
    d = ImageDraw.Draw(mask)
    if kind == 'round':
        d.ellipse([off, off, off + shape - 1, off + shape - 1], fill=255)
    else:
        d.rounded_rectangle([off, off, off + shape - 1, off + shape - 1], radius=int(shape * 0.22), fill=255)
    canvas = Image.new('RGBA', (box, box), (0, 0, 0, 0))
    canvas.paste(icon.resize((shape, shape), LANCZOS), (off, off))
    canvas.putalpha(mask)
    return canvas.resize((size, size), LANCZOS)


def main():
    if not CHROME:
        sys.exit('No Chromium-based browser found. Set CHROME=<path to chrome or msedge>.')
    z.build()
    done = []

    icon = render('zemen-app-icon', 1024)
    done.append(save(icon.convert('RGB'), 'png/zemen-app-icon-1024.png'))
    done.append(save(scaled(icon, 512).convert('RGB'), 'png/zemen-play-store-icon-512.png'))
    for dpi, px in (('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)):
        done.append(save(shaped(icon, px, 'square'), 'android/mipmap-%s/ic_launcher.png' % dpi))
        done.append(save(shaped(icon, px, 'round'), 'android/mipmap-%s/ic_launcher_round.png' % dpi))

    for name, sizes in (('zemen-mark', (1024, 512, 192, 96, 48)),
                        ('zemen-mark-simple', (512, 192, 96, 48)),
                        ('zemen-symbol-white', (512, 96, 48, 24)),
                        ('zemen-symbol-black', (512, 96, 48, 24)),
                        ('zemen-symbol-emerald', (512, 96, 48))):
        base = render(name, 1024)
        for s in sizes:
            done.append(save(scaled(base, s), 'png/%s-%d.png' % (name, s)))

    for mode, bg in (('dark', z.BLACK), ('light', z.WHITE)):
        for kind, width in (('stacked', 1200), ('horizontal', 1800), ('compact', 1400)):
            name = 'zemen-logo-%s-on-%s' % (kind, mode)
            im = render(name, width)
            done.append(save(im, 'png/%s.png' % name))
            done.append(save(on_solid(im, bg), 'png/%s-solid.png' % name))
        name = 'zemen-wordmark-on-%s' % mode
        done.append(save(render(name, 1200), 'png/%s.png' % name))

    for f in done:
        print(f)


if __name__ == '__main__':
    main()
