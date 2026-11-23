# -*- coding: utf-8 -*-
"""Sanity check: re-read the generated Android vector drawables, turn them back
into SVG, render them, and compare against the brand master pixel by pixel."""
import os, site, sys
site.addsitedir(site.getusersitepackages())
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops, ImageStat
import export_assets as ex
import zemen_brand as z

A = '{http://schemas.android.com/apk/res/android}'
AAPT = '{http://schemas.android.com/aapt}'
defs, ids = [], [0]

def nid():
    ids[0] += 1
    return 'v%d' % ids[0]

def conv(e):
    if e.tag == 'group':
        t = 'translate(%s,%s) scale(%s,%s)' % (e.get(A + 'translateX', '0'), e.get(A + 'translateY', '0'),
                                               e.get(A + 'scaleX', '1'), e.get(A + 'scaleY', '1'))
        clip, kids = '', []
        for c in e:
            if c.tag == 'clip-path':
                i = nid(); defs.append('<clipPath id="%s"><path d="%s"/></clipPath>' % (i, c.get(A + 'pathData')))
                clip = ' clip-path="url(#%s)"' % i
            else:
                kids.append(conv(c))
        return '<g transform="%s"%s>%s</g>' % (t, clip, ''.join(kids))
    if e.tag == 'path':
        fill = e.get(A + 'fillColor')
        attr = e.find(AAPT + 'attr')
        if attr is not None:
            g = attr.find('gradient'); i = nid()
            defs.append('<linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="%s" y1="%s" x2="%s" y2="%s">%s</linearGradient>' % (
                i, g.get(A + 'startX'), g.get(A + 'startY'), g.get(A + 'endX'), g.get(A + 'endY'),
                ''.join('<stop offset="%s" stop-color="%s"/>' % (it.get(A + 'offset'), it.get(A + 'color')) for it in g)))
            fill = 'url(#%s)' % i
        s = ' fill="%s"' % (fill or 'none')
        if e.get(A + 'fillAlpha'): s += ' fill-opacity="%s"' % e.get(A + 'fillAlpha')
        if e.get(A + 'strokeColor'):
            s += ' stroke="%s" stroke-width="%s" stroke-linecap="%s" stroke-linejoin="%s"' % (
                e.get(A + 'strokeColor'), e.get(A + 'strokeWidth'), e.get(A + 'strokeLineCap'), e.get(A + 'strokeLineJoin'))
        return '<path d="%s"%s/>' % (e.get(A + 'pathData'), s)
    raise ValueError(e.tag)

def layer(name):
    root = ET.parse(os.path.join(z.OUT, 'android', 'drawable', name)).getroot()
    assert root.tag == 'vector' and root.get(A + 'viewportWidth') in ('108', '512'), root.attrib
    return ''.join(conv(c) for c in root)

body = layer('ic_launcher_background.xml') + layer('ic_launcher_foreground.xml')
z.write('svg/_vd_color.svg', '<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108"><defs>%s</defs>%s</svg>' % (''.join(defs), body))
defs[:] = []
mono = layer('ic_launcher_monochrome.xml')
z.write('svg/_vd_mono.svg', '<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" viewBox="0 0 108 108"><defs>%s</defs>%s</svg>' % (''.join(defs), mono))

full = ex.render('_vd_color', 432)
window = full.crop((72, 72, 360, 360)).convert('RGB')            # the 72dp launcher window
master = ex.render('zemen-app-icon', 1024).resize((288, 288), ex.LANCZOS).convert('RGB')
diff = ImageStat.Stat(ImageChops.difference(window, master))
print('colour layers vs master: mean abs diff per channel =', [round(v, 2) for v in diff.mean], 'max =', [e[1] for e in diff.extrema])

m = ex.render('_vd_mono', 432).crop((72, 72, 360, 360))
ref = ex.render('zemen-symbol-white', 1024)
s = int(round(288 * z.ICON_SCALE)); ref = ref.resize((s, s), ex.LANCZOS)
canvas = Image.new('RGBA', (288, 288), (0, 0, 0, 0)); canvas.paste(ref, ((288 - s) // 2, (288 - s) // 2))
d2 = ImageStat.Stat(ImageChops.difference(m.getchannel('A'), canvas.getchannel('A')))
print('monochrome layer vs master: mean abs alpha diff =', round(d2.mean[0], 2))
window.save(os.path.join(z.OUT, '_tmp', 'vd_window.png'))
for f in ('_vd_color.svg', '_vd_mono.svg'):
    os.remove(os.path.join(z.OUT, 'svg', f))
