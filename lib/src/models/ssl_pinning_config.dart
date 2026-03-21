import '../extensions/file_path_ext.dart';

/// Configuration for [SslPinningClient].
///
/// When [passphrase] is `null`, certificates are treated as plain PEM.
/// When [passphrase] is provided, certificates are treated as AES-256-GCM encrypted.
class SslPinningConfig {
  final List<String> certificateAssetPaths;

  /// When provided, certificates are decrypted using AES-256-GCM.
  final String? passphrase;

  const SslPinningConfig({
    required this.certificateAssetPaths,
    this.passphrase,
  });

  bool get isEncrypted => passphrase != null;

  void validate() {
    if (certificateAssetPaths.isEmpty) {
      throw ArgumentError('At least one certificate asset path is required.');
    }
    for (final path in certificateAssetPaths) {
      if (path.trim().isEmpty) {
        throw ArgumentError('Certificate asset path must not be empty.');
      }
    }
    if (passphrase != null && passphrase!.trim().isEmpty) {
      throw ArgumentError('Passphrase must not be empty when provided.');
    }

    for (final path in certificateAssetPaths) {
      if (isEncrypted && !path.isEncryptedCertificate) {
        throw ArgumentError(
          'Encrypted mode requires .enc files. Got: $path. '
          'Use the Certificate Encryptor tool to encrypt your .pem file.',
        );
      }
      if (!isEncrypted && !path.isPlainCertificate) {
        throw ArgumentError(
          'Plain mode requires .pem, .crt, or .cer files. Got: $path. '
          'For encrypted .enc files, provide a passphrase.',
        );
      }
    }
  }
}
