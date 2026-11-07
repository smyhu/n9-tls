#!/bin/bash
# Rebuild libcurl3 7.21.0-1maemo4+0m6 (Nokia PR1.3 source + Debian patches) against openssl-n9
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); export PATH=$TLS/bin:$PATH; O=$TLS/build/stage-openssl/usr
cd $TLS/build; rm -rf curl-7.21.0; tar xzf $TLS/src/curl_7.21.0.orig.tar.gz; cd curl-7.21.0
zcat $TLS/src/curl_7.21.0-1maemo4+0m6.diff.gz | patch -p1 -s
for p in no_com_err runtests_gdb art_http_scripting versioned content-disposition curl_links_with_rt; do patch -p1 -s < debian/patches/$p; done
autoreconf -fi
CC=n9-gcc AR=n9-ar RANLIB=n9-ranlib STRIP=n9-strip CFLAGS="-O2 -g" CPPFLAGS="-I$O/include" LDFLAGS="-L$O/lib -Wl,-rpath-link,$O/lib" \
 ./configure --build=x86_64-linux-gnu --host=arm-linux-gnueabihf --with-random=/dev/urandom --prefix=/usr \
 --disable-dependency-tracking --enable-ipv6 --enable-versioned-symbols --enable-ares --with-ssl=$O \
 --with-ca-path=/etc/openssl-n9/certs --without-gnutls --without-libssh2 --without-gssapi --disable-ldap --disable-ldaps --without-librtmp
make -j8
