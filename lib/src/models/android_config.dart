/// Android-specific configuration for repackaging and install-origin detection.
class AndroidRaspConfig {
  /// Base64-encoded SHA-256 hashes of the expected signing certificates.
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
    'signingCertHashes': signingCertHashes,
    'supportedStores': supportedStores,
  };
}
