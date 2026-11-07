#!/bin/bash
# Package openssl-n9: OpenSSL 1.0.2u libs + openssl-n9 tool + Mozilla CA certificates with
# pre-computed hash links (OpenSSL >= 1.0 subject hash), so no Perl/c_rehash is needed on the phone.
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); export PATH=$TLS/bin:$PATH
VER=1.0.2u-2; B=$TLS/build; P=$B/pkg-openssl-n9; OUT=$TLS/dist; mkdir -p $OUT
CADIR=${CADIR:-/usr/share/ca-certificates/mozilla}
rm -rf $P; mkdir -p $P/DEBIAN $P/usr/lib $P/usr/bin $P/etc/openssl-n9/certs $P/usr/share/doc/openssl-n9
install -m 0644 $B/stage-openssl/usr/lib/libssl.so.1.0.2 $B/stage-openssl/usr/lib/libcrypto.so.1.0.2 $P/usr/lib/
install -m 0755 $B/stage-openssl/usr/bin/openssl $P/usr/bin/openssl-n9
n9-strip --strip-unneeded $P/usr/lib/*.so.* ; n9-strip $P/usr/bin/openssl-n9
install -m 0644 $B/openssl-1.0.2u/apps/openssl.cnf $P/etc/openssl-n9/openssl.cnf
for c in $CADIR/*.crt; do n=$(basename "$c" .crt | tr ' ' '_' | iconv -f UTF-8 -t ASCII//TRANSLIT | tr -cd 'A-Za-z0-9_.=-'); openssl x509 -in "$c" -out "$P/etc/openssl-n9/certs/$n.pem"; done
# hash links (same subject_hash algorithm as OpenSSL 1.0.x)
(cd $P/etc/openssl-n9/certs; for f in *.pem; do h=$(openssl x509 -in "$f" -noout -subject_hash); i=0; while [ -e "$h.$i" ]; do i=$((i+1)); done; ln -s "$f" "$h.$i"; done)
cat $P/etc/openssl-n9/certs/*.pem > $P/etc/openssl-n9/cert.pem
NCA=$(ls $P/etc/openssl-n9/certs/*.pem | wc -l)
cp $B/openssl-1.0.2u/LICENSE $P/usr/share/doc/openssl-n9/LICENSE.openssl
cat > $P/usr/share/doc/openssl-n9/README <<R
openssl-n9 $VER for Nokia N9 (MeeGo Harmattan PR1.3)
OpenSSL 1.0.2u (20 Dec 2019) built with soname libssl.so.1.0.2/libcrypto.so.1.0.2 and
versioned symbols (OPENSSL_1.0.2), so it can live in the same process as Nokia's OpenSSL 0.9.8.
CA certificates: $NCA roots from Mozilla (Ubuntu ca-certificates $(dpkg-query -W -f='${Version}' ca-certificates 2>/dev/null)).
Designed and written by Claude (Anthropic) together with smyhu for the Nokia N9.
This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/).
R
cat > $P/DEBIAN/control <<C
Package: openssl-n9
Version: $VER
Architecture: armel
Maintainer: smyhu <smyhu@users.noreply.github.com>
Depends: libc6 (>= 2.7)
Section: libs
Priority: optional
Installed-Size: $(du -sk $P --exclude=DEBIAN | cut -f1)
Homepage: https://github.com/smyhu
Description: OpenSSL 1.0.2u with TLS 1.2 and current CA certificates for N9
 Separate soname and versioned symbols: coexists with the system OpenSSL 0.9.8.
 Used by the rebuilt Nokia libraries of the n9-tls patch.
C
printf '#!/bin/sh\nset -e\nif [ "$1" = configure ]; then /sbin/ldconfig || true; fi\n' > $P/DEBIAN/postinst
printf '#!/bin/sh\nset -e\nif [ "$1" = remove ]; then /sbin/ldconfig || true; fi\n' > $P/DEBIAN/postrm
chmod 0755 $P/DEBIAN/postinst $P/DEBIAN/postrm
(cd $P; find . -type f ! -path './DEBIAN/*' | sed 's|^\./||' | sort | xargs md5sum > DEBIAN/md5sums)
echo "/etc/openssl-n9/openssl.cnf" > $P/DEBIAN/conffiles
# Aegis digsigsums (SHA-1 of every regular file + maintainer scripts), same format as Nokia packages
python3 - "$P" <<'PY'
import hashlib, os, sys
P = sys.argv[1]; out = []
def line(rel, full):
    out.append('S 15 com.nokia.maemo H 40 %s R %d %s' % (hashlib.sha1(open(full, 'rb').read()).hexdigest(), len(rel.encode()), rel))
for root, dirs, files in os.walk(P):
    if root.startswith(os.path.join(P, 'DEBIAN')): continue
    for f in sorted(files):
        full = os.path.join(root, f)
        if os.path.islink(full): continue
        line(os.path.relpath(full, P), full)
for sc in ('postinst', 'postrm'):
    line('var/lib/dpkg/info/openssl-n9.' + sc, os.path.join(P, 'DEBIAN', sc))
open(os.path.join(P, 'DEBIAN', 'digsigsums'), 'w').write('\n'.join(sorted(out)) + '\n')
PY
fakeroot dpkg-deb -Zgzip --build $P $OUT/openssl-n9_${VER}_armel.deb
