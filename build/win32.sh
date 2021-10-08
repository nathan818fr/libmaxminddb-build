#!/bin/sh
set -e

set -x

# Build
cp -a "${LIBMAXMINDDB_DIR}/" sources/
cd sources
cmake -A "$MSVC_ARCH" -DBUILD_SHARED_LIBS=OFF .
cmake --build . --config Release

# Test
ctest -V . | grep -vE '^[0-9]+: ok '

# Copy
cp include/*.h Release/maxminddb.lib "$OUT_DIR"

exit 0
