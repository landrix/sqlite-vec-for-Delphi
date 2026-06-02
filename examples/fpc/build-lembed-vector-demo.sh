#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
MORMOT_SRC="$REPO_ROOT/lib-source/mORMot2/src"
OUT_DIR="$SCRIPT_DIR/bin/aarch64-linux"

mkdir -p "$OUT_DIR/units"

fpc \
  -Mdelphi \
  -Sh \
  -Fu"$MORMOT_SRC" \
  -Fu"$MORMOT_SRC/core" \
  -Fu"$MORMOT_SRC/db" \
  -Fu"$MORMOT_SRC/lib" \
  -Fu"$MORMOT_SRC/net" \
  -Fu"$MORMOT_SRC/orm" \
  -Fu"$MORMOT_SRC/rest" \
  -Fu"$MORMOT_SRC/crypt" \
  -Fu"$MORMOT_SRC/misc" \
  -Fu"$REPO_ROOT/lib-source/mORMot2/static/aarch64-linux" \
  -FU"$OUT_DIR/units" \
  -FE"$OUT_DIR" \
  "$SCRIPT_DIR/LembedVectorDemo.lpr"

echo
echo "Built: $OUT_DIR/LembedVectorDemo"
