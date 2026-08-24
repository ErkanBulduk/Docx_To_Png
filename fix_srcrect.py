#!/usr/bin/env python3
"""
Normalise les <a:srcRect> a valeurs negatives dans un PPTX/DOCX.

PowerPoint accepte des valeurs negatives dans <a:srcRect> : cela ajoute du
"padding" transparent autour de l'image au lieu de la rogner. LibreOffice
ignore purement et simplement le srcRect dans ce cas, et dessine l'image
entiere etiree sur tout le cadre -> elements graphiques trop grands qui
recouvrent le texte.

Ce script reecrit chaque srcRect en crop uniquement positif et compense en
reduisant / decalant le cadre <a:xfrm> du <p:pic>, ce qui donne exactement le
meme rendu que PowerPoint tout en restant comprehensible par LibreOffice.
"""
import re, shutil, sys, zipfile
from pathlib import Path

PART_RE = re.compile(r'(ppt/slides/slide\d+\.xml|ppt/slideLayouts/slideLayout\d+\.xml|'
                     r'ppt/slideMasters/slideMaster\d+\.xml|word/document\.xml)$')
PIC_RE = re.compile(r'<(p|pic):pic>.*?</\1:pic>', re.S)
SRC_RE = re.compile(r'<a:srcRect([^>]*)/>')
ATTR_RE = re.compile(r'\b([ltrb])="(-?\d+)"')
OFF_RE = re.compile(r'<a:off x="(-?\d+)" y="(-?\d+)"\s*/>')
EXT_RE = re.compile(r'<a:ext cx="(\d+)" cy="(\d+)"\s*/>')
ROT_RE = re.compile(r'<a:xfrm[^>]*\b(rot|flipH|flipV)=')


def fix_pic(frag, part, report):
    m = SRC_RE.search(frag)
    if not m:
        return frag
    crop = {k: 0 for k in 'ltrb'}
    crop.update({k: int(v) for k, v in ATTR_RE.findall(m.group(1))})
    if all(v >= 0 for v in crop.values()):
        return frag                      # crop classique, LibreOffice sait faire

    off, ext = OFF_RE.search(frag), EXT_RE.search(frag)
    if not (off and ext):
        report.append('%s: srcRect negatif sans <a:xfrm> explicite -> ignore' % part)
        return frag
    if ROT_RE.search(frag):
        report.append('%s: srcRect negatif sur une image tournee/miroir -> ignore' % part)
        return frag

    l, t, r, b = (crop[k] / 100000 for k in 'ltrb')
    sw, sh = 1 - l - r, 1 - t - b        # largeur/hauteur visible en fraction de la source
    if sw <= 0 or sh <= 0:
        return frag

    cl, ct = max(l, 0.0), max(t, 0.0)    # region reellement presente dans l'image
    cr, cb = min(1 - r, 1.0), min(1 - b, 1.0)
    if cr <= cl or cb <= ct:
        return frag

    x, y = int(off.group(1)), int(off.group(2))
    cx, cy = int(ext.group(1)), int(ext.group(2))
    nx = x + round(cx * (cl - l) / sw)
    ny = y + round(cy * (ct - t) / sh)
    ncx = max(1, round(cx * (cr - cl) / sw))
    ncy = max(1, round(cy * (cb - ct) / sh))

    new_src = '<a:srcRect l="%d" t="%d" r="%d" b="%d"/>' % (
        round(cl * 100000), round(ct * 100000),
        round((1 - cr) * 100000), round((1 - cb) * 100000))
    frag = frag[:m.start()] + new_src + frag[m.end():]
    frag = OFF_RE.sub('<a:off x="%d" y="%d"/>' % (nx, ny), frag, count=1)
    frag = EXT_RE.sub('<a:ext cx="%d" cy="%d"/>' % (ncx, ncy), frag, count=1)
    report.append('%s: crop %s -> %s | cadre %dx%d@%d,%d -> %dx%d@%d,%d'
                  % (part, crop, new_src, cx, cy, x, y, ncx, ncy, nx, ny))
    return frag


def process(path):
    path = Path(path)
    with zipfile.ZipFile(path) as zin:
        items = [(i, zin.read(i.filename)) for i in zin.infolist()]

    report, changed = [], False
    out = []
    for info, data in items:
        if PART_RE.search(info.filename):
            xml = data.decode('utf-8')
            part = info.filename.rsplit('/', 1)[-1]
            new = PIC_RE.sub(lambda mm: fix_pic(mm.group(0), part, report), xml)
            if new != xml:
                changed = True
                data = new.encode('utf-8')
        out.append((info, data))

    if changed:
        tmp = path.with_suffix(path.suffix + '.tmp')
        with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as zout:
            for info, data in out:
                zout.writestr(info, data)
        shutil.move(str(tmp), str(path))
    for line in report:
        print('  %s: %s' % (path.name, line), file=sys.stderr)
    return changed


if __name__ == '__main__':
    for arg in sys.argv[1:]:
        process(arg)
