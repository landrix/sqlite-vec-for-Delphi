#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
LEMBED_LIB_DIR="$REPO_ROOT/lib/sqlite-lembed/aarch64-linux"
BIN="$SCRIPT_DIR/bin/aarch64-linux/VectorLembedDemo"

if [[ ! -x "$BIN" ]]; then
  "$SCRIPT_DIR/build-vector-lembed-demo.sh"
fi

export LD_LIBRARY_PATH="$LEMBED_LIB_DIR:${LD_LIBRARY_PATH:-}"
exec "$BIN"
