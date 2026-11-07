#!/bin/bash
# Rebuild libQtNetwork.so.4.7.4 from the PR1.3 qt4-x11 source (all Nokia patches incl. SNI backport)
# against openssl-n9 headers, linked to the phone's own QtCore/QtDBus/QtXml.
set -e
TLS=$(cd "$(dirname "$0")/.." && pwd); export PATH=$TLS/bin:$PATH
O=$TLS/build/stage-openssl/usr; S=$TLS/sysroot; Q=$TLS/build/qt4-x11-4.7.4~git20120327
cd $TLS/build; rm -rf $Q; tar xzf $TLS/src/qt4-x11_4.7.4~git20120327-0maemo1+0m8.tar.gz; cd $Q
for p in $(cat debian/patches/series.armel debian/patches/series | grep -v '^#' | grep -v '^\s*$'); do patch -p1 -f -s < debian/patches/$p > /dev/null || true; done
for p in $TLS/patches/qt-*.diff; do patch -p1 < $p; done      # our two patches
mkdir -p mkspecs/linux-n9-g++; cp $TLS/tools/qmake.conf mkspecs/linux-n9-g++/; cp mkspecs/linux-g++/qplatformdefs.h mkspecs/linux-n9-g++/
echo yes | CXXFLAGS="-std=gnu++98 -fpermissive -w" ./configure -continue -opensource -confirm-license -release -prefix /usr -bindir /usr/bin -libdir /usr/lib \
 -headerdir /usr/include/qt4 -datadir /usr/share/qt4 -plugindir /usr/lib/qt4/plugins -importdir /usr/lib/qt4/imports -translationdir /usr/share/qt4/translations \
 -sysconfdir /etc/xdg -platform linux-g++ -xplatform linux-n9-g++ -arch armv6 -fast -no-optimized-qmake -reduce-relocations -no-rpath -system-zlib \
 -no-qt3support -nomake examples -nomake demos -nomake docs -nomake tools -little-endian -exceptions -dbus-linked -no-pch -no-webkit -no-phonon \
 -no-gstreamer -no-opengl -no-xmlpatterns -no-multimedia -no-audio-backend -no-svg -no-script -no-scripttools -no-declarative -no-sql-sqlite \
 -no-libtiff -no-libpng -no-libjpeg -no-libmng -no-glib -no-cups -no-iconv -no-nis -no-xinput -no-xkb -no-sm -no-xshape -no-xsync -no-xrender \
 -no-mitshm -no-fontconfig -no-xvideo -no-xinerama -no-xcursor -no-xfixes -no-xrandr -no-gtkstyle -openssl \
 -I$O/include -I$S/usr/include/dbus-1.0 -I$S/usr/lib/dbus-1.0/include -L$O/lib -lssl -lcrypto
# use Nokia's own qconfig.h (same feature set as the phone's QtCore, incl. ICD bearer)
dpkg-deb --fsys-tarfile $TLS/mirror/debs/libqt4-dev_*.deb | tar -xO ./usr/include/qt4/QtCore/qconfig.h > src/corelib/global/qconfig.h
for l in QtCore QtDBus QtXml; do ln -sf $S/usr/lib/lib$l.so.4.7.4 lib/lib$l.so; ln -sf $S/usr/lib/lib$l.so.4.7.4 lib/lib$l.so.4; done
(cd src/tools/bootstrap && make -j8); (cd src/tools/moc && make -j8)
cd src/network
sed -i '/^LIBS /s/ -lssl -lcrypto//' Makefile            # OpenSSL is loaded at run time (libssl.so.1.0.2)
sed -i '/^LFLAGS /s/$/ -Wl,--no-as-needed/' Makefile      # keep the same NEEDED list as Nokia's build
mkdir -p .obj/release-shared .moc/release-shared; make -j8
cp $Q/lib/libQtNetwork.so.4.7.4 $TLS/build/libQtNetwork.so.4.7.4.strip; n9-strip --strip-unneeded $TLS/build/libQtNetwork.so.4.7.4.strip
