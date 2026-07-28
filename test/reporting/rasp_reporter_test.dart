import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
// ignore: implementation_imports
import 'package:flutter_rasp/src/flutter_rasp_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_platform.dart';

void main() {
  late MockFlutterRaspPlatform mockPlatform;
  late RaspReporter reporter;

  setUp(() async {
    // Dispose any leftover reporter state from a previous test so
    // FlutterError.onError is restored before we swap in a fresh mock.
    await RaspReporter.instance.dispose();

    mockPlatform = MockFlutterRaspPlatform();
    FlutterRaspPlatform.instance = mockPlatform;
    reporter = RaspReporter.instance;
    await reporter.resetForTesting();
  });

  tearDown(() async {
    await RaspReporter.instance.dispose();
  });

  // Error capture is opt-in (off by default), so enable it explicitly
  // here — these tests exercise the installed-handler behavior.
  ReporterConfig configFor() => ReporterConfig(
    endpoint: Uri.parse('https://example.com/v1/ingest'),
    headers: const {'X-Project-Id': 'test'},
    captureFlutterErrors: true,
    capturePlatformErrors: true,
  );

  group('initialize', () {
    test('forwards config across the bridge', () async {
      final cfg = configFor();
      await reporter.initialize(cfg);

      expect(reporter.isInitialized, isTrue);
      expect(reporter.config, cfg);
      expect(mockPlatform.initReporterCalls, 1);
      expect(mockPlatform.lastReporterConfig, cfg);
    });

    test('throws when called twice without dispose', () async {
      await reporter.initialize(configFor());

      expect(
        () => reporter.initialize(configFor()),
        throwsA(
          isA<RaspException>().having(
            (e) => e.errorCode,
            'errorCode',
            RaspErrorCode.raspReporterAlreadyInitialized,
          ),
        ),
      );
      expect(mockPlatform.initReporterCalls, 1);
    });

    test(
      'captureFlutterErrors:false leaves FlutterError.onError untouched',
      () async {
        final original = FlutterError.onError;
        addTearDown(() => FlutterError.onError = original);

        await reporter.initialize(
          ReporterConfig(
            endpoint: Uri.parse('https://example.com'),
            captureFlutterErrors: false,
          ),
        );

        expect(identical(FlutterError.onError, original), isTrue);
      },
    );

    test('captureFlutterErrors:true installs a chained handler', () async {
      final original = FlutterError.onError;
      addTearDown(() => FlutterError.onError = original);

      await reporter.initialize(configFor());

      expect(identical(FlutterError.onError, original), isFalse);
      expect(FlutterError.onError, isNotNull);
    });
  });

  group('dispose', () {
    test('tears native down and restores handlers', () async {
      final original = FlutterError.onError;
      addTearDown(() => FlutterError.onError = original);

      await reporter.initialize(configFor());
      await reporter.dispose();

      expect(reporter.isInitialized, isFalse);
      expect(mockPlatform.disposeReporterCalls, 1);
      expect(identical(FlutterError.onError, original), isTrue);
    });

    test('is a no-op when not initialized', () async {
      await reporter.dispose();
      expect(mockPlatform.disposeReporterCalls, 0);
    });
  });

  group('addBreadcrumb', () {
    test('forwards every field and encodes data as JSON', () async {
      await reporter.initialize(configFor());

      await reporter.addBreadcrumb(
        message: 'user tapped login',
        category: 'ui',
        level: BreadcrumbLevel.warning,
        data: const {'screen': 'home', 'attempt': 2},
      );

      expect(mockPlatform.breadcrumbs, hasLength(1));
      final b = mockPlatform.breadcrumbs.single;
      expect(b['message'], 'user tapped login');
      expect(b['category'], 'ui');
      expect(b['level'], 'warning');
      expect(b['timestampMs'], isA<int>());
      expect(jsonDecode(b['dataJson']! as String), {
        'screen': 'home',
        'attempt': 2,
      });
    });

    test('skips the dataJson serialization when data is empty', () async {
      await reporter.initialize(configFor());
      await reporter.addBreadcrumb(message: 'no data');

      expect(mockPlatform.breadcrumbs.single['dataJson'], '');
    });

    test('is a no-op before initialize()', () async {
      await reporter.addBreadcrumb(message: 'ignored');
      expect(mockPlatform.breadcrumbs, isEmpty);
    });
  });

  group('captureException', () {
    test('ships type=manual with message + stack', () async {
      await reporter.initialize(configFor());

      final stack = StackTrace.current;
      await reporter.captureException(StateError('boom'), stackTrace: stack);

      expect(mockPlatform.capturedErrors, hasLength(1));
      final e = mockPlatform.capturedErrors.single;
      expect(e['event'], 'manualCapture');
      expect(e['message'], contains('Bad state: boom'));
      expect(e['stackTrace'], stack.toString());
    });

    test('prefers `hint` over the exception toString', () async {
      await reporter.initialize(configFor());
      await reporter.captureException(
        Exception('low-level'),
        hint: 'user pressed Force error',
      );

      expect(
        mockPlatform.capturedErrors.single['message'],
        'user pressed Force error',
      );
    });

    test('is a no-op before initialize()', () async {
      await reporter.captureException(Exception('x'));
      expect(mockPlatform.capturedErrors, isEmpty);
    });
  });

  group('setUserId / flushPending', () {
    test('setUserId reaches the platform', () async {
      await reporter.initialize(configFor());
      await reporter.setUserId('u-1');
      expect(mockPlatform.lastUserId, 'u-1');
    });

    test('setUserId is a no-op before initialize()', () async {
      await reporter.setUserId('u-1');
      expect(mockPlatform.lastUserId, isNull);
    });

    test('flushPending reaches the platform', () async {
      await reporter.initialize(configFor());
      await reporter.flushPending();
      expect(mockPlatform.flushCalls, 1);
    });

    test('flushPending is a no-op before initialize()', () async {
      await reporter.flushPending();
      expect(mockPlatform.flushCalls, 0);
    });
  });

  group('Dart-side error capture', () {
    test('hooked FlutterError.onError ships a flutterError report', () async {
      final original = FlutterError.onError;
      addTearDown(() => FlutterError.onError = original);

      await reporter.initialize(configFor());

      FlutterError.onError!(
        FlutterErrorDetails(
          exception: StateError('flutter-fail'),
          library: 'rendering',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(mockPlatform.capturedErrors, hasLength(1));
      final e = mockPlatform.capturedErrors.single;
      expect(e['event'], 'flutterError');
      expect(e['library'], 'rendering');
      expect(e['message'], contains('flutter-fail'));
    });
  });
}
