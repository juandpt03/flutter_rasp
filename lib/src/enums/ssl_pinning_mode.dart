/// Pinning strategy for SSL certificate validation.
enum SslPinningMode {
  /// SHA-256 of the full DER-encoded certificate.
  certificate,

  /// SHA-256 of the SubjectPublicKeyInfo (SPKI).
  ///
  /// Recommended: survives certificate renewals if the key pair is reused.
  publicKey,
}
