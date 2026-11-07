# Cross-build environment for Nokia N9 (Harmattan PR1.3, armv7-a hard-float, glibc 2.10)
TLS=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export SYSROOT=$TLS/sysroot
export PATH=$TLS/bin:$PATH
