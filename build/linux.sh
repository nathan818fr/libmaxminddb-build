#!/bin/sh
set -e

CHOST="${CHOST:-}"
FLAGS="${FLAGS:-} -fPIC"
LDFLAGS="${LDFLAGS:-}"

case "$PLATFORM" in
linux*)
  # Force new C++11 ABI compliance
  FLAGS="${FLAGS} -D_GLIBCXX_USE_CXX11_ABI=1"
  ;;
esac

export FLAGS
export CFLAGS="$FLAGS"
export CXXFLAGS="$FLAGS"
export OBJCFLAGS="$FLAGS"
export OBJCXXFLAGS="$FLAGS"
export LDFLAGS
if [ -z "$CHOST" ]; then export CC="gcc"; else export CC="${CHOST}-gcc"; fi # fix libtap compilation

echo "PLATFORM=$PLATFORM"
echo "CHOST=$CHOST"
echo "FLAGS=$FLAGS"
echo "LDFLAGS=$LDFLAGS"
set -x
{
  cp -a "${LIBMAXMINDDB_DIR}/" sources/
  cd sources
  ./configure --host="$CHOST" --disable-binaries
  make -j"$(nproc)"

  if [ -z "$CHOST" ]; then # skip tests during cross-platform compilation
    make check | grep -v '^ok '
  fi

  cp include/*.h src/.libs/libmaxminddb.a "$OUT_DIR"
}
set +x

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
