import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('PinValidator', () {
    late _FakeX509Certificate fakeCert;

    setUp(() {
      fakeCert = _FakeX509Certificate(base64.decode(_testCertBase64));
    });

    test('returns true when host has no pins (not pinned)', () {
      const config = SslPinningConfig(pins: {});
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });

    test('certificate mode — matching pin', () {
      final hash = base64.encode(sha256(fakeCert.der));
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.certificate(hash)],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });

    test('certificate mode — wrong pin', () {
      const config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.certificate('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=')],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isFalse);
    });

    test('publicKey mode — matching pin', () {
      final spki = SpkiExtractor.extract(fakeCert.der)!;
      final hash = base64.encode(sha256(spki));
      final config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey(hash)],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });

    test('publicKey mode — wrong pin', () {
      const config = SslPinningConfig(pins: {
        'api.example.com': [SslPin.publicKey('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=')],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isFalse);
    });

    test('any pin match succeeds (backup pin support)', () {
      final certHash = base64.encode(sha256(fakeCert.der));
      final config = SslPinningConfig(pins: {
        'api.example.com': [
          const SslPin.certificate('WRONG_HASH_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='),
          SslPin.certificate(certHash), // backup pin
        ],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });

    test('mixed modes — certificate and publicKey pins', () {
      final spki = SpkiExtractor.extract(fakeCert.der)!;
      final spkiHash = base64.encode(sha256(spki));
      final config = SslPinningConfig(pins: {
        'api.example.com': [
          const SslPin.certificate('WRONG_HASH_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='),
          SslPin.publicKey(spkiHash), // this one matches
        ],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });

    test('different host returns true (not pinned for that host)', () {
      const config = SslPinningConfig(pins: {
        'other.example.com': [SslPin.certificate('anything')],
      });
      final result = PinValidator.validate(fakeCert, 'api.example.com', config);
      expect(result, isTrue);
    });
  });
}

/// Minimal [X509Certificate] fake for unit testing.
class _FakeX509Certificate implements X509Certificate {
  final Uint8List _derBytes;

  _FakeX509Certificate(this._derBytes);

  @override
  Uint8List get der => _derBytes;

  @override
  String get pem => throw UnimplementedError();

  @override
  Uint8List get sha1 => throw UnimplementedError();

  @override
  DateTime get endValidity => throw UnimplementedError();

  @override
  String get issuer => throw UnimplementedError();

  @override
  DateTime get startValidity => throw UnimplementedError();

  @override
  String get subject => throw UnimplementedError();
}

/// Same real self-signed RSA 2048 test certificate used in
/// spki_extractor_test.dart.
const _testCertBase64 =
    'MIIDFzCCAf+gAwIBAgIUKmLpoEaqpSLylAI2GYKE6ttPSg0wDQYJKoZIhvcNAQEL'
    'BQAwGzEZMBcGA1UEAwwQdGVzdC5leGFtcGxlLmNvbTAeFw0yNjAyMTcwNzA3MjZa'
    'Fw0zNjAyMTUwNzA3MjZaMBsxGTAXBgNVBAMMEHRlc3QuZXhhbXBsZS5jb20wggEi'
    'MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC6553bjiuimBxJedmneJQvysiA1O'
    'nsFHP+ktFBW+Z7l2jVsiChtHm+M8uwQLEaDh6fk1tp68C1uFPJt1Oy7nd3fr/xp2k'
    'CPESl8EyeBQf2z1GEydAq/hD+sZTfFITD02OHym5T/zepGvtgbTgMKy2O3BZHjsw'
    '9wPpqv8hfZCedr1HpY5+rOUiMbfdtazUyNUi/8cUhIlUJ2iPBcuHT3WcsDz9GbMH'
    'q9ddEQ02kp7kRyxtJPkPRTSlxdSaKv+PNjBZO3KlAtrOs5xUeeZXKkXK1KgvGct0'
    'YUPk2nM+00sOnaVNqRWqsLfGbPSIeQkg5YhjhQyhj89vK9WP41XzWRn7PAgMBAAGj'
    'UzBRMB0GA1UdDgQWBBRKi7aehj58CHALgGdXRM2sQQIN3jAfBgNVHSMEGDAWgBRK'
    'i7aehj58CHALgGdXRM2sQQIN3jAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCw'
    'UAA4IBAQAu+6iTmKIAMU9DzBtIJqPQTL14U5/28fsmGHiGMRGxfAZ70ZumFvyj+m'
    'E/FsFR6SmXUThSOdg/o0YID8KGGct7H5tzaNZ3uyfNoU0yiXtuKuvKRXCfuMykXGNY'
    'ckX7nRZWzelSTpYFPLx5vJzTaKD6721h3z665ivpXVzRhccz24yB2fCxRHwjbGwmkU'
    '7b/s7+3ftkh+OgM2OCAGVfvnn6RPWPLCuj546z4/gBNv5tvcINMsJP5tbHquIpqHXn'
    'VZa7ltTUzNIEeOjnPCb5QGQ0khRBNXg7enWwXow6ovDqYKcy/94NMJWR2fjhmXHPh'
    '2nuD7ydOwezlT92mBv8EWHf';
