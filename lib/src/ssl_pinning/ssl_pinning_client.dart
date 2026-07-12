import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../errors/rasp_exception.dart';
import '../models/remote_certificate_config.dart';
import '../models/ssl_pinning_config.dart';
import '../utils/certificate_store.dart';
import 'certificate_decryptor.dart';

/// Creates [SecurityContext] and [HttpClient] with pinned certificates.
///
/// - **Local** (recommended): [createContext] / [createHttpClient] load
///   bundled certificates, plain or encrypted.
/// - **Remote**: [downloadCertificate] fetches the certificate from your
///   endpoint and always replaces the stored copy; then
///   [createRemoteContext] / [createRemoteHttpClient] build pinned
///   clients synchronously from it.
class SslPinningClient {
  const SslPinningClient._();

  static final _cache = <String, SecurityContext>{};
  static final _pemCache = <String, Uint8List>{};

  /// Certificates are a few KB; anything larger than this is not one.
  static const _maxDownloadBytes = 1024 * 1024;

  /// Override for the download request in tests.
  @visibleForTesting
  static Future<Uint8List> Function(RemoteCertificateConfig config)?
  debugFetchOverride;

  // ─── Local certificate ───

  /// Builds a [SecurityContext] pinned to the local certificates in
  /// [config], plain PEM or encrypted `.enc` (with `passphrase`).
  ///
  /// The context is cached in memory; repeated calls with the same
  /// [config] are instant.
  static Future<SecurityContext> createContext(
    SslPinningConfig config, {
    AssetBundle? bundle,
  }) async {
    config.validate();

    final key = _localKey(config);
    final cached = _cache[key];
    if (cached != null) return cached;

    final ctx = await _fromAssets(config, bundle, key);
    _cache[key] = ctx;
    return ctx;
  }

  /// [createContext] wrapped in an [HttpClient].
  static Future<HttpClient> createHttpClient(
    SslPinningConfig config, {
    AssetBundle? bundle,
  }) async {
    final context = await createContext(config, bundle: bundle);
    return HttpClient(context: context);
  }

  // ─── Remote certificate ───

  /// Downloads the certificate from [RemoteCertificateConfig.url],
  /// validates it (plain or encrypted, per `passphrase`), and **always
  /// replaces** the stored copy.
  ///
  /// Returns `true` on a fresh download, `false` when the download
  /// failed but a copy from a previous session was restored. Throws
  /// [RaspException.certificateDownloadFailed] when neither is available.
  static Future<bool> downloadCertificate(
    RemoteCertificateConfig config,
  ) async {
    config.validate();
    final key = _remoteKey(config);

    Object? downloadError;
    try {
      final bytes = await (debugFetchOverride ?? _fetch)(config);
      // Cache before persisting so a storage failure never reverts the
      // session to an older certificate.
      _cache[key] = await _buildContext(bytes, config.passphrase, key);
      await CertificateStore.save(bytes, key: key);
      return true;
    } catch (e) {
      downloadError = e;
    }

    if (_cache.containsKey(key)) return false;

    final stored = await CertificateStore.load(key: key);
    if (stored != null) {
      try {
        _cache[key] = await _buildContext(stored, config.passphrase, key);
        return false;
      } on RaspException catch (_) {
      } on TlsException catch (_) {}
    }

    throw RaspException.certificateDownloadFailed(
      'Certificate download from ${config.url} failed and no stored '
      'certificate is available. Cause: $downloadError',
    );
  }

  /// Synchronously builds a [SecurityContext] pinned to the certificate
  /// previously obtained with [downloadCertificate].
  ///
  /// Throws [RaspException.noCertificateAvailable] if
  /// [downloadCertificate] hasn't succeeded in this session.
  static SecurityContext createRemoteContext(RemoteCertificateConfig config) {
    config.validate();
    final ctx = _cache[_remoteKey(config)];
    if (ctx == null) {
      throw RaspException.noCertificateAvailable(
        'No downloaded certificate for ${config.url}. '
        'Call downloadCertificate() first.',
      );
    }
    return ctx;
  }

  /// [createRemoteContext] wrapped in an [HttpClient].
  static HttpClient createRemoteHttpClient(RemoteCertificateConfig config) {
    return HttpClient(context: createRemoteContext(config));
  }

  /// Removes the stored remote certificate for [config] and evicts it
  /// from the memory cache.
  static Future<void> clearRemoteCertificate(
    RemoteCertificateConfig config,
  ) async {
    final key = _remoteKey(config);
    await CertificateStore.clear(key: key);
    _cache.remove(key);
    _pemCache.remove(key);
  }

  // ─── Shared utilities ───

  /// Clears every in-memory context and PEM. Stored remote certificates
  /// are kept; use [clearRemoteCertificate] to delete them.
  static void invalidateCache() {
    _cache.clear();
    _pemCache.clear();
  }

  /// Resolved PEM bytes for a local [config], or `null` if it hasn't been
  /// initialized yet. Forward to the reporter's `pinnedCertPem` to
  /// reuse the same cert without a second load.
  static Uint8List? cachedPem(SslPinningConfig config) =>
      _pemCache[_localKey(config)];

  /// Resolved PEM bytes for a remote [config], or `null` if
  /// [downloadCertificate] hasn't succeeded yet.
  static Uint8List? cachedRemotePem(RemoteCertificateConfig config) =>
      _pemCache[_remoteKey(config)];

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

  // ─── Internals ───

  static Future<Uint8List> _fetch(RemoteCertificateConfig config) async {
    final client = HttpClient()..connectionTimeout = config.timeout;
    try {
      final request = await client
          .getUrl(config.url)
          .timeout(config.timeout);
      config.headers.forEach(request.headers.set);
      final response = await request.close().timeout(config.timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw RaspException.certificateDownloadFailed(
          'HTTP ${response.statusCode} from ${config.url}',
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(config.timeout)) {
        builder.add(chunk);
        if (builder.length > _maxDownloadBytes) {
          throw RaspException.certificateDownloadFailed(
            'Response from ${config.url} exceeds $_maxDownloadBytes bytes; '
            'not a certificate.',
          );
        }
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  static Future<SecurityContext> _buildContext(
    Uint8List bytes,
    String? passphrase,
    String key,
  ) async {
    final Uint8List pemBytes;
    if (passphrase != null) {
      // PBKDF2 takes seconds on low-end devices; keep it off the UI isolate.
      pemBytes = await Isolate.run(
        () => CertificateDecryptor.decrypt(bytes, passphrase),
      );
    } else {
      validatePem(bytes);
      pemBytes = bytes;
    }
    final ctx = SecurityContext(withTrustedRoots: false);
    ctx.setTrustedCertificatesBytes(pemBytes);
    _pemCache[key] = pemBytes;
    return ctx;
  }

  static Future<SecurityContext> _fromAssets(
    SslPinningConfig config,
    AssetBundle? bundle,
    String key,
  ) async {
    final effectiveBundle = bundle ?? rootBundle;
    final ctx = SecurityContext(withTrustedRoots: false);
    final builder = BytesBuilder(copy: false);

    for (final assetPath in config.certificateAssetPaths) {
      final Uint8List pemBytes;

      final passphrase = config.passphrase;
      if (passphrase != null) {
        final byteData = await effectiveBundle.load(assetPath);
        final encrypted = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        pemBytes = await Isolate.run(
          () => CertificateDecryptor.decrypt(encrypted, passphrase),
        );
      } else {
        final pem = await effectiveBundle.loadString(assetPath);
        final pemAsBytes = Uint8List.fromList(utf8.encode(pem));
        validatePem(pemAsBytes);
        pemBytes = pemAsBytes;
      }

      ctx.setTrustedCertificatesBytes(pemBytes);
      builder.add(pemBytes);
    }

    _pemCache[key] = builder.takeBytes();
    return ctx;
  }

  static String _localKey(SslPinningConfig config) =>
      _hashKey(config.certificateAssetPaths.join('|'));

  static String _remoteKey(RemoteCertificateConfig config) =>
      _hashKey('remote|${config.url}');

  static String _hashKey(String source) {
    return source.hashCode
        .toUnsigned(32)
        .toRadixString(16)
        .padLeft(8, '0');
  }
}
