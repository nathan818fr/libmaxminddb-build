#!/bin/sh
set -e

echo "PLATFORM=$PLATFORM"
echo "CHOST=$CHOST"
echo "FLAGS=$FLAGS"
echo "LDFLAGS=$LDFLAGS"

export CFLAGS="$FLAGS"
export CXXFLAGS="$FLAGS"
export OBJCFLAGS="$FLAGS"
export OBJCXXFLAGS="$FLAGS"
if [ -z "$CC" ]; then
  # fix libtap compilation
  if [ -z "$CHOST" ]; then export CC='gcc'; else export CC="${CHOST}-gcc"; fi
fi

set -x

cp -a "${LIBMAXMINDDB_DIR}/" sources/
cd sources
./configure --host="$CHOST" --disable-binaries
make $MAKEFLAGS

if [ -z "$CHOST" ]; then # skip tests during cross-platform compilation
  make check | grep -v '^ok '
fi

cp include/*.h src/.libs/libmaxminddb.a "$OUT_DIR"

exit 0
