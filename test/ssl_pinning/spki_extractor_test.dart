import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/src/ssl_pinning/spki_extractor.dart';

void main() {
  group('SpkiExtractor', () {
    test('extracts SPKI from a real DER-encoded certificate', () {
      final derBytes = base64.decode(_testCertBase64);
      final spki = SpkiExtractor.extract(derBytes);

      expect(spki, isNotNull);
      // SPKI must start with SEQUENCE tag (0x30).
      expect(spki![0], 0x30);
      // RSA 2048 SPKI is typically 294 bytes.
      expect(spki.length, greaterThan(200));
    });

    test('returns null for empty input', () {
      expect(SpkiExtractor.extract(Uint8List(0)), isNull);
    });

    test('returns null for garbage data', () {
      expect(SpkiExtractor.extract(Uint8List.fromList([0xFF, 0xFF])), isNull);
    });

    test('returns null for truncated certificate', () {
      final derBytes = base64.decode(_testCertBase64);
      final truncated = Uint8List.sublistView(derBytes, 0, 50);
      expect(SpkiExtractor.extract(truncated), isNull);
    });

    test('returns null when outer tag is not SEQUENCE', () {
      final bad = Uint8List.fromList([0x02, 0x01, 0x00]);
      expect(SpkiExtractor.extract(bad), isNull);
    });

    test('extracted SPKI is a valid sublist of original DER', () {
      final derBytes = base64.decode(_testCertBase64);
      final spki = SpkiExtractor.extract(derBytes);

      expect(spki, isNotNull);
      final spkiHex = _hex(spki!);
      final derHex = _hex(derBytes);
      expect(derHex.contains(spkiHex), isTrue);
    });
  });
}

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// A real self-signed RSA 2048 X.509 v3 certificate in DER format (Base64).
/// Subject: CN=test.example.com
/// Generated with openssl for testing purposes only.
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
