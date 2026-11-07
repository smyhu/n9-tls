import sys,re,urllib.request,hashlib,os
P=open(sys.argv[1]).read().split("\n\n"); base=os.environ.get("BASE","https://coderus.openrepos.net/n9mirror/001/")
idx={}
for b in P:
    m=re.search(r'^Package: (\S+)',b,re.M)
    if m: idx[m.group(1)]=b
for n in sys.argv[3:]:
    b=idx.get(n)
    if not b: print("NOTFOUND",n); continue
    fn=re.search(r'^Filename: (\S+)',b,re.M).group(1); md=re.search(r'^MD5sum: (\S+)',b,re.M).group(1)
    out=os.path.join(sys.argv[2],os.path.basename(fn))
    if not os.path.exists(out):
        d=urllib.request.urlopen(base+fn,timeout=120).read(); open(out,'wb').write(d)
    ok=hashlib.md5(open(out,'rb').read()).hexdigest()==md
    print(n,os.path.basename(fn),"OK" if ok else "BADMD5")
