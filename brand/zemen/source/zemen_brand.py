# -*- coding: utf-8 -*-
"""ZEMEN brand identity - vector master generator.

Everything is geometry. The mark and the Latin wordmark are constructed
polygons; the Amharic name and the tagline are real font outlines (OFL
fonts: Noto Sans Ethiopic, Outfit) converted to paths, so no output file
depends on an installed font.

Usage: python -I zemen_brand.py <fonts_dir> <out_dir>
"""
import math
import os
import site
import sys

site.addsitedir(site.getusersitepackages())

from fontTools.pens.boundsPen import BoundsPen  # noqa: E402
from fontTools.pens.recordingPen import RecordingPen  # noqa: E402
from fontTools.pens.svgPathPen import SVGPathPen  # noqa: E402
from fontTools.pens.transformPen import TransformPen  # noqa: E402
from fontTools.ttLib import TTFont  # noqa: E402
from fontTools.varLib.instancer import instantiateVariableFont  # noqa: E402
import uharfbuzz as hb  # noqa: E402

FONTS = sys.argv[1]
OUT = sys.argv[2]

# ---------------------------------------------------------------- palette
BLACK = '#080B09'
EMERALD = '#00C853'
GOLD = '#FFD700'
WHITE = '#FFFFFF'
DGREEN = '#063D27'

TAGLINE = 'Your Time. Your Tradition. Your Calendar.'
AMHARIC = 'ዘመን'  # ዘመን
ETH_FONT = 'NotoSansEthiopic-VF.ttf'
LAT_FONT = 'Outfit-VF.ttf'

MODES = {
    'dark': dict(word=WHITE, accent=EMERALD, amh=GOLD, rule=GOLD, tag='#C4CEC8', bg=BLACK),
    'light': dict(word=BLACK, accent=EMERALD, amh=DGREEN, rule=EMERALD, tag='#33413A', bg=WHITE),
}


# ---------------------------------------------------------------- helpers
def n(v):
    s = ('%.2f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def nf(v):
    """Higher precision for scales and offsets (two decimals would drift)."""
    s = ('%.5f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def poly(pts):
    return 'M' + ' L'.join('%s,%s' % (n(x), n(y)) for x, y in pts) + ' Z'


def rrect(x, y, w, h, r):
    r = min(r, w / 2, h / 2)
    if r <= 0:
        return poly([(x, y), (x + w, y), (x + w, y + h), (x, y + h)])
    return ('M%s,%s H%s A%s,%s 0 0 1 %s,%s V%s A%s,%s 0 0 1 %s,%s '
            'H%s A%s,%s 0 0 1 %s,%s V%s A%s,%s 0 0 1 %s,%s Z') % (
        n(x + r), n(y), n(x + w - r), n(r), n(r), n(x + w), n(y + r),
        n(y + h - r), n(r), n(r), n(x + w - r), n(y + h),
        n(x + r), n(r), n(r), n(x), n(y + h - r),
        n(y + r), n(r), n(r), n(x + r), n(y))


def circle(cx, cy, r):
    return 'M%s,%s A%s,%s 0 1 0 %s,%s A%s,%s 0 1 0 %s,%s Z' % (
        n(cx - r), n(cy), n(r), n(r), n(cx + r), n(cy),
        n(r), n(r), n(cx - r), n(cy))


def diamond(cx, cy, r):
    return poly([(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)])


def lin(x1, y1, x2, y2, *stops):
    return ('lin', x1, y1, x2, y2, stops)


# ------------------------------------------------------------ mark (512 grid)
M = 512.0
TX, TY, TS, TR = 64.0, 88.0, 384.0, 76.0      # calendar tile
BAND = 80.0                                   # Z bar thickness (top bar = calendar header)
DW = 116.0                                    # diagonal horizontal width
Y1 = TY + BAND                                # underside of the top bar
Y2 = TY + TS - BAND                           # top of the bottom bar
RING_X = (176.0, 336.0)
RING_W, RING_TOP, RING_H = 30.0, 44.0, 80.0
SLOT = 7.0                                    # gap around a ring
CLOCK = (376.65, 320.65, 50.0)                # incircle of the lower counter
MARK_BOX = (TX, RING_TOP, TX + TS, TY + TS)   # visible bounds of the mark


def diagonal():
    return poly([(TX + TS - DW, Y1), (TX + TS, Y1), (TX + DW, Y2), (TX, Y2)])


def ring(cx):
    return rrect(cx - RING_W / 2, RING_TOP, RING_W, RING_H, RING_W / 2)


def ring_slot(cx):
    w = RING_W + 2 * SLOT
    y0 = TY - 40
    return rrect(cx - w / 2, y0, w, RING_TOP + RING_H + SLOT - y0, w / 2)


def date_cells():
    ox, oy, px, py, cw, ch = 90.0, Y1 + 26.0, 52.0, 43.5, 38.0, 30.0
    return [rrect(ox + col * px, oy + row * py, cw, ch, 8)
            for row in range(3) for col in range(3 - row)]


def tibeb(cy=432.0, count=13, pitch=26.0, r=10.5):
    """Hem pattern: 12 diamonds + one small gold diamond = 13 months."""
    x0 = M / 2 - (count - 1) * pitch / 2
    big = [diamond(x0 + i * pitch, cy, r) for i in range(count - 1)]
    holes = [diamond(x0 + i * pitch, cy, r * 0.36) for i in range(count - 1)]
    last = diamond(x0 + (count - 1) * pitch, cy, r * 0.72)
    return big, holes, last


def clock_hands():
    cx, cy, r = CLOCK

    def tip(deg, length):
        a = math.radians(deg - 90)
        return cx + math.cos(a) * length, cy + math.sin(a) * length
    hx, hy = tip(120, r * 0.44)       # hour hand -> 4
    mx, my = tip(0, r * 0.62)         # minute hand -> 12
    return 'M%s,%s L%s,%s L%s,%s' % (n(mx), n(my), n(cx), n(cy), n(hx), n(hy))


GOLD_V = ((0, '#FFE352'), (1, '#F2C200'))


def mark_layers(detail=True, clock=True):
    """Full-colour mark as paint layers: (clip path, clipped layers, free layers)."""
    cx, cy, r = CLOCK
    L = [
        dict(d=rrect(TX, TY, TS, TS, 0), fill=lin(0, TY, 0, TY + TS, (0, '#0B5033'), (1, '#062E1E'))),
        dict(d=poly([(TX, TY), (TX + TS, TY), (TX + TS, Y1), (TX, Y1)]),
             fill=lin(0, TY, 0, Y1, (0, '#19D469'), (1, '#00BC4D'))),
        dict(d=poly([(TX, Y2), (TX + TS, Y2), (TX + TS, TY + TS), (TX, TY + TS)]),
             fill=lin(0, Y2, 0, TY + TS, (0, '#00C853'), (1, '#00A843'))),
        dict(d=diagonal(), fill=lin(TX + TS, Y1, TX, Y2, (0, '#009A40'), (0.26, '#00C853'), (1, '#00BB4E'))),
    ]
    if detail:
        L.append(dict(d=' '.join(date_cells()), fill=WHITE, alpha=0.94))
        big, holes, last = tibeb()
        L.append(dict(d=' '.join(big), fill=DGREEN, alpha=0.62))
        L.append(dict(d=' '.join(holes), fill=EMERALD))
        L.append(dict(d=last, fill=GOLD))
    if clock:
        L.append(dict(d=circle(cx, cy, r), fill=lin(0, cy - r, 0, cy + r, *GOLD_V)))
        if detail:
            L.append(dict(d=clock_hands(), stroke=(DGREEN, 9.0)))
    L.append(dict(d=' '.join(ring_slot(x) for x in RING_X), fill=DGREEN))
    free = [dict(d=' '.join(ring(x) for x in RING_X),
                 fill=lin(0, RING_TOP, 0, RING_TOP + RING_H, *GOLD_V))]
    return rrect(TX, TY, TS, TS, TR), L, free


def mono_paths():
    """Single-colour symbol: the Z with calendar rings, counters open."""
    s = RING_W / 2 + SLOT
    yb = RING_TOP + RING_H + SLOT - s
    top = 'M%s,%s V%s A%s,%s 0 0 1 %s,%s' % (n(TX), n(Y1), n(TY + TR), n(TR), n(TR), n(TX + TR), n(TY))
    for cx in RING_X:
        top += ' H%s V%s A%s,%s 0 0 0 %s,%s V%s' % (n(cx - s), n(yb), n(s), n(s), n(cx + s), n(yb), n(TY))
    top += ' H%s A%s,%s 0 0 1 %s,%s V%s Z' % (n(TX + TS - TR), n(TR), n(TR), n(TX + TS), n(TY + TR), n(Y1))
    bottom = 'M%s,%s H%s V%s A%s,%s 0 0 1 %s,%s H%s A%s,%s 0 0 1 %s,%s Z' % (
        n(TX), n(Y2), n(TX + TS), n(TY + TS - TR), n(TR), n(TR), n(TX + TS - TR), n(TY + TS),
        n(TX + TR), n(TR), n(TR), n(TX), n(TY + TS - TR))
    return [top, diagonal(), bottom] + [ring(cx) for cx in RING_X]


# ---------------------------------------------------------- SVG serialisers
def _svg_path(layer, gid, defs):
    f = layer.get('fill')
    a = ''
    if isinstance(f, tuple):
        _, x1, y1, x2, y2, stops = f
        defs.append('<linearGradient id="%s" gradientUnits="userSpaceOnUse" x1="%s" y1="%s" x2="%s" y2="%s">%s</linearGradient>' % (
            gid, n(x1), n(y1), n(x2), n(y2),
            ''.join('<stop offset="%s" stop-color="%s"/>' % (n(o), c) for o, c in stops)))
        a += ' fill="url(#%s)"' % gid
    elif f:
        a += ' fill="%s"' % f
    else:
        a += ' fill="none"'
    if 'alpha' in layer:
        a += ' fill-opacity="%s"' % n(layer['alpha'])
    if 'stroke' in layer:
        a += ' stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round"' % (
            layer['stroke'][0], n(layer['stroke'][1]))
    return '<path d="%s"%s/>' % (layer['d'], a)


def mark_full(u, detail=True, clock=True):
    clip, clipped, free = mark_layers(detail, clock)
    defs = ['<clipPath id="%s-c"><path d="%s"/></clipPath>' % (u, clip)]
    a = [_svg_path(l, '%s-a%d' % (u, i), defs) for i, l in enumerate(clipped)]
    b = [_svg_path(l, '%s-b%d' % (u, i), defs) for i, l in enumerate(free)]
    return '<defs>%s</defs><g clip-path="url(#%s-c)">%s</g>%s' % (''.join(defs), u, ''.join(a), ''.join(b))


def mark_mono(color):
    return '<path d="%s" fill="%s"/>' % (' '.join(mono_paths()), color)


# ------------------------------------------------- Android vector drawables
def _vd_path(layer, pad):
    f = layer.get('fill')
    a = ['android:pathData="%s"' % layer['d']]
    if isinstance(f, str):
        a.append('android:fillColor="%s"' % f)
    if 'alpha' in layer:
        a.append('android:fillAlpha="%s"' % n(layer['alpha']))
    if 'stroke' in layer:
        a += ['android:strokeColor="%s"' % layer['stroke'][0], 'android:strokeWidth="%s"' % n(layer['stroke'][1]),
              'android:strokeLineCap="round"', 'android:strokeLineJoin="round"']
    head = pad + '<path\n' + '\n'.join(pad + '    ' + x for x in a)
    if not isinstance(f, tuple):
        return head + ' />\n'
    _, x1, y1, x2, y2, stops = f
    g = [pad + '    <aapt:attr name="android:fillColor">',
         pad + '        <gradient android:type="linear" android:startX="%s" android:startY="%s" android:endX="%s" android:endY="%s">' % (
             n(x1), n(y1), n(x2), n(y2))]
    g += [pad + '            <item android:offset="%s" android:color="%s" />' % (n(o), c) for o, c in stops]
    g += [pad + '        </gradient>', pad + '    </aapt:attr>', pad + '</path>']
    return head + '>\n' + '\n'.join(g) + '\n'


VD_HEAD = ('<?xml version="1.0" encoding="utf-8"?>\n<!-- %s -->\n'
           '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
           '    xmlns:aapt="http://schemas.android.com/aapt"\n'
           '    android:width="%sdp"\n    android:height="%sdp"\n'
           '    android:viewportWidth="%s"\n    android:viewportHeight="%s">\n')

# Adaptive icon: 108dp canvas, mark scaled so it sits inside the 66dp safe zone.
AD_SCALE = 0.125
AD_SHIFT = 54 - 256 * AD_SCALE


def vd_adaptive_foreground():
    clip, clipped, free = mark_layers(True, True)
    o = [VD_HEAD % ('ZEMEN launcher icon - foreground layer (generated from the brand master).', 108, 108, 108, 108)]
    o.append('    <group\n        android:scaleX="%s"\n        android:scaleY="%s"\n        android:translateX="%s"\n        android:translateY="%s">\n' % (
        nf(AD_SCALE), nf(AD_SCALE), nf(AD_SHIFT), nf(AD_SHIFT)))
    o.append('        <group>\n            <clip-path android:pathData="%s" />\n' % clip)
    o += [_vd_path(l, '            ') for l in clipped]
    o.append('        </group>\n')
    o += [_vd_path(l, '        ') for l in free]
    o.append('    </group>\n</vector>\n')
    return ''.join(o)


def vd_adaptive_background():
    o = [VD_HEAD % ('ZEMEN launcher icon - background layer: deep black.', 108, 108, 108, 108)]
    o.append(_vd_path(dict(d='M0,0h108v108h-108z', fill=lin(0, 0, 0, 108, (0, '#0B100D'), (1, '#060807'))), '    '))
    o.append('</vector>\n')
    return ''.join(o)


def vd_adaptive_monochrome():
    o = [VD_HEAD % ('ZEMEN launcher icon - monochrome layer for Android 13+ themed icons.', 108, 108, 108, 108)]
    o.append('    <group\n        android:scaleX="%s"\n        android:scaleY="%s"\n        android:translateX="%s"\n        android:translateY="%s">\n' % (
        nf(AD_SCALE), nf(AD_SCALE), nf(AD_SHIFT), nf(AD_SHIFT)))
    o.append(_vd_path(dict(d=' '.join(mono_paths()), fill=WHITE), '        '))
    o.append('    </group>\n</vector>\n')
    return ''.join(o)


def vd_symbol_24():
    o = [VD_HEAD % ('ZEMEN symbol - 24dp single-colour glyph (status bar, widgets).', 24, 24, 512, 512)]
    o.append(_vd_path(dict(d=' '.join(mono_paths()), fill=WHITE), '    '))
    o.append('</vector>\n')
    return ''.join(o)


# ------------------------------------------------------- wordmark (cap 100)
WM_W, WM_H = 514.0, 100.0


def wordmark(fill, accent=None):
    def shift(pts, dx):
        return poly([(x + dx, y) for x, y in pts])
    z_all = [(0, 0), (88, 0), (88, 22), (33, 78), (88, 78), (88, 100), (0, 100), (0, 78), (55, 22), (0, 22)]
    z_bars = [[(0, 0), (88, 0), (88, 22), (0, 22)], [(0, 78), (88, 78), (88, 100), (0, 100)]]
    z_diag = [(55, 21), (88, 21), (33, 79), (0, 79)]
    e = [(0, 0), (72, 0), (72, 22), (24, 22), (24, 39.5), (64, 39.5), (64, 60.5), (24, 60.5),
         (24, 78), (72, 78), (72, 100), (0, 100)]
    m = [(0, 100), (0, 0), (26, 0), (56, 69.77), (86, 0), (112, 0), (112, 100), (88, 100),
         (88, 55.8), (69, 100), (43, 100), (24, 55.8), (24, 100)]
    nn = [(0, 100), (0, 0), (29, 0), (68, 61.9), (68, 0), (92, 0), (92, 100), (63, 100), (24, 38.1), (24, 100)]
    rest = [shift(e, 108), shift(m, 198), shift(e, 332), shift(nn, 422)]
    if accent and accent != fill:
        return ('<path d="%s" fill="%s"/><path d="%s" fill="%s"/>' % (
            shift(z_diag, 0), accent, ' '.join([shift(b, 0) for b in z_bars] + rest), fill))
    return '<path d="%s" fill="%s"/>' % (' '.join([shift(z_all, 0)] + rest), fill)


# ----------------------------------------------------------- font outlines
_fonts = {}


def _static(vf, loc):
    key = (vf, tuple(sorted(loc.items())))
    if key not in _fonts:
        dst_dir = os.path.join(OUT, '_static')
        os.makedirs(dst_dir, exist_ok=True)
        dst = os.path.join(dst_dir, '%s-%s.ttf' % (
            os.path.splitext(vf)[0], '-'.join('%s%d' % (k, v) for k, v in sorted(loc.items()))))
        if not os.path.exists(dst):
            instantiateVariableFont(TTFont(os.path.join(FONTS, vf)), loc).save(dst)
        _fonts[key] = (TTFont(dst), hb.Font(hb.Face(hb.Blob.from_file_path(dst))))
    return _fonts[key]


def text_outline(text, vf, size, tracking=0.0, **loc):
    """Returns (path d, advance width, bounds) - baseline at y=0, y grows down."""
    tt, hbfont = _static(vf, loc)
    s = size / tt['head'].unitsPerEm
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(hbfont, buf, {'kern': True, 'liga': False})
    gs = tt.getGlyphSet()
    rec = RecordingPen()
    x = 0.0
    count = len(buf.glyph_infos)
    for i, (info, pos) in enumerate(zip(buf.glyph_infos, buf.glyph_positions)):
        name = tt.getGlyphName(info.codepoint)
        gs[name].draw(TransformPen(rec, (s, 0, 0, -s, x + pos.x_offset * s, -pos.y_offset * s)))
        x += pos.x_advance * s + (tracking if i < count - 1 else 0.0)
    sp = SVGPathPen(gs, ntos=n)
    rec.replay(sp)
    bp = BoundsPen(gs)
    rec.replay(bp)
    return sp.getCommands(), x, bp.bounds


# ------------------------------------------------------------------ lockups
def type_block(mode, width=440.0, tagline=True, amharic=True):
    """ZEMEN + ዘመን + tagline, top-left at (0,0). Returns (markup, height)."""
    c = MODES[mode]
    k = width / 440.0
    s = width / WM_W
    o = ['<g transform="scale(%s)">%s</g>' % (nf(s), wordmark(c['word'], c['accent']))]
    y = WM_H * s
    if amharic:
        d, adv, b = text_outline(AMHARIC, ETH_FONT, 58.0 * k, tracking=7.0 * k, wght=800, wdth=100)
        aw, ah = b[2] - b[0], b[3] - b[1]
        top = y + 30 * k
        o.append('<path transform="translate(%s,%s)" d="%s" fill="%s"/>' % (
            nf((width - aw) / 2 - b[0]), nf(top - b[1]), d, c['amh']))
        mid = top + ah / 2
        inner = aw / 2 + 26 * k
        t = 1.1 * k
        rules = [poly([(0, mid - t), (width / 2 - inner, mid - t), (width / 2 - inner, mid + t), (0, mid + t)]),
                 poly([(width / 2 + inner, mid - t), (width, mid - t), (width, mid + t), (width / 2 + inner, mid + t)]),
                 diamond(width / 2 - inner, mid, 4.6 * k), diamond(width / 2 + inner, mid, 4.6 * k)]
        o.append('<path d="%s" fill="%s"/>' % (' '.join(rules), c['rule']))
        y = top + ah
    if tagline:
        d, adv, b2 = text_outline(TAGLINE, LAT_FONT, 20.5 * k, tracking=0.85 * k, wght=500)
        top = y + 28 * k
        o.append('<path transform="translate(%s,%s)" d="%s" fill="%s"/>' % (
            nf((width - adv) / 2), nf(top - b2[1]), d, c['tag']))
        y = top + (b2[3] - b2[1])
    return ''.join(o), y


def _placed_mark(u, x_tile, y_tile, tile, detail=True):
    """Mark placed so its calendar tile occupies (x_tile, y_tile, tile, tile)."""
    s = tile / TS
    return '<g transform="translate(%s,%s) scale(%s)">%s</g>' % (
        nf(x_tile - TX * s), nf(y_tile - TY * s), nf(s), mark_full(u, detail=detail))


def logo_stacked(u, mode, width=440.0, pad=44.0):
    k = width / 440.0
    tile = 208 * k
    ring_up = (TY - RING_TOP) * tile / TS
    text, th = type_block(mode, width)
    ty = ring_up + tile + 48 * k
    body = _placed_mark(u, (width - tile) / 2, ring_up, tile) + '<g transform="translate(0,%s)">%s</g>' % (nf(ty), text)
    return body, (-pad, -pad, width + 2 * pad, ty + th + 2 * pad)


def logo_horizontal(u, mode, width=440.0, pad=44.0):
    k = width / 440.0
    text, th = type_block(mode, width)
    tile = th
    ring_up = (TY - RING_TOP) * tile / TS
    gap = 46 * k
    body = _placed_mark(u, 0, 0, tile) + '<g transform="translate(%s,0)">%s</g>' % (nf(tile + gap), text)
    return body, (-pad, -pad - ring_up, tile + gap + width + 2 * pad, th + ring_up + 2 * pad)


def logo_compact(u, mode, width=440.0, pad=40.0):
    """Mark + wordmark only, for app bars and small headers."""
    c = MODES[mode]
    s = width / WM_W
    wh = WM_H * s
    tile = wh * 1.72
    ring_up = (TY - RING_TOP) * tile / TS
    gap = tile * 0.3
    body = _placed_mark(u, 0, 0, tile, detail=False) + '<g transform="translate(%s,%s) scale(%s)">%s</g>' % (
        nf(tile + gap), nf((tile - wh) / 2), nf(s), wordmark(c['word'], c['accent']))
    return body, (-pad, -pad - ring_up, tile + gap + width + 2 * pad, tile + ring_up + 2 * pad)


# ----------------------------------------------------------------- app icon
ICON_SCALE = AD_SCALE * 512 / 72            # the 72dp visible window mapped to 512px
ICON_SHIFT = 256 - 256 * ICON_SCALE


def app_icon_body(u, detail=True):
    """Full-bleed 512 square: what the launcher shows inside its mask."""
    return ('<defs><linearGradient id="%s-bg" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="512">'
            '<stop offset="0" stop-color="#0B100D"/><stop offset="1" stop-color="#060807"/></linearGradient></defs>'
            '<rect width="512" height="512" fill="url(#%s-bg)"/>'
            '<g transform="translate(%s,%s) scale(%s)">%s</g>') % (
        u, u, nf(ICON_SHIFT), nf(ICON_SHIFT), nf(ICON_SCALE), mark_full(u, detail=detail))


def svg(body, vb, width=None, bg=None):
    x, y, w, h = vb
    width = width or w
    back = '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % (n(x), n(y), n(w), n(h), bg) if bg else ''
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="%s %s %s %s">%s%s</svg>\n'
            % (n(width), n(width * h / w), n(x), n(y), n(w), n(h), back, body))


def write(name, text):
    path = os.path.join(OUT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as fh:
        fh.write(text)
    return path


def build():
    sq = (0, 0, 512, 512)
    files = {
        'svg/zemen-mark.svg': svg(mark_full('m'), sq),
        'svg/zemen-mark-simple.svg': svg(mark_full('ms', detail=False), sq),
        'svg/zemen-symbol-white.svg': svg(mark_mono(WHITE), sq),
        'svg/zemen-symbol-black.svg': svg(mark_mono(BLACK), sq),
        'svg/zemen-symbol-emerald.svg': svg(mark_mono(EMERALD), sq),
        'svg/zemen-app-icon.svg': svg(app_icon_body('ai'), sq),
        'svg/zemen-wordmark-on-dark.svg': svg(wordmark(WHITE, EMERALD), (-20, -20, WM_W + 40, WM_H + 40)),
        'svg/zemen-wordmark-on-light.svg': svg(wordmark(BLACK, EMERALD), (-20, -20, WM_W + 40, WM_H + 40)),
        'svg/zemen-wordmark-white.svg': svg(wordmark(WHITE), (-20, -20, WM_W + 40, WM_H + 40)),
        'svg/zemen-wordmark-black.svg': svg(wordmark(BLACK), (-20, -20, WM_W + 40, WM_H + 40)),
        'android/drawable/ic_launcher_foreground.xml': vd_adaptive_foreground(),
        'android/drawable/ic_launcher_background.xml': vd_adaptive_background(),
        'android/drawable/ic_launcher_monochrome.xml': vd_adaptive_monochrome(),
        'android/drawable/ic_zemen_symbol.xml': vd_symbol_24(),
    }
    for mode in ('dark', 'light'):
        for name, fn in (('stacked', logo_stacked), ('horizontal', logo_horizontal), ('compact', logo_compact)):
            body, vb = fn('%s%s' % (name[0], mode[0]), mode)
            files['svg/zemen-logo-%s-on-%s.svg' % (name, mode)] = svg(body, vb)
    d, _, b = text_outline(AMHARIC, ETH_FONT, 100.0, tracking=12.0, wght=800, wdth=100)
    for name, color in (('gold', GOLD), ('green', DGREEN), ('white', WHITE), ('black', BLACK)):
        files['svg/zemen-amharic-%s.svg' % name] = svg(
            '<path d="%s" fill="%s"/>' % (d, color), (b[0] - 16, b[1] - 16, b[2] - b[0] + 32, b[3] - b[1] + 32))
    for name, text in files.items():
        write(name, text)
    return sorted(files)


if __name__ == '__main__':
    for f in build():
        print(f)
