import '../enums/ssl_pinning_mode.dart';

/// A single SSL pin: Base64-encoded SHA-256 hash paired with a [SslPinningMode].
class SslPin {
  final SslPinningMode mode;
  final String sha256Hash;

  const SslPin({required this.mode, required this.sha256Hash});

  const SslPin.certificate(this.sha256Hash) : mode = SslPinningMode.certificate;

  const SslPin.publicKey(this.sha256Hash) : mode = SslPinningMode.publicKey;
}
