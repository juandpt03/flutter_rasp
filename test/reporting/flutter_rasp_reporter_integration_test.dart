import 'package:flutter_rasp/flutter_rasp.dart';
// ignore: implementation_imports
import 'package:flutter_rasp/src/flutter_rasp_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_platform.dart';

class _FailingPlatform extends MockFlutterRaspPlatform {
  @override
  Future<void> startMonitoring(RaspConfig config) async {
    throw RaspException.unknown(message: 'simulated native failure');
  }
}

void main() {
  group('FlutterRasp.initialize(reporter:)', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() async {
      await RaspReporter.instance.dispose();
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
      await RaspReporter.instance.resetForTesting();
    });

    tearDown(() async {
      await RaspReporter.instance.dispose();
    });

    test('boots the reporter when a config is provided', () async {
      final cfg = ReporterConfig(
        endpoint: Uri.parse('https://example.com'),
      );

      await rasp.initialize(
        onThreatDetected: (_) {},
        reporter: cfg,
      );

      expect(RaspReporter.instance.isInitialized, isTrue);
      expect(mockPlatform.initReporterCalls, 1);
      expect(mockPlatform.lastReporterConfig, cfg);
    });

    test('leaves the reporter alone when no config is provided', () async {
      await rasp.initialize(onThreatDetected: (_) {});
      expect(RaspReporter.instance.isInitialized, isFalse);
      expect(mockPlatform.initReporterCalls, 0);
    });

    test('rolls the reporter back if RASP setup fails', () async {
      // Swap to a platform that throws on startMonitoring.
      FlutterRaspPlatform.instance = _FailingPlatform();
      rasp = freshRasp();

      await expectLater(
        rasp.initialize(
          onThreatDetected: (_) {},
          reporter: ReporterConfig(endpoint: Uri.parse('https://x')),
        ),
        throwsA(isA<RaspException>()),
      );

      expect(RaspReporter.instance.isInitialized, isFalse);
      expect(rasp.isInitialized, isFalse);
    });
  });
}
