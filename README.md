# n9-tls: TLS 1.2 for the Nokia N9

A TLS 1.2 patch for the Nokia N9 (MeeGo Harmattan PR1.3). After installing it, Qt apps (browser, mail, calendar sync, Warehouse, RSS readers…) and curl-based apps can connect to today's HTTPS servers, with SNI and current root certificates.

Designed and written by Claude (Anthropic) together with smyhu.

## What it installs

Four packages, about 2.2 MB in total (`dist/`):

| Package | Version | What it does |
|---|---|---|
| `openssl-n9` (new) | 1.0.2u-2 | OpenSSL 1.0.2u as `libssl.so.1.0.2` / `libcrypto.so.1.0.2` with versioned symbols, the `openssl-n9` command, and 117 Mozilla root certificates (August 2026) with ready hash links in `/etc/openssl-n9/certs` |
| `libqt4-network` | same as Nokia | QtNetwork rebuilt from the PR1.3 source with all Nokia patches (including SNI), using openssl-n9 |
| `libcurl3` | same as Nokia | curl rebuilt against openssl-n9 |
| `aegis-certman-common-ca` | same as Nokia | the system certificate store refreshed with the same Mozilla roots |

The repacked Nokia packages keep their original version numbers, maintainer scripts and Aegis manifests. No Perl is needed.

### Why it coexists with the system OpenSSL

The N9 keeps its own OpenSSL 0.9.8, which many system services use. `openssl-n9` has a different soname **and versioned symbols**, so both versions can live in the same process without mixing. That is why only four packages are needed and why services that load 0.9.8 themselves (location/A-GPS `nped`, calendar sync `msyncd`, Python) keep working. A TLS library without versioned symbols gets mixed up with 0.9.8 in such processes: curl calls fail and QtNetwork can crash (`tests/` reproduces both).

## Install

You need developer mode, SSH or the Terminal, and root (`devel-su`). Copy the `dist/` folder to the phone, for example to `/home/developer/n9-tls`, then as the user:

```
cd /home/developer/n9-tls
```
```
md5sum -c md5sums.txt
```

All four lines must say `OK`. Then as root (dpkg works out the order itself):

```
aegis-dpkg -i /home/developer/n9-tls/openssl-n9_1.0.2u-2_armel.deb /home/developer/n9-tls/libqt4-network_4.7.4~git20120327-0maemo1+0m8_armel.deb /home/developer/n9-tls/libcurl3_7.21.0-1maemo4+0m6_armel.deb /home/developer/n9-tls/aegis-certman-common-ca_1.0.8+0m8_all.deb
```

Reboot the phone afterwards.

If another TLS patch is installed (`md5sum /usr/lib/libQtNetwork.so.4.7.4` is not `7123b565acfcdc987eade607c308ee69`), first restore Nokia's original packages as described by that patch.

## Check

As root:

```
md5sum /usr/lib/libQtNetwork.so.4.7.4
```

It must print `ce41893f751f121cb2d567cb148eb94a`.

```
openssl-n9 s_client -connect example.com:443 -servername example.com -CApath /etc/openssl-n9/certs
```

Look for `Protocol  : TLSv1.2` and `Verify return code: 0 (ok)`; leave with Ctrl+C. In the browser, https://tls-v1-2.badssl.com:1012/ should show a green page.

## Uninstall

Put Nokia's original `libqt4-network`, `libcurl3` and `aegis-certman-common-ca` packages (same versions as above, from the PR1.3 repository) in a folder, e.g. `/home/developer/nokia-original`, then as root:

```
aegis-dpkg -i /home/developer/nokia-original/libqt4-network_4.7.4~git20120327-0maemo1+0m8_armel.deb /home/developer/nokia-original/libcurl3_7.21.0-1maemo4+0m6_armel.deb /home/developer/nokia-original/aegis-certman-common-ca_1.0.8+0m8_all.deb
```
```
dpkg -r openssl-n9
```

Reboot afterwards. Certificates added to the Aegis store stay there, which does no harm.

## Tested

On a Nokia N9 with PR1.3 (November 2026): TLS 1.2 with ECDHE-GCM ciphers and certificate verification, the system browser (including SNI sites behind Cloudflare), mail, Nextcloud CalDAV two-way calendar sync, Warehouse, RSS, curl-based map tiles (CloudGPS). The location service `nped` keeps loading only the original OpenSSL 0.9.8.

Modern websites still look broken in the 2012 system browser. That is a JavaScript/CSS limit of the browser, not a TLS problem.

## Building from source

Everything is cross-compiled on a PC from Nokia's PR1.3 source packages and OpenSSL 1.0.2u. See [BUILD.md](BUILD.md).

| Folder | Contents |
|---|---|
| `bin/` | `n9-gcc`, `n9-g++` compiler wrappers (hard-float, N9 sysroot only) |
| `tools/` | sysroot and source download, build scripts, `repack.py` (repacks Nokia debs with new md5sums/digsigsums) |
| `patches/` | the two Qt changes: CA directory and a Qt 4.7 `foreach` fix for GCC ≥ 9 |
| `tests/` | qemu tests: TLS 1.2 via QSslSocket, and curl/Qt in a process that already uses OpenSSL 0.9.8 |
| `dist/` | ready packages and `md5sums.txt` |

## Thanks

To WunderWungiel, whose TLS patch for the N9 showed that this is possible and kept many N9s online for years. This project is an independent rebuild with a different approach (separate, versioned OpenSSL), not a copy of that patch.

## Licences

The scripts, tools and documentation in this repository are under the MIT licence (`LICENSE`). The packages in `dist/` contain third-party software under its own licences:

- OpenSSL 1.0.2u: OpenSSL/SSLeay licence. This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/).
- Qt 4.7 (QtNetwork): LGPL 2.1. Built from Nokia's PR1.3 source package with the changes in `patches/`.
- curl 7.21.0: curl licence.
- Mozilla CA certificate list: MPL 2.0.
- Nokia's maintainer scripts and Aegis manifests are kept unchanged in the repacked packages.

Sources of all third-party components are public; `tools/isoget.py` downloads the exact PR1.3 source packages used.
