# Flutter RASP

[![pub package](https://img.shields.io/pub/v/flutter_rasp.svg)](https://pub.dev/packages/flutter_rasp)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green.svg)](https://flutter.dev)

A comprehensive **RASP** (Runtime Application Self-Protection) plugin for Flutter. Protect your app against reverse engineering, tampering, runtime attacks, and man-in-the-middle attacks.

---

## Features

### Threat Detection

| Threat | Android | iOS | Description |
|--------|:-------:|:---:|-------------|
| Root / Jailbreak | :white_check_mark: | :white_check_mark: | Compromised OS with full system access. Attackers can bypass app sandboxing, read private data, and inject code |
| Emulator / Simulator | :white_check_mark: | :white_check_mark: | Virtual environments used to automate attacks, bypass device-bound protections, and analyze app behavior at scale |
| Debugger | :white_check_mark: | :white_check_mark: | Attached debuggers (JDWP, ptrace) allow stepping through code, modifying variables at runtime, and extracting secrets |
| Hooks (Frida/Xposed) | :white_check_mark: | :white_check_mark: | Instrumentation frameworks that intercept and modify function calls at runtime, bypassing security checks |
| Repackaging | :white_check_mark: | :white_check_mark: | Tampered app re-signed with a different certificate. Used to inject malware, remove license checks, or steal data |
| Trusted Install | :white_check_mark: | :white_check_mark: | Sideloaded apps bypass store review and integrity checks, increasing risk of running modified or malicious builds |
| VPN | :white_check_mark: | :white_check_mark: | Active VPN or proxy that can intercept, inspect, and modify network traffic between the app and its servers |
| Developer Mode | :white_check_mark: | :x: | Enabled developer options expose debugging interfaces that allow unauthorized access to app internals |
| ADB Enabled | :white_check_mark: | :x: | Android Debug Bridge enabled, allowing unauthorized USB debugging access to app internals and data extraction |
| Device Passcode | :white_check_mark: | :white_check_mark: | Device without screen lock. Physical access gives unrestricted access to app data and keychain entries |
| Secure Hardware | :white_check_mark: | :white_check_mark: | Missing hardware-backed keystore (TEE/StrongBox, Secure Enclave). Cryptographic keys can be extracted by software attacks |
| Obfuscation | :white_check_mark: | :x: | Unobfuscated binary with readable class and symbol names, making reverse engineering and vulnerability discovery trivial |
| Time Spoofing | :white_check_mark: | :x: | Manipulated system clock used to bypass time-based logic like token expiration, trial periods, or certificate validity |
| Location Spoofing | :white_check_mark: | :x: | Fake GPS coordinates used to bypass geo-restrictions, cheat in location-based services, or commit region-locked fraud |
| Multi-Instance | :white_check_mark: | :x: | Cloned or dual-app environments that run multiple copies of the app to abuse promotions, bypass rate limits, or impersonate users |
| Screen Capture | :white_check_mark: | :white_check_mark: | Blocks screenshots and screen recording to prevent leaking sensitive UI content like PINs, tokens, or personal data |

### SSL Certificate Pinning

| Feature | Description |
|---------|-------------|
| PEM Certificate Pinning | Only trusts the `.pem` certificates you provide — any other connection fails automatically |
| Encrypted Certificate Pinning | Encrypt `.pem` files so they can't be extracted from your app bundle |
| Remote Certificate Updates | Fetch certificates from your API at runtime — no app update needed on rotation |
| Secure Storage | Certificates stored via Keychain (iOS) / EncryptedSharedPreferences (Android) |
| Compatible with `dart:io`, Dio, `package:http` | Works with any HTTP client that accepts a `dart:io` `HttpClient` |

---

## Getting Started

```yaml
dependencies:
  flutter_rasp: ^5.1.2
```

| Platform | Minimum Version |
|----------|----------------|
| Android | API 24 (Android 7.0) |
| iOS | 13.0 |

No additional permissions required.

---

## Usage

### Initialization

```dart
import 'package:flutter_rasp/flutter_rasp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterRasp.instance.initialize(
    config: const RaspConfig(
      policy: ThreatPolicy.high,
      monitoringInterval: Duration(seconds: 10),
      androidConfig: AndroidRaspConfig(
        signingCertHashes: ['A1:2B:3C:4D:5E:6F:70:81:92:A3:B4:C5:D6:E7:F8:09:1A:2B:3C:4D:5E:6F:70:81:92:A3:B4:C5:D6:E7:F8:09'],
      ),
      iosConfig: IosRaspConfig(
        teamId: 'A1B2C3D4E5',
        bundleIds: ['com.yourcompany.yourapp'],
      ),
    ),
    onThreatDetected: (threats) => debugPrint('$threats'),
    threatCallback: ThreatCallback(
      onRoot: () => navigateToBlockedScreen(),
      onVpn: () => showVpnWarning(),
    ),
  );

  runApp(const MyApp());
}
```

> **Note:** At least one of `onThreatDetected` or `threatCallback` must be provided.

### Platform Configuration

**Android** — `signingCertHashes` accepts the SHA-256 fingerprint directly from Google Play Console.

> **Important:** Google Play re-signs your app. You must use the **Play signing key**, not your local keystore.

Go to **Google Play Console** → your app → **Release** → **App integrity** → **App signing** and copy the **SHA-256** fingerprint from the **App signing key certificate** section. Pass it directly:

```dart
AndroidRaspConfig(
  signingCertHashes: ['A1:2B:3C:4D:5E:6F:70:81:92:A3:B4:C5:D6:E7:F8:09:1A:2B:3C:4D:5E:6F:70:81:92:A3:B4:C5:D6:E7:F8:09'],
)
```

**iOS** — Find your Team ID at [Apple Developer Account](https://developer.apple.com/account) → **Membership Details**.

### SSL Certificate Pinning

> **Tip:** Initialize SSL pinning at app startup (e.g., in `main()`) before making any HTTP request. The first call builds and caches the `SecurityContext` — subsequent calls return instantly with zero latency.

Download your server's certificate:

```bash
openssl s_client -connect your-api.com:443 -servername your-api.com \
  2>/dev/null | openssl x509 > assets/certs/your_server.pem
```

Register it in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/certs/
```

#### Plain PEM

```dart
const config = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/your_server.pem'],
);

final client = await SslPinningClient.createHttpClient(config);
```

#### Encrypted PEM

Encrypt your `.pem` with the [Certificate Encryptor](tool/certificate_encryptor/) web tool, then place the `.enc` file in your assets:

```dart
const config = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/your_server.enc'],
  passphrase: 'your_passphrase',
);

final client = await SslPinningClient.createHttpClient(config);
```

#### Remote Certificate Updates

Pass an `onFetchRemote` callback to update certificates at runtime — no app update needed on server certificate rotation. Each config represents one endpoint with one certificate:

```dart
// API endpoint
const apiConfig = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/api.enc'],
  passphrase: 'your_passphrase',
);

final apiClient = await SslPinningClient.createHttpClient(
  apiConfig,
  onFetchRemote: () async {
    final response = await yourApi.get(
      '/certs/current.enc',
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.bodyBytes;
  },
);

// CDN endpoint (independent config, independent storage)
const cdnConfig = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/cdn.enc'],
  passphrase: 'your_passphrase',
);

final cdnClient = await SslPinningClient.createHttpClient(
  cdnConfig,
  onFetchRemote: () async {
    final response = await yourCdn.get('/certs/cdn.enc');
    return response.bodyBytes;
  },
);
```

The plugin resolves each certificate independently: stored cert → remote fetch → asset fallback. Stored certificates use **Keychain** (iOS) and **EncryptedSharedPreferences** (Android), and are only written when the content changes.

```dart
await SslPinningClient.clearStoredCertificate(apiConfig);
SslPinningClient.invalidateCache();
```

#### HTTP Client Compatibility

Works with any HTTP client that accepts a `dart:io` `HttpClient`:

```dart
// dart:io
final request = await client.getUrl(Uri.parse('https://your-api.com/endpoint'));

// Dio
final dio = Dio()
  ..httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => client,
  );

// package:http
final httpClient = IOClient(client);
```

You can also use `SslPinningClient.createContext(config)` to get a `SecurityContext` directly if you need more control.

See the [example app](example/lib/notifiers/ssl_pinning_notifier.dart) for a complete working implementation.

### Supported Stores / Distribution Methods

The `supportedStores` parameter in `AndroidRaspConfig` controls which install sources are considered trusted.

| Store / Distribution method | Package name                      | Notes                                    |
|-----------------------------|-----------------------------------|------------------------------------------|
| App Store (iOS)             |                                   | Included by default, no action needed    |
| TestFlight (iOS)            |                                   | Included by default, no action needed    |
| Google Play                 | `com.android.vending`             | Included by default, no action needed    |
| Huawei AppGallery           | `com.huawei.appmarket`            | Included by default, no action needed    |
| Amazon Appstore             | `com.amazon.venezia`              | Included by default, no action needed    |
| Samsung Galaxy Store        | `com.sec.android.app.samsungapps` | Included by default, no action needed    |
| Firebase App Distribution   | `dev.firebase.appdistribution`    | Included by default, no action needed    |
| Vivo App Store              | `com.vivo.appstore`               | Included by default. Common on Vivo devices |
| HeyTap                      | `com.heytap.market`               | Included by default. Common on Realme and Oppo devices |
| Oppo App Market             | `com.oppo.market`                 | Included by default. Common on Oppo devices |
| GetApps                     | `com.xiaomi.mipicks`              | Included by default. Common on Xiaomi, Redmi and POCO devices |

By default you don't need to set `supportedStores` at all — the full list above is applied automatically:

```dart
// Uses every store marked "Included by default".
AndroidRaspConfig(signingCertHashes: ['...']);
```

If you **do** pass `supportedStores`, the value **replaces** the defaults entirely (it is not merged). To allow a custom store alongside the built-in ones, spread `AndroidRaspConfig.defaultSupportedStores`:

```dart
AndroidRaspConfig(
  signingCertHashes: ['...'],
  supportedStores: [
    ...AndroidRaspConfig.defaultSupportedStores,
    'com.your.custom.store',
  ],
);
```

To trust **only** a specific subset (e.g. enterprise distribution where only one store is valid), pass just those package names:

```dart
AndroidRaspConfig(
  signingCertHashes: ['...'],
  supportedStores: ['com.your.private.store'], // defaults are discarded
);
```

### Threat Policies

Policies control which threats **terminate the app at the native level** before Dart code can react.

| Policy | Exit Threats |
|--------|-------------|
| `ThreatPolicy.none` | None (report only) |
| `ThreatPolicy.low` | repackaging, trustedInstall |
| `ThreatPolicy.medium` | root, hook, repackaging, trustedInstall, obfuscationIssues, multiInstance |
| `ThreatPolicy.high` | root, hook, repackaging, trustedInstall, debug, devicePasscode, obfuscationIssues, multiInstance, secureHardwareNotAvailable, locationSpoofing, adbEnabled |

```dart
const policy = ThreatPolicy(
  exitThreats: {Threat.root, Threat.repackaging, Threat.vpn},
);
```

> **Tip:** Use `ThreatPolicy.none` during development.

### Obfuscation Detection (Android)

`flutter run` → detected (debug has no R8)
`flutter run --release` → not detected (R8 obfuscates classes)

Enable R8 in `android/app/build.gradle.kts`:

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

> **Note:** Flutter's `--obfuscate` flag only covers Dart code. `isMinifyEnabled = true` is required to obfuscate the native Android layer.

### Scans & Individual Checks

```dart
final result = await FlutterRasp.instance.scanAll();
if (result.isCompromised) {
  debugPrint('Detected: ${result.detectedThreats}');
}
```

Available: `isRooted()`, `isEmulator()`, `isDebugged()`, `isHooked()`, `isRepackaged()`, `isUntrustedInstall()`, `isVpnConnected()`, `isDeveloperMode()`, `isAdbEnabled()`, `isDevicePasscodeDisabled()`, `isSecureHardwareUnavailable()`, `hasObfuscationIssues()`, `isTimeSpoofed()`, `isLocationSpoofed()`, `isMultiInstance()`.

### Screen Capture Protection

```dart
await FlutterRasp.instance.blockScreenCapture(true);
```

---

## Architecture

```
Flutter App
    |
FlutterRasp (Singleton)             SslPinningClient
    |                                    |
FlutterRaspPlatform (Interface)     CertificateDecryptor (encrypted .enc)
    |                               CertificateStore     (Keychain / EncryptedSharedPrefs)
PigeonFlutterRasp                   SecurityContext       (withTrustedRoots: false)
    |--- FlutterRaspHostApi  (type-safe commands/checks)
    |--- FlutterRaspFlutterApi (type-safe threat stream)
    |
    Android (Kotlin)                 iOS (Swift)
    -------------------              -------------------
    FlutterRaspPlugin                FlutterRaspPlugin
        |                                |
    flutter_rasp_core (AAR)          flutter_rasp_core (XCFramework)
```

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Adding a New Detector

1. Create a detector class implementing `ThreatDetector` (Android) or `ThreatDetectable` (iOS)
2. Add it to the `DetectorRegistry` list
3. Add the corresponding `Threat` enum value in Dart

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
