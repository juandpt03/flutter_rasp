import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('HashConverter', () {
    test('SHA-256 to Base64 roundtrip', () {
      const sha =
          'AE:4F:12:31:E0:AF:E1:35:E9:BC:0A:F5:21:AF:9B:C6:'
          '7E:09:76:B1:B4:D6:4E:79:90:DB:AC:30:82:E4:6E:69';
      final base64 = hashConverter.fromSha256toBase64(sha);
      expect(base64.isNotEmpty, isTrue);
      expect(hashConverter.fromBase64toSha256(base64), sha);
    });

    test('SHA-256 without colons roundtrip', () {
      const sha =
          'AE4F1231E0AFE135E9BC0AF521AF9BC67E0976B1B4D64E7990DBAC3082E46E69';
      final base64 = hashConverter.fromSha256toBase64(sha);
      final back = hashConverter.fromBase64toSha256(base64);
      // fromBase64toSha256 always returns with colons
      expect(back.replaceAll(':', ''), sha);
    });

    group('isValidSha256Format', () {
      test('accepts 64 hex chars', () {
        expect(hashConverter.isValidSha256Format('a' * 64), isTrue);
        expect(hashConverter.isValidSha256Format('A' * 64), isTrue);
        expect(
          hashConverter.isValidSha256Format('0123456789abcdef' * 4),
          isTrue,
        );
      });

      test('rejects wrong length', () {
        expect(hashConverter.isValidSha256Format('a' * 63), isFalse);
        expect(hashConverter.isValidSha256Format('a' * 65), isFalse);
        expect(hashConverter.isValidSha256Format(''), isFalse);
      });

      test('rejects non-hex characters', () {
        expect(hashConverter.isValidSha256Format('g' * 64), isFalse);
        expect(hashConverter.isValidSha256Format('z' * 64), isFalse);
      });
    });

    group('isValidBase64Sha256', () {
      test('accepts valid Base64 encoding of 32 bytes', () {
        final validB64 = hashConverter.fromSha256toBase64('ab' * 32);
        expect(hashConverter.isValidBase64Sha256(validB64), isTrue);
      });

      test('rejects short Base64', () {
        expect(hashConverter.isValidBase64Sha256('short'), isFalse);
      });

      test('rejects invalid Base64', () {
        expect(hashConverter.isValidBase64Sha256('!!!'), isFalse);
      });

      test('rejects Base64 of wrong byte length', () {
        // "YQ==" decodes to 1 byte, not 32
        expect(hashConverter.isValidBase64Sha256('YQ=='), isFalse);
      });
    });

    group('error handling', () {
      test('fromSha256toBase64 throws on invalid input', () {
        expect(
          () => hashConverter.fromSha256toBase64('not-a-hash'),
          throwsA(isA<FormatException>()),
        );
      });

      test('fromBase64toSha256 throws on wrong byte length', () {
        expect(
          () => hashConverter.fromBase64toSha256('YQ=='),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
