#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/sqlite-vec"
LIB_DIR="$REPO_ROOT/lib/sqlite-vec/x86_64-linux"
BUILD_DIR="${BUILD_DIR:-$SCRIPT_DIR/.build/sqlite-vec/x86_64-linux}"

ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" ]]; then
  echo "This script must run on x86_64 Linux; current architecture is: $ARCH" >&2
  echo "Use build-sqlite-vec-wsl.ps1 for the local WSL aarch64 build." >&2
  exit 1
fi

command -v cc >/dev/null || { echo "a C compiler is required" >&2; exit 1; }

CFLAGS=(-fPIC -shared -Wall -Wextra -O3 -Ivendor)
if grep -q -m1 -o 'avx[^ ]*' /proc/cpuinfo 2>/dev/null; then
  CFLAGS+=(-mavx -mavx2 -DSQLITE_VEC_ENABLE_AVX)
fi

mkdir -p "$BUILD_DIR"
cc "${CFLAGS[@]}" "$SOURCE_DIR/sqlite-vec.c" \
  -o "$BUILD_DIR/vec0.so" -lm

mkdir -p "$LIB_DIR"
cp -f "$BUILD_DIR/vec0.so" "$LIB_DIR/"

echo
echo "sqlite-vec x86_64 Linux runtime file:"
ls -lh "$LIB_DIR/vec0.so"
