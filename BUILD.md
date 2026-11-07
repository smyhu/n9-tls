# Building n9-tls from source

Everything is cross-compiled on a PC; nothing is built on the phone.

## Host (Ubuntu 24.04)

Host packages: gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf qemu-user-static autoconf automake libtool fakeroot python3-pip; `pip install pycdlib`.

1. `tools/make-sysroot.sh` - device runtime debs (coderus mirror 001) + SDK -dev debs -> sysroot/
2. `python3 tools/isoget.py src openssl1 curl qt4-x11` - source packages from the PR1.3 sources ISO
   (http://maemo.cloud-7.de/HARM/N9/1.3/cdrom.iso) by HTTP range requests; OpenSSL 1.0.2u from openssl.org (sha256 ecd0c6ff...)
3. `tools/build-openssl.sh`, `tools/build-curl.sh`, `tools/build-qtnetwork.sh`
4. `ORIG=<folder with Nokia original debs> tools/build-debs.sh` -> dist/ (default ORIG: mirror/debs; originals from the coderus n9mirror/001 repository)

Notes:
- Harmattan is "armel" but uses the hard-float ABI (Tag_ABI_VFP_args); the wrappers bin/n9-gcc and bin/n9-g++ use
  arm-linux-gnueabihf-gcc with only the N9 sysroot (glibc 2.10, libstdc++ 4.4 headers, /lib/ld-linux.so.3).
- patches/qt-foreach-gcc9.diff: Qt 4.7 foreach breaks with GCC >= 9 (stops after the first element); local macro fix, no ABI change.
- patches/qt-openssl-n9-certdir.diff: adds /etc/openssl-n9/certs/ in front of Qt's CA directories.
- Exported symbols of the rebuilt QtNetwork match Nokia's (1206 of 1211; the 4 missing are weak copies of inline functions).

## Tests (qemu-arm)

- tests/mix.c - libcurl in a process that already uses OpenSSL 0.9.8 (like nped): ours OK, WunderWungiel's fails (error 35).
- tests/qssl.cpp - QSslSocket TLS 1.2 (RSA and ECDSA, SNI sent, wrong CA rejected), also with 0.9.8 in the process:
  ours OK; WunderWungiel's QtNetwork crashes (SIGSEGV) when 0.9.8 is already loaded.

Licences: OpenSSL licence (OpenSSL 1.0.2u), LGPL 2.1 (Qt), curl licence (curl), MPL 2.0 (Mozilla CA list).
