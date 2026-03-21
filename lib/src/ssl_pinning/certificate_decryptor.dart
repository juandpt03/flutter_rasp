import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../errors/rasp_exception.dart';

/// Decrypts PEM certificates encrypted with the RASP Certificate Encryptor.
class CertificateDecryptor {
  const CertificateDecryptor._();

  static const _magic = [0x52, 0x41, 0x53, 0x50];
  static const _currentVersion = 1;
  static const _saltLen = 32;
  static const _ivLen = 12;
  static const _tagBits = 128;
  static const _tagLen = _tagBits ~/ 8;
  static const _keyLen = 32;
  static const _headerSize = 4 + 1 + 4 + _saltLen + _ivLen;

  static Uint8List decrypt(Uint8List data, String passphrase) {
    _validateHeader(data);

    final iterations = _readUint32BE(data, 5);
    final salt = Uint8List.sublistView(data, 9, 9 + _saltLen);
    final iv = Uint8List.sublistView(
      data,
      _headerSize - _ivLen,
      _headerSize,
    );
    final ciphertextWithTag = Uint8List.sublistView(data, _headerSize);

    final key = _deriveKey(passphrase, salt, iterations);

    try {
      return _decryptAesGcm(ciphertextWithTag, key, iv);
    } on InvalidCipherTextException {
      throw RaspException.invalidEncryptedCertificate();
    }
  }

  static Uint8List _deriveKey(
    String passphrase,
    Uint8List salt,
    int iterations,
  ) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, _keyLen));
    return derivator.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  static Uint8List _decryptAesGcm(
    Uint8List ciphertextWithTag,
    Uint8List key,
    Uint8List iv,
  ) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      false,
      AEADParameters(KeyParameter(key), _tagBits, iv, Uint8List(0)),
    );
    return cipher.process(ciphertextWithTag);
  }

  static void _validateHeader(Uint8List data) {
    if (data.length < _headerSize + _tagLen) {
      throw RaspException.invalidEncryptedCertificate(
        'File too small (${data.length} bytes, minimum ${_headerSize + _tagLen}).',
      );
    }
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) {
        throw RaspException.invalidEncryptedCertificate(
          'Missing RASP header. '
          'Ensure the file was encrypted with the Certificate Encryptor tool.',
        );
      }
    }
    if (data[4] != _currentVersion) {
      throw RaspException.invalidEncryptedCertificate(
        'Unsupported format version: ${data[4]} (expected: $_currentVersion).',
      );
    }
  }

  static int _readUint32BE(Uint8List data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }
}
