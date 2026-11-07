#!/bin/bash
# Repack Nokia's original packages (same versions, scripts and Aegis manifests) with the rebuilt files.
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); export PATH=$TLS/bin:$PATH; B=$TLS/build; D=$TLS/dist
ORIG=${ORIG:-$TLS/mirror/debs}     # Nokia originals (coderus n9mirror/001)
mkdir -p $D; $TLS/tools/build-openssl-n9-deb.sh
cp $B/curl-7.21.0/lib/.libs/libcurl.so.4.2.0 $B/libcurl.so.4.2.0.strip; n9-strip --strip-unneeded $B/libcurl.so.4.2.0.strip
python3 $TLS/tools/repack.py $ORIG/libcurl3_7.21.0-1maemo4+0m6_armel.deb $D/libcurl3_7.21.0-1maemo4+0m6_armel.deb \
  --dep 'libssl0.9.8 (>= 0.9.8k-1)::openssl-n9 (>= 1.0.2u-1)' usr/lib/libcurl.so.4.2.0=$B/libcurl.so.4.2.0.strip
python3 $TLS/tools/repack.py $ORIG/libqt4-network_4.7.4~git20120327-0maemo1+0m8_armel.deb $D/libqt4-network_4.7.4~git20120327-0maemo1+0m8_armel.deb \
  --dep 'zlib1g (>= 1:1.1.4)::zlib1g (>= 1:1.1.4), openssl-n9 (>= 1.0.2u-1)' usr/lib/libQtNetwork.so.4.7.4=$B/libQtNetwork.so.4.7.4.strip
rm -rf $B/ca2026; mkdir -p $B/ca2026; cp $B/pkg-openssl-n9/etc/openssl-n9/certs/*.pem $B/ca2026/
python3 $TLS/tools/repack.py $ORIG/aegis-certman-common-ca_1.0.8+0m8_all.deb $D/aegis-certman-common-ca_1.0.8+0m8_all.deb \
  --dir usr/share/aegis-certman-common-ca=$B/ca2026
(cd $D; md5sum *.deb > md5sums.txt)
