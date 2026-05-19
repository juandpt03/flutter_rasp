import '../utils/hash_converter.dart';

/// Android-specific configuration for repackaging and install-origin detection.
class AndroidRaspConfig {
  /// Package names of the install sources trusted by default.
  ///
  /// Reference this list to extend the defaults with your own stores instead
  /// of accidentally replacing them:
  ///
  /// ```dart
  /// AndroidRaspConfig(
  ///   signingCertHashes: ['...'],
  ///   supportedStores: [
  ///     ...AndroidRaspConfig.defaultSupportedStores,
  ///     'com.your.custom.store',
  ///   ],
  /// );
  /// ```
  static const List<String> defaultSupportedStores = [
    'com.android.vending',
    'com.amazon.venezia',
    'com.huawei.appmarket',
    'com.sec.android.app.samsungapps',
    'dev.firebase.appdistribution',
    'com.vivo.appstore',
    'com.heytap.market',
    'com.oppo.market',
    'com.xiaomi.mipicks',
  ];

  /// SHA-256 fingerprint of the signing certificate, as shown in Google Play Console.
  ///
  /// Go to **Google Play Console** > your app > **App integrity** > **App signing**
  /// and copy the SHA-256 fingerprint (e.g. `'A1:2B:3C:4D:...'`).
  final List<String> signingCertHashes;

  /// Package names of allowed install sources.
  ///
  /// Defaults to [defaultSupportedStores]. Passing a value here **replaces**
  /// the defaults entirely — spread [defaultSupportedStores] to keep them.
  final List<String> supportedStores;

  const AndroidRaspConfig({
    required this.signingCertHashes,
    this.supportedStores = defaultSupportedStores,
  });

  Map<String, dynamic> toMap() => {
    'signingCertHashes':
        signingCertHashes.map(hashConverter.fromSha256toBase64).toList(),
    'supportedStores': supportedStores,
  };
}
