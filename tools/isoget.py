import pycdlib, urllib.request, io, sys, os
URL="http://maemo.cloud-7.de/HARM/N9/1.3/cdrom.iso"; SIZE=2930874368; BS=1<<20
class R(io.RawIOBase):
    def __init__(s): s.p=0; s.cache={}
    def seekable(s): return True
    def readable(s): return True
    def seek(s,o,w=0):
        s.p = o if w==0 else (s.p+o if w==1 else SIZE+o); return s.p
    def tell(s): return s.p
    def _blk(s,b):
        if b not in s.cache:
            if len(s.cache)>64: s.cache.clear()
            for t in range(6):
                try:
                    r=urllib.request.Request(URL,headers={"Range":"bytes=%d-%d"%(b*BS,b*BS+BS-1)})
                    s.cache[b]=urllib.request.urlopen(r,timeout=120).read(); break
                except Exception as e: print("retry",e,file=sys.stderr)
        return s.cache[b]
    def readinto(s,buf):
        n=len(buf); out=b""
        while len(out)<n and s.p<SIZE:
            b=s.p//BS; d=s._blk(b)[s.p%BS:]; d=d[:n-len(out)]; out+=d; s.p+=len(d)
        buf[:len(out)]=out; return len(out)
iso=pycdlib.PyCdlib(); iso.open_fp(io.BufferedReader(R(),BS))
out=sys.argv[1]; names=sys.argv[2:]
want=set()
for path,dirs,files in iso.walk(rr_path='/sources'):
    for f in files:
        if any(f.startswith(n+"_") for n in names): want.add(f)
for f in sorted(want):
    print("get",f,flush=True)
    with open(os.path.join(out,f),"wb") as o: iso.get_file_from_iso_fp(o, rr_path='/sources/'+f)
