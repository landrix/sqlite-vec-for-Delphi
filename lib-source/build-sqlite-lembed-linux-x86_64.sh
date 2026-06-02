#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-build-linux-x86_64}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/sqlite-lembed"
LIB_DIR="$REPO_ROOT/lib/sqlite-lembed/x86_64-linux"

ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" ]]; then
  echo "This script must run on x86_64 Linux; current architecture is: $ARCH" >&2
  echo "Use build-sqlite-lembed-wsl.ps1 for the local WSL aarch64 build." >&2
  exit 1
fi

command -v cmake >/dev/null || { echo "cmake is required" >&2; exit 1; }
command -v ninja >/dev/null || { echo "ninja is required" >&2; exit 1; }
command -v cc >/dev/null || { echo "a C compiler is required" >&2; exit 1; }
command -v c++ >/dev/null || { echo "a C++ compiler is required" >&2; exit 1; }

cmake -S "$SOURCE_DIR" -B "$SOURCE_DIR/$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE="$CONFIGURATION"
cmake --build "$SOURCE_DIR/$BUILD_DIR" --config "$CONFIGURATION" \
  --target sqlite_lembed

RUNTIME_DIR="$SOURCE_DIR/$BUILD_DIR/bin"
RUNTIME_FILES=(
  "lembed0.so"
  "libllama.so"
  "libggml.so"
  "libggml-base.so"
  "libggml-cpu.so"
)

mkdir -p "$LIB_DIR"
for file in "${RUNTIME_FILES[@]}"; do
  if [[ ! -f "$RUNTIME_DIR/$file" ]]; then
    echo "Missing runtime file: $RUNTIME_DIR/$file" >&2
    exit 1
  fi
  cp -f "$RUNTIME_DIR/$file" "$LIB_DIR/"
done

echo
echo "sqlite-lembed x86_64 Linux runtime files:"
ls -lh "$LIB_DIR"/{lembed0.so,libllama.so,libggml.so,libggml-base.so,libggml-cpu.so}
