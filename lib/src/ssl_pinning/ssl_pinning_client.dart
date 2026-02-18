import 'dart:io';

import '../models/ssl_pinning_config.dart';
import 'pin_validator.dart';

/// Creates [HttpClient] instances with SSL certificate pinning.
///
/// Rejects connections whose certificate or public key doesn't match
/// the configured [SslPinningConfig].
///
/// Uses `withTrustedRoots: false` so that [HttpClient.badCertificateCallback]
/// is invoked for every TLS handshake, not only for untrusted certificates.
///
/// Compatible with `dart:io`, Dio (`onHttpClientCreate`), and `http` (`IOClient`).
class SslPinningClient {
  const SslPinningClient._();

  /// Creates an [HttpClient] that validates server certificates against [config].
  ///
  /// The certificate must match at least one pin for the target host.
  /// Connections to hosts without configured pins are rejected.
  static HttpClient create(
    SslPinningConfig config, {
    void Function(String host, X509Certificate certificate)? onPinningFailure,
  }) {
    config.validate();

    final context = SecurityContext(withTrustedRoots: false);
    final client = HttpClient(context: context);

    client.badCertificateCallback = (cert, host, port) {
      if (!config.isPinned(host)) return false;

      final isValid = PinValidator.validate(cert, host, config);

      if (!isValid) {
        try {
          onPinningFailure?.call(host, cert);
        } catch (_) {}
      }

      return isValid;
    };

    return client;
  }
}
