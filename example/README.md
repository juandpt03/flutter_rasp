# flutter_rasp example

A runnable Android and iOS app demonstrating threat monitoring, screen capture
protection, SSL pinning, and security reporting with [flutter_rasp](../README.md).
A local Dart backend receives reports and serves the certificate fixtures.

## Requirements

- Flutter 3.47+ and Dart 3.13+.
- Android builds use AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, and JDK 17+.
- An Android device/emulator supported by your Flutter SDK, or an iOS 15+
  device/simulator. Building iOS requires macOS and Xcode.
- A device and development computer that can reach each other over the network.
- Internet access for the GitHub SSL pinning demo.

Native iOS dependencies use **Swift Package Manager**. It is enabled in
[pubspec.yaml](pubspec.yaml); CocoaPods installation and `pod install` are no
longer part of setup. Open `ios/Runner.xcworkspace` when working in Xcode.

UI components come from `package:material_ui/material_ui.dart`. The
`uses-material-design: true` setting bundles the font used by `Icons`; it does
not select the SDK's Material widget library.

The Android project uses AGP's built-in Kotlin support
(`android.builtInKotlin=true`). It retains `android.newDsl=false` for Flutter's
Gradle integration. Dependency version checks remain enabled.

## Quick start

Run these commands from this `example/` directory unless stated otherwise.

### 1. Install dependencies and start the backend

```sh
flutter pub get
dart run tool/mock_backend.dart
```

Keep this terminal running. Open [the local dashboard](http://localhost:8787/)
on your computer. Reports are stored in memory and cleared when the backend
restarts.

### 2. Configure the device connection

Find your computer's LAN IPv4 address using `ifconfig` on macOS/Linux or
`ipconfig` on Windows. Update [lib/backend_host.dart](lib/backend_host.dart):

```dart
const String backendHost = '192.168.1.10'; // Replace with your computer's IP.
```

The host is an IP address only, without a scheme or port. The example connects
to port `8787`. Use a reachable LAN address for physical devices; `localhost`
on a device refers to that device. Allow incoming connections to the backend
through your development computer's firewall.

The identifiers in [lib/main.dart](lib/main.dart) are demonstration values.
Set `signingCertHashes`, `teamId`, and `bundleIds` to your application's actual
values when evaluating signing or repackaging detection. For a physical iOS
device, also configure the Runner signing team in Xcode.

### 3. Launch the app

In a second terminal, also from `example/`:

```sh
flutter devices
flutter run -d <device-id>
```

Replace `<device-id>` with an ID from `flutter devices`. Successful startup
adds `RASP initialized — monitoring active` to the app's monitor. Initialization
errors show a failure screen with the error and stack trace.

## Try the features

| Feature | Action | Expected result |
| --- | --- | --- |
| Threat detection | Tap **SCAN ALL** | Results appear in the in-app monitor. Detected threats depend on the device. |
| Reporting | Tap **Force Dart error**, then **Flush pending** | A manually captured exception appears in the backend dashboard when delivery succeeds. |
| Screen capture | Toggle screen capture protection | The platform applies its supported capture restrictions. |
| Local SSL pinning | Try the plain or encrypted certificate with `dart:io`, Dio, or http | The request is checked against the bundled certificate. |
| Remote SSL pinning | Tap **Download**, then **Use remote** | The certificate is downloaded from the local backend, stored, and used for a pinned request. |

The default policy is `ThreatPolicy.none`, so the demo reports threats without
terminating the app. Monitoring runs every five seconds. Automatic Flutter and
platform error capture remains disabled; the error button explicitly calls
`captureException`.

Pinned requests target `https://api.github.com/zen`. Green means TLS and the HTTP
request succeeded; amber means pinning succeeded but the HTTP response was not
successful (for example, a rate limit); red indicates a pinning or network error.
The certificate and passphrase are demonstration fixtures, not production
configuration.

The mock backend uses HTTP for local development. The Android cleartext-network
configuration belongs to this demo. Use HTTPS and your own certificates and
identifiers when adapting it for production.

## Release version

The example uses `7.2.0+1`: Android and iOS read the app version from
`pubspec.yaml`. The plugin and the bundled native core artifacts use `7.2.0`.
The native build script reads the release version from the plugin pubspec so
future AAR and XCFramework builds stay aligned.

## Project guide

| Location | Purpose |
| --- | --- |
| [lib/main.dart](lib/main.dart) | Initializes SSL pinning, RASP, and the reporter before rendering the app. |
| [lib/backend_host.dart](lib/backend_host.dart) | Configures the local backend host. |
| [lib/notifiers/](lib/notifiers/) | Holds feature state and coordinates plugin calls. |
| [lib/screens/](lib/screens/) | Builds the dashboard with `material_ui`. |
| [assets/certs/](assets/certs/) | Contains the plain and encrypted demo certificates. |
| [tool/mock_backend.dart](tool/mock_backend.dart) | Receives reports and serves the dashboard and certificate fixtures. |
| [integration_test/plugin_integration_test.dart](integration_test/plugin_integration_test.dart) | Checks native initialization and a threat scan on a device. |

The backend exposes `POST /v1/ingest`, `GET /reports`, `DELETE /reports`,
`GET /cert.enc`, and `GET /cert.pem`. Its `--port` option changes the listening
port; if you use it, also update the URLs in the app that currently use `8787`.

## Validate changes

Analyze the example and build for the iOS simulator:

```sh
flutter analyze
flutter build ios --simulator --debug
```

Run the native integration smoke test on an available device:

```sh
flutter test integration_test/plugin_integration_test.dart -d <device-id>
```

From the parent plugin directory, run the unit tests:

```sh
cd ..
flutter test
```

The smoke test verifies initialization and scan results; it does not exercise
every dashboard control, real-device threat, or report-delivery scenario.

## Troubleshooting

- **Flutter cannot find `flutter_rasp/android/app/build.gradle`:** the launch
  directory points to the plugin instead of this app. Run `flutter run` from
  `flutter_rasp/example/`. In VS Code, set the launch configuration `cwd` to
  that directory and `program` to its `lib/main.dart`.

- **Reports do not arrive:** confirm the backend is running, the LAN address is
  current, and the device can reach port `8787`. Then tap **Flush pending**.
- **Remote certificate download fails:** launch the backend from `example/`
  so its relative `assets/certs/` paths resolve.
- **Signing fails on a physical iOS device:** configure your development team
  and bundle identifier in Xcode, or use a simulator for build verification.
- **An old checkout still references Pods:** run `flutter clean`,
  `flutter pub get`, and rebuild. Confirm Swift Package Manager is enabled in
  `pubspec.yaml` and use the checked-in workspace configuration.

## References

- [Plugin API and configuration](../README.md)
- [Flutter's Swift Package Manager integration](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers)
- [Standalone Material UI migration](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui)
- [Flutter built-in Kotlin migration](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)
