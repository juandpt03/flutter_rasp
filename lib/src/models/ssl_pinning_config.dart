import 'dart:collection';

import '../utils/hash_converter.dart';
import 'ssl_pin.dart';

/// Maps hostnames to their expected [SslPin] values.
///
/// Each host can have multiple pins for key rotation.
class SslPinningConfig {
  final Map<String, List<SslPin>> pins;

  const SslPinningConfig({required this.pins});

  /// Creates an unmodifiable [SslPinningConfig] from a runtime-built map.
  factory SslPinningConfig.immutable({
    required Map<String, List<SslPin>> pins,
  }) {
    return SslPinningConfig(
      pins: UnmodifiableMapView({
        for (final entry in pins.entries)
          entry.key: List<SslPin>.unmodifiable(entry.value),
      }),
    );
  }

  List<SslPin> pinsForHost(String host) => pins[host] ?? const [];

  bool isPinned(String host) => pins.containsKey(host);

  /// Throws [ArgumentError] on empty pin lists or invalid hashes.
  void validate() {
    for (final entry in pins.entries) {
      if (entry.value.isEmpty) {
        throw ArgumentError('Host "${entry.key}" has an empty pin list.');
      }
      for (final pin in entry.value) {
        if (!hashConverter.isValidBase64Sha256(pin.sha256Hash)) {
          throw ArgumentError(
            'Invalid Base64 SHA-256 hash for host "${entry.key}": '
            '${pin.sha256Hash}',
          );
        }
      }
    }
  }
}
