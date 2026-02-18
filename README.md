# Schulte Grid iOS (WIP)

Current implementation includes core business logic, persistence, and a runnable SwiftUI app.

## Modules

- `SchulteDomain`: game rules, entities, state machine, scoring, use cases, repository protocols
- `SchulteData`: local repositories and key-value store adapters
- `SchulteFeatures`: UI-facing view models for Home/Game/Records
- `SchulteAppUI`: Home -> Game -> Result -> Home / Records navigation and iOS-style screens
- `SchulteApp`: executable wrapper for SwiftPM local run, reusing `SchulteAppUI`

## Project layout

- `swigrid.xcodeproj`: iOS app shell project (open this in Xcode)
- `swigrid/`: app entry and app-level resources
- `swigridUITests/`: iPhone/iPad UI smoke tests
- `Package.swift`: local Swift Package manifest
- `Sources/` + `Tests/`: core business modules and unit/integration tests

## Current scope

- iOS deployment target baseline updated to `iOS 26+`
- Portrait-focused UX for iPhone/iPad
- App-level portrait orientation lock enabled for iOS runtime
- Legacy assets wired: fonts, audio, about/help markdown
- Sound + haptic feedback on game interactions
- Animated home background and next-number hint emphasis
- Responsive width tuning for iPhone/iPad portrait (home/game/records)
- Accessibility identifiers added for key controls (UI test ready)

## Local verification

```bash
mkdir -p .build/{home,modulecache,cache,config,security}
HOME=$(pwd)/.build/home \
SWIFTPM_MODULECACHE_OVERRIDE=$(pwd)/.build/modulecache \
CLANG_MODULE_CACHE_PATH=$(pwd)/.build/modulecache \
swift test \
  --scratch-path .build \
  --cache-path .build/cache \
  --config-path .build/config \
  --security-path .build/security \
  --disable-sandbox
```

or simply:

```bash
./scripts/verify.sh
```

Verify SwiftPM with Xcode backend:

```bash
./scripts/verify-xcode-backend.sh
```

Verify Xcode iOS app shell (`swigrid.xcodeproj`):

```bash
./scripts/verify-ios-app.sh
```

Run iPhone/iPad UI smoke tests (XCUITest):

```bash
./scripts/verify-ios-ui-tests.sh
```

Note: with portrait-only orientation on iOS 26, `xcodebuild` may print an interface-orientation warning while still producing a valid build artifact.

## Next

- Add codesign/TestFlight packaging on top of the current Xcode shell
- Add release checklist automation (Go/No-Go -> TestFlight)

## Build app prototype

```bash
HOME=$(pwd)/.build/home \
SWIFTPM_MODULECACHE_OVERRIDE=$(pwd)/.build/modulecache \
CLANG_MODULE_CACHE_PATH=$(pwd)/.build/modulecache \
swift build \
  --product SchulteApp \
  --scratch-path .build \
  --cache-path .build/cache \
  --config-path .build/config \
  --security-path .build/security \
  --disable-sandbox
```

## Verify iOS simulator compile

```bash
./scripts/verify-ios-sim.sh
```

Note: SwiftPM executable linking for iOS simulator may print a sysroot warning in this environment, but build completion is still used as compatibility smoke check.

## CI

- Workflow: `.github/workflows/ios-ci.yml`
- Lint/format config: `.swiftlint.yml`, `.swiftformat`
