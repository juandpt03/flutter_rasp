# flutter_rasp · example

End-to-end demo of `flutter_rasp` — RASP monitoring, SSL pinning
(local, encrypted, and remote download), and the security reporter
shipping to a tiny local backend bundled in this same package.

## Run it

### 1. Start the local backend

```bash
dart run tool/mock_backend.dart
```

Dashboard at `http://localhost:8787/`.

### 2. Set your machine's LAN IP

Find it with `ifconfig` (macOS/Linux) or `ipconfig` (Windows). Open
`lib/backend_host.dart` and replace the placeholder:

```dart
const String backendHost = '192.168.x.x';   // ← your IP here
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

The **SSL PINNING** card has three explicit groups:

- **LOCAL · PLAIN .PEM** — pins with the bundled plain certificate
  (`dart:io` / `Dio` / `http`).
- **LOCAL · ENCRYPTED .ENC** — same three clients, but the bundled
  certificate is encrypted and decrypted with a passphrase.
- **REMOTE** — **1. Download** fetches the certificate from the mock
  backend (`GET /cert.enc`, always replacing the stored copy), then
  **2. Use remote** builds the pinned client synchronously from it.

The pinned request goes to `https://api.github.com/zen`. The bundled
certificate is GitHub's **root CA** (USERTrust ECC, valid to 2038),
not the leaf — leaf certificates rotate every ~90 days and would
break the pin; the root doesn't.

Result colors: green = pinned TLS handshake + HTTP 2xx; amber =
pin worked but the server returned an error status (e.g. 403 if the
unauthenticated GitHub rate limit of 60 req/h is exceeded); red =
real failure (`Pin mismatch` for certificate problems, network
issues labeled as such).

## Notes

- The `network_security_config.xml` in this example exists only
  because the mock backend speaks plain HTTP. The plugin itself
  assumes HTTPS for real backends — **your production app does not
  need to add or modify any network-security config** for the
  reporter to work.
- The mock backend has no dependencies (`dart:io` / `dart:convert`)
  and dumps every report to stdout, including the
  `X-Rasp-Signature` HMAC header when signing is enabled.
