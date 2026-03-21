import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../errors/rasp_exception.dart';
import '../models/ssl_pinning_config.dart';
import '../utils/certificate_store.dart';
import 'certificate_decryptor.dart';

/// Creates [SecurityContext] and [HttpClient] with pinned certificates.
///
/// When [onFetchRemote] is provided:
/// 1. Memory cache → instant
/// 2. Stored cert (secure storage) → use + background fetch
/// 3. No stored cert → await fetch → store → use
/// 4. Everything fails → asset fallback
///
/// Supports both encrypted (.enc + passphrase) and plain PEM (.pem) modes.
class SslPinningClient {
  const SslPinningClient._();

  static final _cache = <String, SecurityContext>{};

  static Future<SecurityContext> createContext(
    SslPinningConfig config, {
    AssetBundle? bundle,
    Future<Uint8List?> Function()? onFetchRemote,
  }) async {
    config.validate();

    final key = _storageKey(config);

    if (_cache.containsKey(key)) return _cache[key]!;

    if (onFetchRemote != null) {
      final stored = await CertificateStore.load(key: key);

      if (stored != null) {
        try {
          final ctx = _buildContext(stored, config.passphrase);
          _cache[key] = ctx;
          unawaited(
            _backgroundUpdate(onFetchRemote, key, config.passphrase),
          );
          return ctx;
        } on RaspException catch (_) {
        } on TlsException catch (_) {}
      }

      try {
        final bytes = await onFetchRemote();
        if (bytes != null) {
          final ctx = _buildContext(bytes, config.passphrase);
          await CertificateStore.save(bytes, key: key);
          _cache[key] = ctx;
          return ctx;
        }
      } on RaspException catch (_) {
      } on TlsException catch (_) {
      } on IOException catch (_) {}
    }

    try {
      final ctx = await _fromAssets(config, bundle);
      _cache[key] = ctx;
      return ctx;
    } catch (e) {
      if (onFetchRemote != null) {
        throw RaspException.noCertificateAvailable('$e');
      }
      rethrow;
    }
  }

  static Future<HttpClient> createHttpClient(
    SslPinningConfig config, {
    AssetBundle? bundle,
    Future<Uint8List?> Function()? onFetchRemote,
  }) async {
    final context = await createContext(
      config,
      bundle: bundle,
      onFetchRemote: onFetchRemote,
    );
    return HttpClient(context: context);
  }

  static Future<void> clearStoredCertificate(SslPinningConfig config) async {
    final key = _storageKey(config);
    await CertificateStore.clear(key: key);
    _cache.remove(key);
  }

  static void invalidateCache() => _cache.clear();

  // -- Internal --

  static SecurityContext _buildContext(Uint8List bytes, String? passphrase) {
    final Uint8List pemBytes;
    if (passphrase != null) {
      pemBytes = CertificateDecryptor.decrypt(bytes, passphrase);
    } else {
      validatePem(bytes);
      pemBytes = bytes;
    }
    final ctx = SecurityContext(withTrustedRoots: false);
    ctx.setTrustedCertificatesBytes(pemBytes);
    return ctx;
  }

  static void validatePem(Uint8List bytes) {
    final String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      throw RaspException.invalidCertificateFormat(
        'Invalid PEM certificate: not valid UTF-8. '
        'If this is an encrypted certificate, provide a passphrase.',
      );
    }
    if (!content.contains('-----BEGIN CERTIFICATE-----') ||
        !content.contains('-----END CERTIFICATE-----')) {
      throw RaspException.invalidCertificateFormat();
    }
  }

  static Future<SecurityContext> _fromAssets(
    SslPinningConfig config,
    AssetBundle? bundle,
  ) async {
    final effectiveBundle = bundle ?? rootBundle;
    final ctx = SecurityContext(withTrustedRoots: false);

    for (final assetPath in config.certificateAssetPaths) {
      final Uint8List pemBytes;

      if (config.passphrase != null) {
        final byteData = await effectiveBundle.load(assetPath);
        final encrypted = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        pemBytes = CertificateDecryptor.decrypt(encrypted, config.passphrase!);
      } else {
        final pem = await effectiveBundle.loadString(assetPath);
        final pemAsBytes = Uint8List.fromList(utf8.encode(pem));
        validatePem(pemAsBytes);
        pemBytes = pemAsBytes;
      }

      ctx.setTrustedCertificatesBytes(pemBytes);
    }

    return ctx;
  }

  static Future<void> _backgroundUpdate(
    Future<Uint8List?> Function() onFetch,
    String key,
    String? passphrase,
  ) async {
    try {
      final bytes = await onFetch();
      if (bytes == null) return;
      if (passphrase != null) {
        CertificateDecryptor.decrypt(bytes, passphrase);
      } else {
        validatePem(bytes);
      }
      final updated = await CertificateStore.save(bytes, key: key);
      if (updated) _cache.remove(key);
    } catch (_) {}
  }

  static String _storageKey(SslPinningConfig config) {
    return config.certificateAssetPaths
        .join('|')
        .hashCode
        .toUnsigned(32)
        .toRadixString(16)
        .padLeft(8, '0');
  }
}
