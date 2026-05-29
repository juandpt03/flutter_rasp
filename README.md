# Flutter RASP

[![pub package](https://img.shields.io/pub/v/flutter_rasp.svg)](https://pub.dev/packages/flutter_rasp)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-android%20%7C%20ios-green.svg)](https://flutter.dev)

RASP (Runtime Application Self-Protection) for Flutter. Detects
runtime tampering and ships every event to your own backend.

## Features

- Threat detection (16 threats including root/jailbreak, hooks,
  debugger, repackaging, untrusted install, emulator, VPN…).
- Real-time monitoring with native-level termination when a
  configured threat fires.
- Screen capture protection.
- SSL certificate pinning (plain `.pem`, encrypted `.enc`, remote
  cert updates with secure storage).
- Built-in security reporter — every detected threat, policy-
  triggered exit and uncaught Dart error shipped to your HTTPS
  endpoint with HMAC + optional pinning.

| Platform | Minimum |
| -------- | ------- |
| Android  | API 24  |
| iOS      | 13.0    |

```yaml
dependencies:
  flutter_rasp: ^6.1.0
```

---

## Threat detection

| Threat | Android | iOS |
| --- | :---: | :---: |
| Root / Jailbreak | ✅ | ✅ |
| Emulator / Simulator | ✅ | ✅ |
| Debugger | ✅ | ✅ |
| Hooks (Frida / Xposed) | ✅ | ✅ |
| Repackaging | ✅ | ✅ |
| Trusted install | ✅ | ✅ |
| VPN | ✅ | ✅ |
| Device passcode | ✅ | ✅ |
| Secure hardware | ✅ | ✅ |
| Screen capture block | ✅ | ✅ |
| Developer mode | ✅ | — |
| ADB enabled | ✅ | — |
| Obfuscation | ✅ | — |
| Time spoofing | ✅ | — |
| Location spoofing | ✅ | — |
| Multi-instance | ✅ | — |

### Initialize

```dart
await FlutterRasp.instance.initialize(
  config: const RaspConfig(
    policy: ThreatPolicy.high,
    monitoringInterval: Duration(seconds: 10),
    androidConfig: AndroidRaspConfig(
      signingCertHashes: ['<sha256-from-Play-Console>'],
    ),
    iosConfig: IosRaspConfig(
      teamId: '<APPLE-TEAM-ID>',
      bundleIds: ['com.your.bundle'],
    ),
  ),
  onThreatDetected: (threats) => debugPrint('$threats'),
);
```

> Provide at least one of `onThreatDetected` or `threatCallback`.

**`signingCertHashes`** is the SHA-256 of the **Play signing key**
(Play Console → App integrity → App signing). **`teamId`** is on
[developer.apple.com](https://developer.apple.com/account) →
Membership Details.

### Threat policies

| Policy | Terminates on |
| --- | --- |
| `ThreatPolicy.none` | nothing (report-only) |
| `ThreatPolicy.low` | repackaging, trustedInstall |
| `ThreatPolicy.medium` | + root, hook, obfuscationIssues, multiInstance |
| `ThreatPolicy.high` | + debug, devicePasscode, secureHardware, adbEnabled, locationSpoofing |

Or roll your own:
```dart
const policy = ThreatPolicy(exitThreats: {Threat.root, Threat.vpn});
```

### On-demand scan

```dart
final result = await FlutterRasp.instance.scanAll();
if (result.isCompromised) print(result.detectedThreats);
```

Or per-threat: `isRooted()`, `isEmulator()`, `isHooked()`,
`isVpnConnected()`, etc. — one method per `Threat` value.

### Screen capture protection

```dart
await FlutterRasp.instance.blockScreenCapture(true);
```

---

## SSL certificate pinning

```dart
const config = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/api.pem'],
);
final client = await SslPinningClient.createHttpClient(config);
```

Works with `dart:io`, Dio (`IOHttpClientAdapter`), `package:http`
(`IOClient`).

**Encrypted PEM** — encrypt with the [Certificate Encryptor](tool/certificate_encryptor/) web tool, pass `passphrase`:
```dart
const config = SslPinningConfig(
  certificateAssetPaths: ['assets/certs/api.enc'],
  passphrase: 'your_passphrase',
);
```

**Remote updates** — fetch a new cert at runtime; the plugin
stores it in Keychain (iOS) / EncryptedSharedPreferences (Android)
and falls back to the asset if the fetch fails:
```dart
final ctx = await SslPinningClient.createContext(
  config,
  onFetchRemote: () => yourApi.fetchCert(),
);
```

Resolution chain: memory → stored cert (background refresh) →
remote fetch → asset.

`SslPinningClient.cachedPem(config)` returns the resolved PEM
bytes synchronously after the first call — forward to the
reporter's `pinnedCertPem` to reuse the same cert without a
second fetch.

---

## Security reporter

Pass a `ReporterConfig` to `FlutterRasp.initialize(...)` and the
plugin ships every detected threat, policy-triggered exit and
uncaught Dart error to your backend.

```dart
await FlutterRasp.instance.initialize(
  config: const RaspConfig(policy: ThreatPolicy.high, /* ... */),
  onThreatDetected: (threats) => debugPrint('$threats'),
  reporter: ReporterConfig(
    endpoint: Uri.parse('https://your-backend.example.com/v1/ingest'),
    headers: const {'X-Project-Id': 'my-app'},
    hmacKey: const String.fromEnvironment('RASP_HMAC_KEY'),
    pinnedCertPem: SslPinningClient.cachedPem(apiConfig), // optional
  ),
);
```

### Configuration

| Field | Default | Purpose |
| --- | --- | --- |
| `captureFlutterErrors` | `true` | Hook `FlutterError.onError`. |
| `capturePlatformErrors` | `true` | Hook `PlatformDispatcher.onError`. |
| `captureExitThreats` | `true` | Ship a report synchronously before RASP kills the process. |
| `captureDetectedThreats` | `true` | Auto-ship when a new threat is observed (deduped per session). |
| `maxBreadcrumbs` | `50` | FIFO cap. |
| `maxPendingReports` | `50` | On-disk queue cap. |
| `exitTimeout` | `1.5 s` | Max wait for the exit report before termination. |
| `httpTimeout` | `1.2 s` | Per-attempt timeout. |
| `retryBackoffs` | `[3 s, 9 s, 27 s]` | Backoff schedule. |
| `userId` | `null` | Optional `user.id`. |

### Wire format

```json
{
  "schemaVersion": 1,
  "reportId": "<uuid-hex>",
  "timestamp": "2026-05-27T10:30:00.000Z",
  "sessionId": "<uuid-hex>",
  "event": "enforcedExit",
  "crashThreat": "root",
  "detectedThreats": ["root", "hook"],
  "message": "enforcedExit triggered by: root",
  "breadcrumbs": [
    { "ts": "...", "category": "rasp", "level": "warning",
      "message": "threats detected" }
  ],
  "device": {
    "id": "<sha256-hex>", "platform": "android", "model": "Pixel 7",
    "manufacturer": "Google", "osVersion": "14", "apiLevel": 34,
    "locale": "es-ES", "country": "CO", "timezone": "America/Bogota",
    "isPhysicalDevice": true
  },
  "app": {
    "packageName": "com.example.app", "version": "1.2.3",
    "build": "456", "installer": "com.android.vending",
    "firstInstallMs": 1747000000000, "lastUpdateMs": 1747500000000,
    "buildType": "release", "abi": "arm64-v8a"
  },
  "network": {
    "type": "wifi", "carrier": "Claro", "mcc": "732", "mnc": "101"
  },
  "policy": { "exitThreats": ["root", "hook", "repackaging"] },
  "user": { "id": "<optional>" },
  "extras": { "source": "native" }
}
```

| Field | Description |
| --- | --- |
| `event` | `threatsDetected` · `enforcedExit` · `flutterError` · `dartError` · `manualCapture`. |
| `crashThreat` | Set only on `enforcedExit` — the threat that triggered termination. |
| `detectedThreats` | All threats observed in this event. |
| `policy.exitThreats` | The exact list the integrator configured as `exitThreats`. |
| `app.installer` | Android: package name (Play, Amazon…) or `sideload`. iOS: `appStore` / `testFlight` / `simulator` / `dev` / `enterprise` / `sideload` / `unknown`. |
| `network.type` | `wifi` / `cellular` / `ethernet` / `vpn` / `none` / `unknown`. Carrier + MCC/MNC on Android with a SIM. |
| `extras.source` | `enforcedExit` ships `"native"` (built and shipped from the native exit path). |

When `hmacKey` is set, every body is signed with `HMAC-SHA256`
and forwarded as the `X-Rasp-Signature` header.

### Reliability

- Pending reports are persisted encrypted at rest. If delivery
  fails or the process dies, the report ships on next launch.
- `enforcedExit` reports are shipped synchronously before the
  process is killed, on a bounded time budget you control with
  `exitTimeout`.
- `4xx` → permanent rejection (dropped). `5xx` / network errors →
  retried with backoff.

### What we don't collect

Source IP (your backend already has it), precise location,
advertising id, IMEI, MAC, SIM serial.

### Try it locally

The `example/` app bundles a Dart mock backend that renders every
report it receives. See [`example/README.md`](example/README.md)
for the three-step setup.

![mock backend dashboard](doc/mock_backend.png)

---

## Architecture

```
Flutter App
    ▼
Dart (public API): FlutterRasp · RaspReporter · SslPinning
    ▼  Pigeon (typed bridge)
flutter_rasp plugin (Kotlin / Swift)
    ▼  in-process
flutter_rasp_core (precompiled AAR / XCFramework)
  detectors · reporter · screen capture
```

Detectors and the reporter ship compiled and obfuscated. The Dart
layer is intentionally thin.

---

## License

MIT. See [LICENSE](LICENSE).
