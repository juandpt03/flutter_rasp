## 5.1.2

- Fixed root detection false positives on Samsung One UI and other Android 14+ devices
- Improved Magisk, KernelSU, and APatch detection accuracy (Android)

## 5.1.1

- Added Firebase App Distribution, Vivo, HeyTap, Oppo, and GetApps to the default `supportedStores` list in `AndroidRaspConfig` so apps published through these stores no longer trigger trusted-install warnings out of the box
- Fixed iOS Swift Package Manager integration — `FlutterRaspCore.xcframework` now lives inside the SPM package root so SPM-based hosts can resolve it correctly

## 5.1.0

- Migrated platform communication from manual `MethodChannel`/`EventChannel` to Pigeon for type-safe, generated native bindings

## 5.0.1

- Downgraded `pointycastle` to `^3.9.1` for broader compatibility with existing projects

## 5.0.0

- Added encrypted certificate pinning — encrypt `.pem` files with a passphrase so they can't be extracted from the APK/IPA
- Added remote certificate updates via `onFetchRemote` callback — one config per endpoint, each with independent storage and caching
- Added secure on-device certificate storage via Keychain (iOS) and EncryptedSharedPreferences (Android)
- Added in-memory certificate cache — initialize at app startup for zero-latency on subsequent calls
- Added automatic fallback chain: stored certificate → remote fetch → bundled asset
- Added certificate format validation for `.pem`, `.crt`, `.cer`, and `.enc` files
- Added Certificate Encryptor web tool (`tools/certificate_encryptor/`)

## 4.0.3

- Documentation and README improvements

## 4.0.2

- Fixed VPN detection false positives on physical iOS devices (iOS)

## 4.0.1

- Fixed hook detection false positives on TestFlight builds (iOS)
- Improved hook detection accuracy and reduced false positive surface (iOS)

## 4.0.0

- **Breaking:** Native detection logic is now distributed as pre-compiled binaries instead of source code (Android & iOS)
- Improved plugin security — detection algorithms are obfuscated and protected against reverse engineering

## 3.6.0

- Strengthened root and jailbreak detection with new bypass-resistant techniques (Android & iOS)
- Improved hook detection with runtime memory and thread analysis (Android & iOS)
- Improved debug detection with additional process-level checks (Android & iOS)
- Expanded emulator/simulator detection coverage (Android & iOS)
- Expanded cloner and mock location app databases (Android)

## 3.5.4

- Fixed iOS repackaging false positives caused by generic dylib name matching
- Expanded suspicious dylib detection list based on OWASP MASTG and IOSSecuritySuite (iOS)

## 3.5.3

- `signingCertHashes` now accepts SHA-256 hex with colons directly from Google Play Console (Android)

## 3.5.2

- Skip redundant team ID and bundle ID checks on App Store/TestFlight (iOS)
- Trust App Store and TestFlight as valid install sources (iOS)

## 3.5.1

- Improved TestFlight detection — uses `sandboxReceipt` as sole reliable indicator (iOS)

## 3.5.0

- Fixed repackaging false positives on App Store, TestFlight, and unconfigured builds (Android & iOS)
- Fixed trusted install false positives on TestFlight (iOS)
- Fixed VPN false positives caused by iOS internal `utun` interfaces
- Fixed iOS monitoring not resuming after returning from background
- Improved TestFlight detection — uses `sandboxReceipt` as sole indicator (iOS)
- Improved `TrustedInstallDetector` with `initiatingPackageName` fallback (Android 11+)
- Added `com.apple.developer.team-identifier` fallback for Team ID extraction (iOS)

## 3.4.0

- Removed `deviceBinding` threat — device fingerprinting proved unreliable across OS updates and factory resets

## 3.3.0

- Fixed `ObfuscationDetector` false positives — now inspects internal DEX classes instead of manifest components (Android)
- Fixed R8 build failure on release builds (Android)
- Separated ProGuard consumer rules to avoid side effects on host apps

## 3.2.0

- Added Swift Package Manager support for iOS

## 3.1.2

- Updated README with direct `keytool -exportcert` command for obtaining SHA-256 hash in Base64

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
