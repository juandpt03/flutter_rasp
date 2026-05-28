# flutter_rasp · example

End-to-end demo of `flutter_rasp` 6.0.0 — RASP monitoring, SSL
pinning, and the security reporter shipping to a tiny local backend
bundled in this same package.

## Run it

### 1. Start the local backend

```bash
dart run tool/mock_backend.dart
```

Dashboard at `http://localhost:8787/`.

### 2. Set your machine's LAN IP

Find it with `ifconfig` (macOS/Linux) or `ipconfig` (Windows). Open
`lib/main.dart` and replace the placeholder:

```dart
const String _backendHost = '192.168.x.x';   // ← your IP here
```

> Using the LAN IP (not `localhost` or `10.0.2.2`) means the same
> value works for the Android emulator, the iOS simulator and
> physical devices — as long as they share the network with the
> machine running the backend.

### 3. Run the app

```bash
flutter run
```

Tap **Force Dart error**, **Flush pending** or **Scan all** — every
action lands on the dashboard within a second.

## Notes

- The `network_security_config.xml` in this example exists only
  because the mock backend speaks plain HTTP. The plugin itself
  assumes HTTPS for real backends — **your production app does not
  need to add or modify any network-security config** for the
  reporter to work.
- The mock backend has no dependencies (`dart:io` / `dart:convert`)
  and dumps every report to stdout, including the
  `X-Rasp-Signature` HMAC header when signing is enabled.
