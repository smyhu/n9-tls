#!/bin/bash
# Build OpenSSL 1.0.2u for Nokia N9 with its own soname (libssl.so.1.0.2) and
# versioned symbols (OPENSSL_1.0.2), so it can coexist with Nokia's 0.9.8 in one process.
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); export PATH=$TLS/bin:$PATH
cd $TLS/build; rm -rf openssl-1.0.2u stage-openssl; tar xzf $TLS/src/openssl-1.0.2u.tar.gz; cd openssl-1.0.2u
sed -i 's/^# define SHLIB_VERSION_NUMBER "1.0.0"/# define SHLIB_VERSION_NUMBER "1.0.2"/' crypto/opensslv.h
printf 'OPENSSL_1.0.2 {\n  global: *;\n};\n' > openssl-n9.ld
CC=n9-gcc AR=n9-ar RANLIB=n9-ranlib ./Configure linux-armv4 shared no-ssl2 no-ssl3 no-comp no-idea no-mdc2 no-rc5 no-krb5 \
  -O2 --prefix=/usr --openssldir=/etc/openssl-n9
sed -i "s|^SHARED_LDFLAGS=.*|SHARED_LDFLAGS=-Wl,--version-script=$PWD/openssl-n9.ld|" Makefile
make depend; make -j8; make install_sw INSTALL_PREFIX=$TLS/build/stage-openssl
rm -f $TLS/build/stage-openssl/usr/lib/*.a
