import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

enum SslPinningStatus { idle, testing, success, failure }

class SslPinningNotifier extends ValueNotifier<SslPinningStatus> {
  SslPinningNotifier() : super(SslPinningStatus.idle);

  String? lastError;

  Future<void> testPinning() async {
    value = SslPinningStatus.testing;
    lastError = null;

    try {
      final config = SslPinningConfig(
        pins: {
          'jsonplaceholder.typicode.com': [
            SslPin.publicKey(_jsonPlaceholderPin),
          ],
        },
      );

      final client = SslPinningClient.create(
        config,
        onPinningFailure: (host, cert) {
          debugPrint('SSL Pinning failed for $host');
        },
      );

      final request = await client
          .getUrl(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'))
          .timeout(const Duration(seconds: 10));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && body.isNotEmpty) {
        value = SslPinningStatus.success;
      } else {
        lastError = 'HTTP ${response.statusCode}';
        value = SslPinningStatus.failure;
      }
    } catch (e) {
      lastError = e.toString();
      value = SslPinningStatus.failure;
    }
  }

  void reset() {
    lastError = null;
    value = SslPinningStatus.idle;
  }
}

/// Pre-computed public key pin for jsonplaceholder.typicode.com.
///
/// Generate the public key pin with:
/// ```bash
/// openssl s_client -connect jsonplaceholder.typicode.com:443 \
///   -servername jsonplaceholder.typicode.com 2>/dev/null \
///   | openssl x509 -pubkey -noout \
///   | openssl pkey -pubin -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
///
/// Generate the certificate pin with:
/// ```bash
/// openssl s_client -connect jsonplaceholder.typicode.com:443 \
///   -servername jsonplaceholder.typicode.com 2>/dev/null \
///   | openssl x509 -outform DER \
///   | openssl dgst -sha256 -binary \
///   | base64
/// ```
const _jsonPlaceholderPin = 'k+swi1D7Mu27FDJ9DAfns27/YipZz5s7BezuYsaXM/s=';
