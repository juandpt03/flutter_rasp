import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/ssl_pinning_config.dart';

/// SSL certificate pinning via [SecurityContext] with `withTrustedRoots: false`.
///
/// Only the PEM certificates in [SslPinningConfig] are trusted.
/// Connections to servers with a different certificate chain fail
/// with a [HandshakeException].
class SslPinningClient {
  const SslPinningClient._();

  /// Returns a [SecurityContext] that only trusts the PEM certificates
  /// in [config]. Use it to build your own [HttpClient].
  static Future<SecurityContext> createContext(
    SslPinningConfig config, {
    AssetBundle? bundle,
  }) async {
    config.validate();

    final effectiveBundle = bundle ?? rootBundle;
    final context = SecurityContext(withTrustedRoots: false);

    for (final assetPath in config.certificateAssetPaths) {
      final pem = await effectiveBundle.loadString(assetPath);
      context.setTrustedCertificatesBytes(utf8.encode(pem));
    }

    return context;
  }

  /// Returns a ready-to-use [HttpClient] with SSL pinning configured.
  static Future<HttpClient> createHttpClient(
    SslPinningConfig config, {
    AssetBundle? bundle,
  }) async {
    final context = await createContext(config, bundle: bundle);
    return HttpClient(context: context);
  }
}
