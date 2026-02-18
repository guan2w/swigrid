#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p .build/{home,modulecache,cache,config,security}

export HOME="$ROOT_DIR/.build/home"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/modulecache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/modulecache"

swift build \
  --product SchulteApp \
  --scratch-path .build \
  --cache-path .build/cache \
  --config-path .build/config \
  --security-path .build/security \
  --disable-sandbox

swift test \
  --scratch-path .build \
  --cache-path .build/cache \
  --config-path .build/config \
  --security-path .build/security \
  --disable-sandbox
