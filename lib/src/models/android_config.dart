import '../utils/hash_converter.dart';

/// Android-specific configuration for repackaging and install-origin detection.
class AndroidRaspConfig {
  /// SHA-256 fingerprint of the signing certificate, as shown in Google Play Console.
  ///
  /// Go to **Google Play Console** > your app > **App integrity** > **App signing**
  /// and copy the SHA-256 fingerprint (e.g. `'A1:2B:3C:4D:...'`).
  final List<String> signingCertHashes;

  /// Package names of allowed install sources.
  final List<String> supportedStores;

  const AndroidRaspConfig({
    required this.signingCertHashes,
    this.supportedStores = const [
      'com.android.vending',
      'com.amazon.venezia',
      'com.huawei.appmarket',
      'com.sec.android.app.samsungapps',
    ],
  });

  Map<String, dynamic> toMap() => {
    'signingCertHashes':
        signingCertHashes.map(hashConverter.fromSha256toBase64).toList(),
    'supportedStores': supportedStores,
  };
}
