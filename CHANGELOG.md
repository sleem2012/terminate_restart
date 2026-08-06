## Unreleased

### Improvements
* **Swift Package Manager support for iOS**: the plugin now ships a `Package.swift`, so it resolves natively under SwiftPM — the default integration for Flutter plugins as of Flutter 3.44
  * iOS sources moved from `ios/Classes/` to `ios/terminate_restart/Sources/terminate_restart/`
  * `ios/terminate_restart.podspec` now points at the new source path, so **CocoaPods keeps working unchanged** — no action is required from existing users on either integration
  * Example app's Xcode project migrated to the Swift Package Manager integration

## 1.1.0

### New Features
* **Web platform support**: Full restart functionality for web browsers (PR #10 by @dario-valles)
  * Page reload for both terminate and UI-only restart modes
  * Browser storage clearing: localStorage, sessionStorage, cookies, IndexedDB, Cache API
  * Configurable data preservation matching native API
* **`wrapWithRestart` widget**: New `TerminateRestart.wrapWithRestart()` method that wraps your app to enable proper UI-only restart (`terminate: false`) with full widget tree rebuild

### Bug Fixes
* **Fixed iOS crash** (Issue #9): Resolved crash on iOS when performing UI-only restart
  * Removed crash-prone new engine creation approach (`destroyContext()` did not exist on `FlutterEngine`)
  * UI-only restart now recreates `FlutterViewController` with the **same engine** (safe, no crash)
  * Sends `resetToRoot` to Dart side to trigger full widget tree rebuild via `wrapWithRestart`
  * Replaced deprecated `keyWindow`/`windows` APIs with `connectedScenes` for iOS 13+
  * Fixed keychain clearing query that prevented proper deletion
  * Added specific error codes and messages for better debugging
* **Fixed web double-tap issue**: `location.replace(sameUrl)` doesn't trigger a reload in most browsers — now uses `location.reload()` for both modes with `scheduleMicrotask` for immediate response
* **Fixed duplicate class definitions**: Removed conflicting `TerminateRestartOptions`, `RestartMode`, and `TerminateRestart` class definitions from `terminate_restart_base.dart`
* **Fixed podspec version mismatch**: Synced podspec version with pubspec
* **Fixed Android dead code**: Removed unreachable engine recreation code that ran on a finishing Activity

### Improvements
* Migrated `restartApp` to use platform interface pattern instead of direct `MethodChannel`
* Updated iOS minimum deployment target from 10.0 to 12.0
* Added 7 working unit tests (previously 100% commented out)
* Added `gc` method handler in iOS plugin
* Added `kIsWeb` guard for internal method channel setup
* Cleaned up unused Android imports (`AlarmManager`, `PendingIntent`, `Process`, `exitProcess`)
* Updated example app to use `wrapWithRestart` and upgraded `google_fonts` to 6.3.3 for Flutter 3.38+ web compatibility

## 1.0.10

* Fixed Swift compiler error in Xcode 16.2 with Flutter 3.29.0:
  * Modified engine property access to handle non-optional FlutterEngine type
* Added documentation for required iOS configuration:
  * Detailed URL scheme configuration in Info.plist for iOS restart functionality
* Improved compatibility with latest Flutter versions

## 1.0.9

* Documentation improvements:
  * Improved README.md formatting and organization
  * Removed emoji icons for better readability
  * Made code examples more concise
  * Fixed markdown formatting issues

## 1.0.8

* Documentation improvements:
  * Streamlined Getting Started section
  * Removed redundant sections
  * Made code examples more concise
  * Added feature comparison table
  * Improved overall readability

## 1.0.7

* Updated deprecated platform message handling to use `channelBuffers.push`
* Enhanced documentation:
  - Added Quick Start guide for faster onboarding
  - Added iOS App Store compliance section
  - Added comprehensive usage table with examples
  - Added confirmation dialog examples
  - Improved code formatting and organization
* Updated README with clearer installation and usage instructions
* Fixed code examples and method signatures

## 1.0.6

* Code maintenance and improvements
* Updated dependencies to latest compatible versions
* Enhanced code documentation
* Minor bug fixes and performance improvements

## 0.0.1

Initial release with the following features:

* Complete app termination and restart functionality
* Platform-specific implementations for Android and iOS
* Extensive customization options
* Perfect integration with Shorebird and other dynamic update systems
* App data management options
* Fast and reliable operation
* Comprehensive documentation and examples

### Features

* Proper process termination and restart on both platforms
* Customizable confirmation dialogs
* Timeout handling with fallback messages
* Data clearing options with granular control
* Platform-specific flags and options
* Comprehensive error handling and reporting
* Type-safe API with proper null safety

### Android Features

* Process.killProcess() for proper termination
* Configurable Intent flags
* Activity lifecycle management
* App data clearing options
* Proper error handling and logging

### iOS Features

* Clean process termination
* Configurable exit codes
* UserDefaults preservation options
* Keychain management
* Cache and temp file clearing

## 1.0.0

* Initial release with the following features:
  * Support for both Android and iOS platforms
  * Two restart modes: UI-only and full process termination
  * Optional data clearing during restart
  * Configurable data preservation options (keychain, user defaults)
  * Confirmation dialog support with customizable messages
  * Comprehensive example app demonstrating all features
  * Fixed data clearing functionality in both UI and terminate modes
  * Added extensive error handling and logging
  * Added type-safe API with null safety support

### Features
- Full app restart functionality
- UI-only refresh option
- Data clearing with selective preservation
- Extensive customization options
- Cross-platform support (Android & iOS)
- Comprehensive logging
- Type-safe implementation

### Android Implementation
- Proper process termination
- Activity/task management
- Intent flag handling
- State preservation options

### iOS Implementation
- Clean process termination
- State restoration
- Data management
- Background task handling

### Documentation
- Comprehensive README
- API documentation
- Usage examples
- Common issues & solutions

## 1.0.3

### 🚀 New Features
- Improved UI-only restart functionality:
  - Maintains WebSocket and HTTP connections
  - Properly resets to root state
  - Smooth transition animations
  - Added `initialize` method with `onRootReset` callback
- Better platform-specific implementations:
  - iOS: Uses proper view controller transitions
  - Android: Maintains Flutter engine while resetting activity

### 🛠️ Improvements
- Added comprehensive documentation
- Added comparison of restart modes
- Added best practices guide
- Improved error handling
- Added example code for common use cases

### 🐛 Bug Fixes
- Fixed UI-only restart not properly resetting to root
- Fixed Android activity recreation issues
- Fixed iOS view controller transition glitches

## 1.0.4

* Added `TerminateRestart.instance` singleton pattern for better state management
* Enhanced initialization with comprehensive state reset examples
* Added support for different state management solutions (GetX, Provider, Bloc)
* Improved documentation with real-world examples
* Updated all code examples to use the new instance pattern
* Fixed UI-only restart implementation
* Added proper error handling for timeouts and platform-specific errors

* Enhanced Android restart functionality:
  * Using `makeRestartActivityTask` for more reliable app restart
  * Improved activity recreation and state management
  * Better handling of process termination

* Improved iOS implementation:
  * Better URL scheme handling for app restart
  * Enhanced view controller management
  * Proper state preservation during restarts

* General improvements:
  * More reliable UI-only restart on both platforms
  * Better error handling and logging
  * Code cleanup and documentation updates

## 1.0.5

* Improved code formatting and organization
* Enhanced error handling with specific PlatformException handling
* Updated method channel naming for better consistency
* Added comprehensive API documentation
* Fixed UI restart functionality
* Added back navigation handling for Android
* Improved static analysis compliance

## 1.0.6

* Fixed critical issue with UI-only restart where plugins would fail to register properly
* Added plugin registration wait mechanism for UI restarts
* Added comprehensive FAQ section
* Added advanced use cases with code examples
* Added flow diagram explaining plugin architecture
* Updated documentation with clearer examples
* Improved media assets and documentation structure
* Enhanced error handling documentation
* Added more real-world examples
