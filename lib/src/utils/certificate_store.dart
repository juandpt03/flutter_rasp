import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely stores certificate bytes using platform Keychain / EncryptedSharedPreferences.
class CertificateStore {
  const CertificateStore._();

  static const _prefix = 'flutter_rasp_cert_';
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  @visibleForTesting
  static set storage(FlutterSecureStorage value) => _storage = value;

  @visibleForTesting
  static void resetStorage() => _storage = const FlutterSecureStorage();

  static Future<bool> save(Uint8List bytes, {required String key}) async {
    final existing = await load(key: key);
    if (existing != null && listEquals(existing, bytes)) return false;

    await _storage.write(
      key: '$_prefix$key',
      value: base64Encode(bytes),
    );
    return true;
  }

  static Future<Uint8List?> load({required String key}) async {
    try {
      final stored = await _storage.read(key: '$_prefix$key');
      if (stored == null) return null;
      return base64Decode(stored);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear({required String key}) async {
    await _storage.delete(key: '$_prefix$key');
  }
}
