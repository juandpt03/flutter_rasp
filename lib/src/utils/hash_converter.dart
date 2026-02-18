import 'dart:convert';

const hashConverter = HashConverter._();

/// Utility for converting SHA-256 hashes between hex and Base64 formats.
///
/// Use this to prepare signing certificate hashes for [AndroidRaspConfig]:
///
/// ```dart
/// final base64Hash = hashConverter.fromSha256toBase64(
///   'A1:B2:C3:...',
/// );
/// ```
class HashConverter {
  const HashConverter._();

  /// Converts a SHA-256 hex string to Base64.
  String fromSha256toBase64(String value) {
    final cleaned = value.replaceAll(':', '');
    if (!isValidSha256Format(cleaned)) {
      throw const FormatException('Value is not a valid SHA-256 hex string.');
    }
    return base64.encode(_hexDecode(cleaned));
  }

  String fromBase64toSha256(String value) {
    final bytes = base64.decode(value);
    if (bytes.length != 32) {
      throw const FormatException('Decoded value is not 32 bytes (SHA-256).');
    }
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
    return hex;
  }

  bool isValidSha256Format(String value) {
    return RegExp(r'^[A-Fa-f0-9]{64}$').hasMatch(value);
  }

  bool isValidBase64Sha256(String value) {
    try {
      final bytes = base64.decode(value);
      return bytes.length == 32;
    } catch (_) {
      return false;
    }
  }

  List<int> _hexDecode(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
