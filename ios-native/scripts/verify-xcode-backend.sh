#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .build-xcode/{home,modulecache,cache,config,security}

export HOME="$ROOT_DIR/.build-xcode/home"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build-xcode/modulecache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-xcode/modulecache"

swift build \
  --build-system xcode \
  --product SchulteApp \
  --scratch-path .build-xcode \
  --cache-path .build-xcode/cache \
  --config-path .build-xcode/config \
  --security-path .build-xcode/security \
  --disable-sandbox
