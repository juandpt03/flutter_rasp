import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/src/ssl_pinning/sha256.dart';

void main() {
  group('sha256', () {
    // NIST / RFC test vectors.
    test('empty string', () {
      final digest = sha256(Uint8List(0));
      expect(
        _hex(digest),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('"abc"', () {
      final digest = sha256(Uint8List.fromList(utf8.encode('abc')));
      expect(
        _hex(digest),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"', () {
      const input =
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
      final digest = sha256(Uint8List.fromList(utf8.encode(input)));
      expect(
        _hex(digest),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('returns 32-byte digest', () {
      final digest = sha256(Uint8List.fromList([0x42]));
      expect(digest.length, 32);
    });

    test('deterministic — same input always produces same output', () {
      final input = Uint8List.fromList(utf8.encode('hello world'));
      final a = sha256(input);
      final b = sha256(input);
      expect(a, b);
    });

    test('different inputs produce different digests', () {
      final a = sha256(Uint8List.fromList([0x00]));
      final b = sha256(Uint8List.fromList([0x01]));
      expect(a, isNot(equals(b)));
    });

    test('long input (> 64 bytes, multiple blocks)', () {
      // 1 million 'a' characters — well-known NIST vector.
      final input = Uint8List.fromList(List.filled(1000000, 0x61));
      final digest = sha256(input);
      expect(
        _hex(digest),
        'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
      );
    });
  });
}

String _hex(Uint8List bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
