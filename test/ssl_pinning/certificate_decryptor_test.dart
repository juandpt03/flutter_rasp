import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:pointycastle/export.dart';

/// Self-signed EC test certificate (valid 10 years).
const _testPem =
    '-----BEGIN CERTIFICATE-----\n'
    'MIIBizCCATGgAwIBAgIUV/NpLEzef0cEYN2As8oKdXoIcn0wCgYIKoZIzj0EAwIw\n'
    'GzEZMBcGA1UEAwwQdGVzdC5leGFtcGxlLmNvbTAeFw0yNjAyMTkwNDUyMTFaFw0z\n'
    'NjAyMTcwNDUyMTFaMBsxGTAXBgNVBAMMEHRlc3QuZXhhbXBsZS5jb20wWTATBgcq\n'
    'hkjOPQIBBggqhkjOPQMBBwNCAAQT8ZkJLGvyymRNo3tcGDwXYK7rD4ML10KMspNm\n'
    's2mdRcLPAoH07+YKThVBOhCoeLQzfclv9bDNQdpHhxWE9rIHo1MwUTAdBgNVHQ4E\n'
    'FgQU40lSXn5FsNdsGdcFIxBA0gQeCJMwHwYDVR0jBBgwFoAU40lSXn5FsNdsGdcF\n'
    'IxBA0gQeCJMwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiBbUSrZ\n'
    'WSkFH0rvuNg07+0YpxUiFMVSPUU6J3pYzTPnUgIhAI1CKpVEzFWxDonaskKSYuFm\n'
    'm3Vc6EX0lhszLLtSebz8\n'
    '-----END CERTIFICATE-----';

const _passphrase = 'test_passphrase_2024';

/// Low iterations for fast tests.
const _testIterations = 1000;

/// Encrypts a PEM string using the same algorithm as the CLI tool.
/// Used only in tests to create valid encrypted fixtures.
Uint8List _encryptForTest(
  String pem,
  String passphrase, {
  int iterations = _testIterations,
}) {
  final random = Random.secure();
  final salt = Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
  final iv = Uint8List.fromList(List.generate(12, (_) => random.nextInt(256)));

  // PBKDF2 key derivation
  final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
  derivator.init(Pbkdf2Parameters(salt, iterations, 32));
  final key = derivator.process(Uint8List.fromList(utf8.encode(passphrase)));

  // AES-256-GCM encryption
  final cipher = GCMBlockCipher(AESEngine());
  cipher.init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
  final ciphertextWithTag = cipher.process(
    Uint8List.fromList(utf8.encode(pem)),
  );

  // Build RASP file format
  final buffer = BytesBuilder(copy: false);
  buffer.add([0x52, 0x41, 0x53, 0x50]); // magic: "RASP"
  buffer.addByte(1); // version
  buffer.add([
    (iterations >> 24) & 0xFF,
    (iterations >> 16) & 0xFF,
    (iterations >> 8) & 0xFF,
    iterations & 0xFF,
  ]);
  buffer.add(salt);
  buffer.add(iv);
  buffer.add(ciphertextWithTag);
  return buffer.toBytes();
}

void main() {
  group('CertificateDecryptor', () {
    test('decrypts a valid encrypted certificate', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      final decrypted = CertificateDecryptor.decrypt(encrypted, _passphrase);
      expect(utf8.decode(decrypted), equals(_testPem));
    });

    test('decrypted bytes match original UTF-8 encoding', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      final decrypted = CertificateDecryptor.decrypt(encrypted, _passphrase);
      expect(decrypted, equals(Uint8List.fromList(utf8.encode(_testPem))));
    });

    test('throws ArgumentError on wrong passphrase', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      expect(
        () => CertificateDecryptor.decrypt(encrypted, 'wrong_passphrase'),
        throwsA(isA<RaspException>()),
      );
    });

    test('throws FormatException on data too small', () {
      expect(
        () => CertificateDecryptor.decrypt(Uint8List(10), _passphrase),
        throwsA(isA<RaspException>()),
      );
    });

    test('throws FormatException on missing RASP header', () {
      final bad = Uint8List(100);
      bad[0] = 0xFF; // wrong magic
      expect(
        () => CertificateDecryptor.decrypt(bad, _passphrase),
        throwsA(isA<RaspException>()),
      );
    });

    test('throws FormatException on unsupported version', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      encrypted[4] = 99; // unsupported version
      expect(
        () => CertificateDecryptor.decrypt(encrypted, _passphrase),
        throwsA(isA<RaspException>()),
      );
    });

    test('throws ArgumentError on corrupted ciphertext', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      // Corrupt a byte in the ciphertext region
      encrypted[60] ^= 0xFF;
      expect(
        () => CertificateDecryptor.decrypt(encrypted, _passphrase),
        throwsA(isA<RaspException>()),
      );
    });

    test('throws ArgumentError on corrupted GCM tag', () {
      final encrypted = _encryptForTest(_testPem, _passphrase);
      // Corrupt the last byte (part of GCM tag)
      encrypted[encrypted.length - 1] ^= 0xFF;
      expect(
        () => CertificateDecryptor.decrypt(encrypted, _passphrase),
        throwsA(isA<RaspException>()),
      );
    });

    test('works with different iteration counts', () {
      for (final iterations in [1000, 5000, 10000]) {
        final encrypted = _encryptForTest(
          _testPem,
          _passphrase,
          iterations: iterations,
        );
        final decrypted = CertificateDecryptor.decrypt(encrypted, _passphrase);
        expect(utf8.decode(decrypted), equals(_testPem));
      }
    });

    test('works with short PEM content', () {
      const shortPem =
          '-----BEGIN CERTIFICATE-----\nABC\n'
          '-----END CERTIFICATE-----';
      final encrypted = _encryptForTest(shortPem, _passphrase);
      final decrypted = CertificateDecryptor.decrypt(encrypted, _passphrase);
      expect(utf8.decode(decrypted), equals(shortPem));
    });

    test('works with empty passphrase', () {
      final encrypted = _encryptForTest(_testPem, '');
      final decrypted = CertificateDecryptor.decrypt(encrypted, '');
      expect(utf8.decode(decrypted), equals(_testPem));
    });
  });
}
