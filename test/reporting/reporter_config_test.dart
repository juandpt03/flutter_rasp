import 'dart:typed_data';

import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReporterConfig defaults', () {
    final config = ReporterConfig(
      endpoint: Uri.parse('https://example.com/v1/ingest'),
    );

    test('endpoint is required and preserved verbatim', () {
      expect(config.endpoint, Uri.parse('https://example.com/v1/ingest'));
    });

    test('headers default to empty', () {
      expect(config.headers, isEmpty);
    });

    test('hmac, pinning and userId default to null', () {
      expect(config.hmacKey, isNull);
      expect(config.pinnedCertPem, isNull);
      expect(config.userId, isNull);
    });

    test('exitTimeout default = 1500 ms', () {
      expect(config.exitTimeout, const Duration(milliseconds: 1500));
    });

    test('httpTimeout default = 1200 ms', () {
      expect(config.httpTimeout, const Duration(milliseconds: 1200));
    });

    test('breadcrumb + queue caps default to 50', () {
      expect(config.maxBreadcrumbs, 50);
      expect(config.maxPendingReports, 50);
    });

    test('retry backoffs default to 3s / 9s / 27s', () {
      expect(config.retryBackoffs, const <Duration>[
        Duration(seconds: 3),
        Duration(seconds: 9),
        Duration(seconds: 27),
      ]);
    });

    test(
      'error capture switches default to false; threat switches to true',
      () {
        expect(config.captureFlutterErrors, isFalse);
        expect(config.capturePlatformErrors, isFalse);
        expect(config.captureExitThreats, isTrue);
        expect(config.captureDetectedThreats, isTrue);
      },
    );
  });

  group('ReporterConfig overrides', () {
    test('every field is honored when explicitly set', () {
      final pem = Uint8List.fromList([0xCA, 0xFE]);
      final config = ReporterConfig(
        endpoint: Uri.parse('https://api.example/ingest'),
        headers: const {'X-Project-Id': 'demo'},
        hmacKey: 'secret',
        pinnedCertPem: pem,
        exitTimeout: const Duration(milliseconds: 500),
        httpTimeout: const Duration(milliseconds: 300),
        maxBreadcrumbs: 10,
        maxPendingReports: 5,
        retryBackoffs: const <Duration>[Duration(seconds: 1)],
        captureFlutterErrors: false,
        capturePlatformErrors: false,
        captureExitThreats: false,
        captureDetectedThreats: false,
        userId: 'user-42',
      );

      expect(config.headers, {'X-Project-Id': 'demo'});
      expect(config.hmacKey, 'secret');
      expect(config.pinnedCertPem, pem);
      expect(config.exitTimeout, const Duration(milliseconds: 500));
      expect(config.httpTimeout, const Duration(milliseconds: 300));
      expect(config.maxBreadcrumbs, 10);
      expect(config.maxPendingReports, 5);
      expect(config.retryBackoffs, [const Duration(seconds: 1)]);
      expect(config.captureFlutterErrors, isFalse);
      expect(config.capturePlatformErrors, isFalse);
      expect(config.captureExitThreats, isFalse);
      expect(config.captureDetectedThreats, isFalse);
      expect(config.userId, 'user-42');
    });
  });
}
