#!/bin/sh
set -e

export FLAGS="${FLAGS:-} -fPIC -D_GLIBCXX_USE_CXX11_ABI=1"
export LDFLAGS="${LDFLAGS:-}"
export MAKEFLAGS="${MAKEFLAGS:-} -j$(nproc)"

"$(dirname "$0")/with_autotools.sh"

case "$PLATFORM" in
linuxmusl*)
  apk info musl | head -n1 | awk '{print $1}' | sed 's/^musl-//' >"${OUT_DIR}/MUSL_VERSION.txt"
  ;;
linux*)
  { if [ -n "$CROSSTOOLS_SYSROOT" ]; then "$CROSSTOOLS_SYSROOT/ldd" --version; else ldd --version; fi; } |
    head -n1 | awk '{print $NF}' >"${OUT_DIR}/GLIBC_VERSION.txt"
  ;;
esac

exit 0
