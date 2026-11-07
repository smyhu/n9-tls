#!/usr/bin/env python3
"""Repack an original Nokia .deb with rebuilt binaries, keeping version, scripts and _aegis manifest.
usage: repack.py ORIG.deb OUT.deb [--dep OLD::NEW]... [--dir pkg/dir=local/dir]... [path/in/pkg=local/file]...
--dir replaces ALL regular files directly inside pkg/dir with the files of local/dir.
Regenerates DEBIAN/md5sums and DEBIAN/digsigsums (SHA-1 per file, Aegis format)."""
import sys, tarfile, io, hashlib, re, time, os, copy

orig, out = sys.argv[1], sys.argv[2]
deps, repl, dirs = [], {}, {}
a = sys.argv[3:]
while a:
    x = a.pop(0)
    if x == '--dep':
        o, n = a.pop(0).split('::', 1)
        deps.append((o, n))
    elif x == '--dir':
        k, v = a.pop(0).split('=', 1)
        dirs[k.strip('./')] = v
    else:
        k, v = x.split('=', 1)
        repl[k.lstrip('./')] = open(v, 'rb').read()


def ar_read(fn):
    d = open(fn, 'rb').read()
    assert d[:8] == b'!<arch>\n'
    p, m = 8, []
    while p < len(d):
        h = d[p:p + 60]
        name = h[:16].decode().strip().rstrip('/')
        size = int(h[48:58])
        p += 60
        m.append((name, d[p:p + size]))
        p += size + (size & 1)
    return m


def ar_write(fn, members):
    now = int(time.time())
    with open(fn, 'wb') as f:
        f.write(b'!<arch>\n')
        for name, data in members:
            f.write(('%-16s%-12d%-6d%-6d%-8s%-10d`\n' % (name, now, 0, 0, '100644', len(data))).encode())
            f.write(data)
            if len(data) & 1:
                f.write(b'\n')


mem = ar_read(orig)
md = dict(mem)

# data.tar.gz: same members, owners, modes and order; replaced contents
src = tarfile.open(fileobj=io.BytesIO(md['data.tar.gz']))
dbuf = io.BytesIO()
dst = tarfile.open(fileobj=dbuf, mode='w:gz', format=tarfile.GNU_FORMAT)
files, used = {}, set()
added, removed = [], []
for ti in src.getmembers():
    p = ti.name.lstrip('./')
    if ti.isfile() and os.path.dirname(p) in dirs:
        removed.append(p)
        continue
    if ti.isdir() and p.rstrip('/') in dirs:
        dst.addfile(ti)
        d = p.rstrip('/')
        for fn in sorted(os.listdir(dirs[d])):
            data = open(os.path.join(dirs[d], fn), 'rb').read()
            nt = copy.copy(ti); nt.type = tarfile.REGTYPE; nt.mode = 0o644
            nt.name = './' + d + '/' + fn; nt.size = len(data); nt.mtime = int(time.time())
            files[d + '/' + fn] = data; added.append(d + '/' + fn)
            dst.addfile(nt, io.BytesIO(data))
        continue
    if ti.isfile():
        data = src.extractfile(ti).read()
        if p in repl:
            data = repl[p]
            used.add(p)
            ti.mtime = int(time.time())
        ti.size = len(data)
        files[p] = data
        dst.addfile(ti, io.BytesIO(data))
    else:
        dst.addfile(ti)
dst.close()
missing = set(repl) - used
if missing:
    sys.exit('not in package: %s' % missing)

# control.tar.gz: Depends edits, regenerated md5sums and digsigsums
src = tarfile.open(fileobj=io.BytesIO(md['control.tar.gz']))
cbuf = io.BytesIO()
dst = tarfile.open(fileobj=cbuf, mode='w:gz', format=tarfile.GNU_FORMAT)
for ti in src.getmembers():
    n = ti.name.lstrip('./')
    if not ti.isfile():
        dst.addfile(ti)
        continue
    data = src.extractfile(ti).read()
    if n == 'control':
        t = data.decode()
        for o, nw in deps:
            if o not in t:
                sys.exit('dependency not found: ' + o)
            t = t.replace(o, nw)
        data = t.encode()
    elif n == 'md5sums':
        lines = []
        for l in data.decode().splitlines():
            h, p = l.split(None, 1)
            p = p.strip()
            if p in files:
                h = hashlib.md5(files[p]).hexdigest()
            if p in removed:
                continue
            lines.append('%s  %s' % (h, p))
        lines += ['%s  %s' % (hashlib.md5(files[p]).hexdigest(), p) for p in added]
        data = ('\n'.join(lines) + '\n').encode()
    elif n == 'digsigsums':
        lines = []
        for l in data.decode().splitlines():
            m = re.match(r'^(S \d+ \S+ H 40 )([0-9a-f]{40})( R (\d+) (.+))$', l)
            if not m:
                sys.exit('bad digsigsums line: ' + l)
            p, h = m.group(5), m.group(2)
            if p in files:
                h = hashlib.sha1(files[p]).hexdigest()
            if p in removed:
                continue
            lines.append(m.group(1) + h + m.group(3))
            src_tag = m.group(1)
        lines += ['%s%s R %d %s' % (src_tag, hashlib.sha1(files[p]).hexdigest(), len(p.encode()), p) for p in added]
        data = ('\n'.join(lines) + '\n').encode()
    ti.size = len(data)
    dst.addfile(ti, io.BytesIO(data))
dst.close()

newm = []
for name, data in mem:
    if name == 'data.tar.gz':
        data = dbuf.getvalue()
    elif name == 'control.tar.gz':
        data = cbuf.getvalue()
    newm.append((name, data))
ar_write(out, newm)
print('wrote', out, 'replaced:', ', '.join(sorted(used)), '| dir files removed %d added %d' % (len(removed), len(added)))
