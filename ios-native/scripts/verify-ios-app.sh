#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/ios-app/swigrid.xcodeproj"
SCHEME="swigrid"

mkdir -p "$ROOT_DIR/.build-ios-app-env"/{home,modulecache}

export HOME="$ROOT_DIR/.build-ios-app-env/home"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build-ios-app-env/modulecache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-ios-app-env/modulecache"

if [[ ! -d "$PROJECT" ]]; then
  echo "Missing iOS project: $PROJECT" >&2
  exit 1
fi

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$ROOT_DIR/.build-ios-app" \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 17" \
  -derivedDataPath "$ROOT_DIR/.build-ios-app-sim" \
  CODE_SIGNING_ALLOWED=NO \
  build
