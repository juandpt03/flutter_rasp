/// Configuration for [SslPinningClient].
///
/// Provide asset paths to `.pem` certificate files.
class SslPinningConfig {
  /// Asset paths pointing to `.pem` certificate files.
  final List<String> certificateAssetPaths;

  const SslPinningConfig({required this.certificateAssetPaths});

  /// Throws [ArgumentError] if [certificateAssetPaths] is empty
  /// or contains blank entries.
  void validate() {
    if (certificateAssetPaths.isEmpty) {
      throw ArgumentError('At least one certificate asset path is required.');
    }
    for (final path in certificateAssetPaths) {
      if (path.trim().isEmpty) {
        throw ArgumentError('Certificate asset path must not be empty.');
      }
    }
  }
}
