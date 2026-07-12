import '../extensions/file_path_ext.dart';

/// Configuration for downloading a pinned certificate from a remote
/// endpoint.
///
/// The certificate format depends on the file and [passphrase]: plain PEM
/// when [passphrase] is `null`, encrypted (`.enc`) when provided.
class RemoteCertificateConfig {
  /// Endpoint that serves the certificate.
  final Uri url;

  /// Extra HTTP headers sent with the download request.
  final Map<String, String> headers;

  /// Timeout applied to the download request.
  final Duration timeout;

  /// Required when the endpoint serves an encrypted certificate.
  final String? passphrase;

  const RemoteCertificateConfig({
    required this.url,
    this.headers = const {},
    this.timeout = const Duration(seconds: 10),
    this.passphrase,
  });

  bool get isEncrypted => passphrase != null;

  void validate() {
    if (url.scheme != 'https' && url.scheme != 'http') {
      throw ArgumentError(
        'Certificate endpoint must use http or https. Got: $url',
      );
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError('Timeout must be greater than zero.');
    }
    if (passphrase != null && passphrase!.trim().isEmpty) {
      throw ArgumentError('Passphrase must not be empty when provided.');
    }

    // Endpoints without a file extension are accepted as-is; the
    // downloaded bytes are validated according to [passphrase].
    if (isEncrypted && url.path.isPlainCertificate) {
      throw ArgumentError(
        'Encrypted mode requires an .enc endpoint. Got: $url. '
        'Remove the passphrase for plain certificates.',
      );
    }
    if (!isEncrypted && url.path.isEncryptedCertificate) {
      throw ArgumentError(
        'Endpoint serves an encrypted certificate: $url. '
        'Provide a passphrase.',
      );
    }
  }
}
