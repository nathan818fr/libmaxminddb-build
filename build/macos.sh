#!/bin/sh
set -e

export FLAGS="${FLAGS:-} -fPIC"
export LDFLAGS="${LDFLAGS:-} -framework CoreServices -framework CoreFoundation -framework Foundation -framework AppKit"
export MAKEFLAGS="${MAKEFLAGS:-} -j$(sysctl -n hw.logicalcpu)"

export CC='clang'
export CXX='clang++'
export MACOSX_DEPLOYMENT_TARGET='11.0'

"$(dirname "$0")/with_autotools.sh"

exit 0
