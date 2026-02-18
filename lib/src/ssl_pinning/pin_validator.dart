import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../enums/ssl_pinning_mode.dart';
import '../models/ssl_pin.dart';
import '../models/ssl_pinning_config.dart';
import 'sha256.dart';
import 'spki_extractor.dart';

/// Validates an [X509Certificate] against the pins configured for a host.
class PinValidator {
  const PinValidator._();

  static bool validate(
    X509Certificate cert,
    String host,
    SslPinningConfig config,
  ) {
    final pins = config.pinsForHost(host);
    if (pins.isEmpty) return true;

    final derBytes = cert.der;

    for (final pin in pins) {
      switch (pin.mode) {
        case SslPinningMode.certificate:
          if (_matchesCertificate(derBytes, pin)) return true;
        case SslPinningMode.publicKey:
          if (_matchesPublicKey(derBytes, pin)) return true;
      }
    }

    return false;
  }

  static bool _matchesCertificate(Uint8List derBytes, SslPin pin) {
    final digest = sha256(derBytes);
    return base64.encode(digest) == pin.sha256Hash;
  }

  static bool _matchesPublicKey(Uint8List derBytes, SslPin pin) {
    final spkiBytes = SpkiExtractor.extract(derBytes);
    if (spkiBytes == null) return false;
    final digest = sha256(spkiBytes);
    return base64.encode(digest) == pin.sha256Hash;
  }
}
