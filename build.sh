#!/bin/bash
set -Eeuo pipefail
umask 022

supported_platforms=(
  linux-arm64v8
  linux-armv6
  linux-armv7
  linux-x64
  linuxmusl-arm64v8
  linuxmusl-x64
  darwin-x64
  darwin-arm64v8
)

function docker() {
  local command='command'
  if [[ "$(id -u)" -ne 0 ]] && ! id -znG | grep -q '\bdocker\b'; then
    command='sudo'
  fi
  ${command} -- docker "$@"
}

function arr_contains() {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

function main() {
  if [[ $# -lt 2 ]]; then
    echo "usage: $0 VERSION PLATFORM[,PLATFORM]" >&2
    return 1
  fi
  version="$1"
  IFS=, read -ra platforms <<<"$2"

  # prepare workspace
  mkdir -p workspace

  # prepare temp directory
  temp_dir="$(mktemp -d)"
  function temp_dir_cleanup() { rm -rf "$temp_dir"; }
  trap temp_dir_cleanup INT TERM EXIT

  # download libmaxminddb sources
  libmaxminddb_url="https://github.com/maxmind/libmaxminddb/releases/download/${version}/libmaxminddb-${version}.tar.gz"
  libmaxminddb_dir="workspace/sources/libmaxminddb-${version}"
  if [[ -d "$libmaxminddb_dir" ]]; then
    echo "libmaxminddb sources already exists: '${libmaxminddb_dir}'"
  else
    echo "libmaxminddb sources doesn't exists: downloading ..."
    temp_dst="${temp_dir}/libmaxminddb"
    mkdir -p "$temp_dst" && curl -fSL -- "$libmaxminddb_url" | tar -xz --strip-components 1 -C "$temp_dst"
    mkdir -p "$libmaxminddb_dir" && mv "${temp_dst}/"* "$libmaxminddb_dir"
    echo "libmaxminddb sources downloaded: '${libmaxminddb_dir}'"
  fi

  # build for each platforms
  for platform in "${platforms[@]}"; do
    if ! arr_contains "$platform" "${supported_platforms[@]}"; then
      echo "error: Unknown platform '${platform}'" >&2
      exit 1
    fi

    # prepare out directory
    out_dir="workspace/out/libmaxminddb_${version}_${platform}"
    echo "${platform}: building to '${out_dir}' ..."

    if [[ -d "$out_dir" ]]; then
      echo "${platform}: deleting the existing output directory"
      rm -rf "$out_dir"
    fi
    mkdir -p "$out_dir"
    chmod 777 "$out_dir"

    # copy notice
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
      image="libmaxminddb-build-${platform}"
      docker build -t "$image" "./${platform}"
      docker run --rm \
        -e "PLATFORM=${platform}" \
        -e "LIBMAXMINDDB_VERSION=${version}" \
        -e "LIBMAXMINDDB_DIR=/${libmaxminddb_dir}" \
        -e "OUT_DIR=/${out_dir}" \
        -v "${PWD}/workspace:/workspace" \
        -v "${PWD}/build:/build" \
        "$image" sh -c '/build/linux.sh'
      ;;
    darwin*)
      if [[ "$platform" = 'darwin-arm64v8' ]]; then
        export CHOST='aarch64-apple-darwin'
        export FLAGS='-arch arm64'
        export SDKROOT=$(xcrun -sdk macosx --show-sdk-path)
      fi

      _=_ \
        PLATFORM="$platform" \
        LIBMAXMINDDB_VERSION="$version" \
        LIBMAXMINDDB_DIR="${PWD}/${libmaxminddb_dir}" \
        OUT_DIR="${PWD}/${out_dir}" \
        sh -c "cd $(printf %q "$temp_dir") && $(printf %q "${PWD}/build/macos.sh")"
      ;;
    *)
      return 1 # theoretically unreachable statement
      ;;
    esac

    # create archives
    echo "${platform}: compressing ..."
    pushd "$(dirname "$out_dir")"
    tar -czvf "$(basename "$out_dir").tar.gz" "$(basename "$out_dir")"
    popd

    echo "${platform}: done"
  done
}

main "$@"
exit 0
