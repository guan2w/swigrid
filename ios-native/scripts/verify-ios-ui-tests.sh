#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT_DIR/ios-app/swigrid.xcodeproj"
SCHEME="swigrid"

mkdir -p "$ROOT_DIR/.build-ui"/{home,modulecache}

export HOME="$ROOT_DIR/.build-ui/home"
export SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build-ui/modulecache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build-ui/modulecache"

if [[ ! -d "$PROJECT" ]]; then
  echo "Missing iOS project: $PROJECT" >&2
  exit 1
fi

if ! DESTINATIONS="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations)"; then
  echo "Failed to query simulator destinations for $PROJECT." >&2
  exit 1
fi

pick_destination() {
  local kind="$1"
  shift

  local name
  for name in "$@"; do
    if grep -Fq "platform:iOS Simulator" <<<"$DESTINATIONS" && grep -Fq "name:$name" <<<"$DESTINATIONS"; then
      printf "platform=iOS Simulator,name=%s" "$name"
      return 0
    fi
  done

  echo "No $kind simulator matched: $*" >&2
  echo "Available destinations:" >&2
  echo "$DESTINATIONS" >&2
  return 1
}

run_ui_test() {
  local destination="$1"
  local derived_data_path="$2"
  local test_case="$3"

  xcodebuild \
    test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -derivedDataPath "$ROOT_DIR/$derived_data_path" \
    -only-testing:"$test_case" \
    CODE_SIGNING_ALLOWED=NO
}

IPHONE_DESTINATION="$(pick_destination iPhone "iPhone 17" "iPhone 17 Pro" "iPhone 16e" "iPhone Air")"
IPAD_DESTINATION="$(pick_destination iPad "iPad (A16)" "iPad Pro 11-inch (M4)" "iPad Air 11-inch (M3)" "iPad mini (A17 Pro)")"

run_ui_test "$IPHONE_DESTINATION" ".build-ios-ui-test" "swigridUITests/testCoreFlowSavesRecord"
run_ui_test "$IPHONE_DESTINATION" ".build-ios-ui-test" "swigridUITests/testMutePersistsAfterRelaunch"
run_ui_test "$IPAD_DESTINATION" ".build-ios-ui-test-ipad" "swigridUITests/testCoreFlowSavesRecord"
