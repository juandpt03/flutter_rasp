import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('SslPinningConfig', () {
    /// A valid Base64-encoded SHA-256 hash (32 bytes).
    final validHash = base64.encode(Uint8List(32));

    test('validate() succeeds with valid config', () {
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with multiple hosts and pins', () {
      final config = SslPinningConfig(pins: {
        'api.example.com': [
          SslPin.publicKey(validHash),
          SslPin.certificate(validHash),
        ],
        'cdn.example.com': [SslPin.publicKey(validHash)],
      });
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with empty pins map', () {
      const config = SslPinningConfig(pins: {});
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() throws on empty pin list for a host', () {
      const config = SslPinningConfig(pins: {
        'api.example.com': [],
      });
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on invalid Base64 hash', () {
      const config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey('not-valid-base64!!!')],
      });
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on Base64 of wrong byte length', () {
      // 16 bytes instead of 32.
      final shortHash = base64.encode(Uint8List(16));
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey(shortHash)],
      });
      expect(() => config.validate(), throwsArgumentError);
    });

    test('pinsForHost returns empty list for unknown host', () {
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(config.pinsForHost('other.com'), isEmpty);
    });

    test('pinsForHost returns pins for known host', () {
      final pin = SslPin.publicKey(validHash);
      final config = SslPinningConfig(pins: {
        'api.example.com': [pin],
      });
      expect(config.pinsForHost('api.example.com'), [pin]);
    });

    test('isPinned returns true for configured host', () {
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(config.isPinned('api.example.com'), isTrue);
      expect(config.isPinned('other.com'), isFalse);
    });
  });

  group('SslPinningConfig.immutable', () {
    final validHash = base64.encode(Uint8List(32));

    test('creates a config with correct pins', () {
      final config = SslPinningConfig.immutable(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(config.pinsForHost('api.example.com'), hasLength(1));
      expect(config.isPinned('api.example.com'), isTrue);
    });

    test('outer map is unmodifiable', () {
      final config = SslPinningConfig.immutable(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(
        () => config.pins['evil.com'] = [SslPin.publicKey(validHash)],
        throwsUnsupportedError,
      );
      expect(
        () => config.pins.clear(),
        throwsUnsupportedError,
      );
    });

    test('inner pin lists are unmodifiable', () {
      final config = SslPinningConfig.immutable(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(
        () => config.pins['api.example.com']!.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => config.pins['api.example.com']!.add(
          SslPin.publicKey(validHash),
        ),
        throwsUnsupportedError,
      );
    });

    test('mutations to original map do not affect config', () {
      final originalPins = <String, List<SslPin>>{
        'api.example.com': [SslPin.publicKey(validHash)],
      };
      final config = SslPinningConfig.immutable(pins: originalPins);
      originalPins['evil.com'] = [SslPin.publicKey(validHash)];
      expect(config.isPinned('evil.com'), isFalse);
    });

    test('validate() works on immutable config', () {
      final config = SslPinningConfig.immutable(pins: {
        'api.example.com': [SslPin.publicKey(validHash)],
      });
      expect(() => config.validate(), returnsNormally);
    });
  });
}
