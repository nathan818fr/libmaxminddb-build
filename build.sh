#!/bin/bash
set -Eeuo pipefail
umask 022

supported_platforms=(
  darwin-arm64v8
  darwin-x64
  linux-arm64v8
  linux-armv6
  linux-armv7
  linux-x64
  linuxmusl-arm64v8
  linuxmusl-x64
  win32-arm64v8
  win32-ia32
  win32-x64
)

function main() {
  if [[ $# -lt 2 ]]; then
    echo "usage: $0 VERSION PLATFORM" >&2
    return 1
  fi

  version="$1"
  platform="$2"

  if ! arr_contains "$platform" "${supported_platforms[@]}"; then
    echo "error: Unknown platform '${platform}' (allowed: ${supported_platforms[*]})"
    return 1
  fi

  # prepare temp directory
  temp_dir="$(mktemp -d)"
  function temp_dir_cleanup() { rm -rf "$temp_dir"; }
  trap temp_dir_cleanup INT TERM EXIT

  # download sources
  cache_dir="${PWD}/cache"
  libmaxminddb_url="https://github.com/maxmind/libmaxminddb/releases/download/${version}/libmaxminddb-${version}.tar.gz"
  libmaxminddb_dir="${cache_dir}/libmaxminddb-${version}"
  download_if_absent 'libmaxminddb sources' "$libmaxminddb_url" "$libmaxminddb_dir"

  # prepare output directory
  if [[ "${GITHUB_REF:-}" == 'refs/tags/v'* ]]; then
    out_version="${GITHUB_REF:11}"
  else
    out_version="$version"
  fi
  out_dir="${PWD}/out/libmaxminddb_${out_version}_${platform}"
  echo "creating output directory: '${out_dir}' ..."

  if [[ -d "$out_dir" ]]; then
    echo "deleting existing output directory ..."
    rm -rf "$out_dir"
  fi

  mkdir -p "$out_dir"
  chmod 777 "$out_dir"

  # copy notice
  echo "copying notice ..."
  {
    cat "${libmaxminddb_dir}/NOTICE"
    echo
    echo '----------'
    echo
    echo 'Sources: https://github.com/maxmind/libmaxminddb'
    echo 'Built by: https://github.com/nathan818fr/libmaxminddb-build'
  } >"${out_dir}/NOTICE"

  # build
  case "$platform" in
  linux*)
    build_with_docker 'linux.sh'
    ;;
  darwin-x64)
    # TODO: Preconditions checks
    build_locally 'macos.sh'
    ;;
  darwin-arm64v8)
    # TODO: Preconditions checks
    export CHOST='aarch64-apple-darwin'
    export FLAGS='-arch arm64'
    export SDKROOT=$(xcrun -sdk macosx --show-sdk-path)
    build_locally 'macos.sh'
    ;;
  win32-x64)
    export MSVC_ARCH=x64
    build_locally 'win32.sh'
    ;;
  win32-ia32)
    export MSVC_ARCH=Win32
    build_locally 'win32.sh'
    ;;
  win32-arm64v8)
    export MSVC_ARCH=ARM64
    build_locally 'win32.sh'
    ;;
  *)
    return 1 # theoretically unreachable statement
    ;;
  esac

  # create archives
  echo "compressing ..."
  pushd "$(dirname "$out_dir")"
  tar -czvf "$(basename "$out_dir").tar.gz" "$(basename "$out_dir")"
  popd

  echo 'done'
  exit 0
}

function build_with_docker() {
  image="libmaxminddb-build-${platform}"
  docker build -t "$image" "./docker/${platform}"
  docker run --rm \
    -e "PLATFORM=${platform}" \
    -e "LIBMAXMINDDB_VERSION=${version}" \
    -e "LIBMAXMINDDB_DIR=$(docker_cache_relpath "$libmaxminddb_dir")" \
    -e "OUT_DIR=/out" \
    -v "${out_dir}:/out" \
    -v "${cache_dir}:/cache" \
    -v "${PWD}/build:/build" \
    "$image" sh -c "/build/$1"
}

function docker_cache_relpath() {
  echo "/cache/${1:${#cache_dir}}"
}

function build_locally() {
  _=_ \
    PLATFORM="$platform" \
    LIBMAXMINDDB_VERSION="$version" \
    LIBMAXMINDDB_DIR="$libmaxminddb_dir" \
    OUT_DIR="$out_dir" \
    sh -c "cd $(printf %q "$temp_dir") && $(printf %q "${PWD}/build/$1")"
}

function download_if_absent() {
  local name url dst
  name="$1"
  url="$2"
  dst="$3"

  if [[ -d "$dst" ]]; then
    echo "${name} already exists: '${dst}'"
  else
    echo "${name} doesn't exists: downloading ..."
    temp_dst="${temp_dir}/.$(sha1 "$url")"
    mkdir -p "$temp_dst" && curl -fSL --retry 3 --retry-max-time 30 -- "$url" | tar -xz --strip-components 1 -C "$temp_dst"
    mkdir -p "$dst" && mv "${temp_dst}/"* "$dst"
    echo "${name} downloaded: '${dst}'"
  fi
}

function docker() {
  local command='command'
  if [[ "$(id -u)" -ne 0 ]] && ! id -znG | grep -q '\bdocker\b'; then
    command='sudo'
  fi
  ${command} -- docker "$@"
}

function sha1() {
  if which shasum >/dev/null 2>&1; then
    echo "$1" | shasum -a1 | awk '{print $1}'
  else
    echo "$1" | sha1sum | awk '{print $1}'
  fi
}

function arr_contains() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

main "$@"
exit 0
