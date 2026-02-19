## 3.1.1

- Improved SSL pinning documentation — added certificate renewal warning and dartdoc comments
- Updated example app to use `createHttpClient()` across all HTTP clients (dart:io, Dio, package:http)

## 3.1.0

- Separated `adbEnabled` from `developerMode` (Android) — developer mode now checks only developer settings, ADB is detected independently
- Added `deviceBinding` threat — detects device hardware fingerprint changes since first app launch (Android & iOS)
- Added `isAdbEnabled()` and `isDeviceBindingChanged()` check methods
- Updated `ThreatPolicy.high` to include `adbEnabled` and `deviceBinding`
- **Breaking:** Replaced hash-based SSL pinning with PEM-based pinning via `SecurityContext`
- `SslPinningConfig` now takes `certificateAssetPaths` pointing to `.pem` certificate files
- `SslPinningClient.createContext()` returns a `SecurityContext` — use it in any `HttpClient`
- `SslPinningClient.createHttpClient()` returns a ready-to-use `HttpClient` with pinned certificates
- Removed `SslPin`, `PinValidator`, `SpkiExtractor`, `SslPinningMode`, and `onPinningFailure`

## 3.0.0

- Added SSL certificate pinning — pure Dart, zero native dependencies
- `obfuscationIssues` threat now conditionally included only on Android

## 2.0.1

- Refactored and improved test suite
- Improved documentation

## 2.0.0

- Added `secureHardwareNotAvailable` threat — detects devices without hardware-backed keystore (TEE/StrongBox on Android, Secure Enclave on iOS)
- Added `obfuscationIssues` threat — detects unobfuscated app binaries with readable class/symbol names (Android)
- Added `timeSpoofing` threat — detects disabled automatic time sync (Android)
- Added `locationSpoofing` threat — detects mock location apps and legacy mock location setting (Android)
- Added `multiInstance` threat — detects cloned/dual-app environments via user profile and cloner app scanning (Android)
- Updated `ThreatPolicy.medium` to include `obfuscationIssues`, `multiInstance`
- Updated `ThreatPolicy.high` to include `obfuscationIssues`, `multiInstance`, `secureHardwareNotAvailable`, `locationSpoofing`

## 1.1.1

- Renamed `isTrustedInstall()` → `isUntrustedInstall()` for semantic clarity
- Added `dispose()` method for resource cleanup
- Added `Threat.active` static set, eliminating repeated undefined filtering
- Fixed `RaspResult.hashCode` to be order-independent
- Fixed iOS `RepackagingDetector` treating TestFlight as App Store
- Fixed socket timeouts — 200ms on both platforms (was blocking up to 225s on iOS)
- Fixed Android `DevicePasscodeDetector` to fail-closed on exception
- Added `_ensureInitialized()` guard to screen capture methods
- Added thread safety: `NSLock` (iOS), `@Volatile` (Android) on shared state
- Extracted `AppEnvironment` singleton (iOS) to deduplicate dylib/receipt/provision checks
- Updated `ThreatPolicy` presets to include `trustedInstall` and `devicePasscode`
- Removed dead code: unused `validate()` methods, imports, redundant filtering

## 1.1.0

- **Breaking:** Renamed `tampered` → `repackaging` (`isTampered()` → `isRepackaged()`, `onTampered` → `onRepackaging`)
- Added `trustedInstall` threat — detects untrusted installation sources
- Improved iOS repackaging detection (injected dylibs, App Store fallback)
- All detectors now run on iOS simulator

## 1.0.1

- Added device passcode detection (Android & iOS)
- Restructured example app with MVVM architecture
- Added barrel files for cleaner imports

## 1.0.0

- Root/Jailbreak detection (Android & iOS)
- Emulator/Simulator detection (Android & iOS)
- Debugger detection (Android & iOS)
- Hook detection — Frida, Xposed, Cycript (Android & iOS)
- App integrity detection with signing certificate verification (Android & iOS)
- VPN connection detection (Android & iOS)
- Developer mode detection (Android)
- Screen capture protection (Android & iOS)
- Real-time threat monitoring with configurable intervals
- Individual on-demand threat checks
- Full security scan with `RaspResult`
- `ThreatPolicy` system with 4 preset levels and custom support
- Native enforcement — critical threats terminate the app before Dart code reacts
- `ThreatCallback` for per-threat callbacks
- `attachListener()` / `detachListener()` for runtime callback management
- `HashConverter` utility for SHA-256 hex ↔ Base64 conversion
