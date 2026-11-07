#!/bin/bash
# Build the N9 sysroot: device runtime libs (PR1.3, coderus mirror 001) + SDK -dev packages (headers).
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); cd $TLS; mkdir -p mirror/debs sysroot
curl -sS -o mirror/Packages https://coderus.openrepos.net/n9mirror/001/Packages
SDK=http://wunderwungiel.pl/MeeGo/harmattan-dev.nokia.com/
for c in free non-free; do curl -sS ${SDK}dists/harmattan/sdk/$c/binary-armel/Packages.gz | gunzip; echo; done > mirror/sdk.txt
python3 -I tools/fetchpkg.py mirror/Packages mirror/debs libaegis-crypto1 libbb5-0 libc-ares2 libc6 libconnsettings0 libcreds2 libcurl3 libdbus-1-3 libdbus-glib-1-2 libdevicemapper0 libexpat1 libgcc1 libgconf2-6 libglib2.0-0 libice6 libicu44 libidn11 libnspr4 libnss3 libpcre3 libpopt0 libqt4-dbus libqt4-network libqt4-xml libqtcore4 libsm6 libsqlite3-0 libssl0.9.8 libstdc++6 libuuid1 libx11-6 libxau6 libxcb1 libxext6 libxml2 zlib1g 
BASE=$SDK python3 -I tools/fetchpkg.py mirror/sdk.txt mirror/debs libc6-dev linux-kernel-headers zlib1g-dev libidn11-dev libc-ares-dev libstdc++6-4.4-dev libcreds2-dev libexpat1-dev libnss3-dev libnspr4-dev libdbus-1-dev libglib2.0-dev libdbus-glib-1-dev libsqlite3-dev libxml2-dev uuid-dev libpopt-dev libdevicemapper0-dev libqt4-dev libx11-dev x11proto-core-dev libxext-dev x11proto-xext-dev libxau-dev libxdmcp-dev x11proto-input-dev x11proto-kb-dev libxcb1-dev xtrans-dev libpthread-stubs0-dev libpthread-stubs0 libice-dev libsm-dev
for d in mirror/debs/*.deb; do dpkg-deb -x $d sysroot; done
cd sysroot
for l in $(find . -xtype l); do t=$(readlink $l); case $t in /*) ln -sf "$(realpath -m --relative-to=$(dirname $l) .$t)" $l;; esac; done
ln -sf libz.so.1.2.3.4 usr/lib/libz.so
rm -r usr/include/qt4   # SDK Qt headers are older; Qt is built from the PR1.3 source tree
