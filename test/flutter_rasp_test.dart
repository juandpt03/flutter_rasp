import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_rasp/src/flutter_rasp_platform_interface.dart';
import 'package:flutter_rasp/src/flutter_rasp_pigeon.dart';

import 'helpers/mock_platform.dart';

void main() {
  test('PigeonFlutterRasp is the default instance', () {
    expect(
      FlutterRaspPlatform.instance,
      isInstanceOf<PigeonFlutterRasp>(),
    );
  });

  group('Initialization', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('starts monitoring with onThreatDetected', () async {
      await rasp.initialize(onThreatDetected: (_) {});

      expect(rasp.isInitialized, isTrue);
      expect(mockPlatform.monitoringStarted, isTrue);
    });

    test('starts monitoring with threatCallback only', () async {
      await rasp.initialize(threatCallback: const ThreatCallback());

      expect(rasp.isInitialized, isTrue);
    });

    test('throws without any callback', () async {
      expect(() => rasp.initialize(), throwsA(isA<RaspException>()));
    });

    test('throws when called twice', () async {
      await rasp.initialize(onThreatDetected: (_) {});

      expect(
        () => rasp.initialize(onThreatDetected: (_) {}),
        throwsA(isA<RaspException>()),
      );
    });
  });

  group('Threat stream', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('onThreatDetected receives threats', () async {
      final detected = <Set<Threat>>[];
      await rasp.initialize(onThreatDetected: detected.add);

      mockPlatform.controller.add(['root', 'emulator']);
      await Future.delayed(Duration.zero);

      expect(detected.length, 1);
      expect(detected.first, {Threat.root, Threat.emulator});
    });

    test('filters undefined threats and ignores empty sets', () async {
      final detected = <Set<Threat>>[];
      await rasp.initialize(onThreatDetected: detected.add);

      mockPlatform.controller.add(['root', 'nonexistent']);
      await Future.delayed(Duration.zero);
      expect(detected.first, {Threat.root});

      mockPlatform.controller.add(['nonexistent']);
      await Future.delayed(Duration.zero);
      expect(detected.length, 1, reason: 'empty set should not fire callback');
    });

    test('onThreatDetected and threatCallback work together', () async {
      var callbackRoot = false;
      final detected = <Set<Threat>>[];

      await rasp.initialize(
        onThreatDetected: detected.add,
        threatCallback: ThreatCallback(onRoot: () => callbackRoot = true),
      );

      mockPlatform.controller.add(['root']);
      await Future.delayed(Duration.zero);

      expect(detected.length, 1);
      expect(callbackRoot, isTrue);
    });

    test('stream error does not crash (handled gracefully)', () async {
      await rasp.initialize(onThreatDetected: (_) {});

      mockPlatform.controller.addError('simulated error');
      await Future.delayed(Duration.zero);

      // Should still be initialized — error is caught internally
      expect(rasp.isInitialized, isTrue);
    });

    test('stream done resets state', () async {
      await rasp.initialize(onThreatDetected: (_) {});

      await mockPlatform.controller.close();
      await Future.delayed(Duration.zero);

      expect(rasp.isInitialized, isFalse);
    });
  });

  group('Listener management', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('attachListener replaces callback', () async {
      var firstCalled = false;
      var secondCalled = false;

      await rasp.initialize(
        threatCallback: ThreatCallback(onRoot: () => firstCalled = true),
      );

      rasp.attachListener(ThreatCallback(onRoot: () => secondCalled = true));

      mockPlatform.controller.add(['root']);
      await Future.delayed(Duration.zero);

      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });

    test('detachListener stops callbacks', () async {
      var called = false;

      await rasp.initialize(
        threatCallback: ThreatCallback(onRoot: () => called = true),
      );

      rasp.detachListener();

      mockPlatform.controller.add(['root']);
      await Future.delayed(Duration.zero);

      expect(called, isFalse);
    });

    test('attachListener throws when not initialized', () {
      expect(
        () => rasp.attachListener(const ThreatCallback()),
        throwsA(isA<RaspException>()),
      );
    });
  });

  group('Scan & individual checks', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('scanAll returns correct result', () async {
      await rasp.initialize(onThreatDetected: (_) {});
      final result = await rasp.scanAll();

      expect(result.isCompromised, isTrue);
      expect(result.isEmulator, isTrue);
      expect(result.isDebugged, isTrue);
      expect(result.isRooted, isFalse);
    });

    test('scanAll throws when not initialized', () {
      expect(() => rasp.scanAll(), throwsA(isA<RaspException>()));
    });

    test('scanAll filters Threat.undefined', () async {
      await rasp.initialize(onThreatDetected: (_) {});
      final result = await rasp.scanAll(
        enabledThreats: {Threat.root, Threat.undefined},
      );
      expect(result.threats.containsKey(Threat.undefined), isFalse);
    });

    /// Data-driven test for all 15 individual check methods.
    for (final entry in _checkEntries) {
      test('${entry.methodName} delegates to platform', () async {
        mockPlatform.checkResults = {entry.threatName: entry.expected};
        await rasp.initialize(onThreatDetected: (_) {});

        final result = await entry.check(rasp);
        expect(result, entry.expected, reason: '${entry.methodName} failed');
      });
    }
  });

  group('Screen capture', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('blockScreenCapture delegates to platform', () async {
      await rasp.initialize(onThreatDetected: (_) {});

      await rasp.blockScreenCapture(true);
      expect(await rasp.isScreenCaptureBlocked(), isTrue);

      await rasp.blockScreenCapture(false);
      expect(await rasp.isScreenCaptureBlocked(), isFalse);
    });
  });

  group('Dispose', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    test('dispose stops monitoring', () async {
      await rasp.initialize(onThreatDetected: (_) {});
      await rasp.dispose();

      expect(rasp.isInitialized, isFalse);
      expect(mockPlatform.monitoringStopped, isTrue);
    });
  });
}

/// Maps each individual check method to its threat name and expected result.
class _CheckEntry {
  final String methodName;
  final String threatName;
  final bool expected;
  final Future<bool> Function(FlutterRasp) check;

  const _CheckEntry(this.methodName, this.threatName, this.expected, this.check);
}

final _checkEntries = [
  _CheckEntry('isRooted', 'root', true, (r) => r.isRooted()),
  _CheckEntry('isEmulator', 'emulator', true, (r) => r.isEmulator()),
  _CheckEntry('isDebugged', 'debug', true, (r) => r.isDebugged()),
  _CheckEntry('isHooked', 'hook', true, (r) => r.isHooked()),
  _CheckEntry('isRepackaged', 'repackaging', true, (r) => r.isRepackaged()),
  _CheckEntry(
    'isUntrustedInstall',
    'trustedInstall',
    true,
    (r) => r.isUntrustedInstall(),
  ),
  _CheckEntry('isVpnConnected', 'vpn', true, (r) => r.isVpnConnected()),
  _CheckEntry(
    'isDeveloperMode',
    'developerMode',
    true,
    (r) => r.isDeveloperMode(),
  ),
  _CheckEntry('isAdbEnabled', 'adbEnabled', true, (r) => r.isAdbEnabled()),
  _CheckEntry(
    'isDevicePasscodeDisabled',
    'devicePasscode',
    true,
    (r) => r.isDevicePasscodeDisabled(),
  ),
  _CheckEntry(
    'isSecureHardwareUnavailable',
    'secureHardwareNotAvailable',
    true,
    (r) => r.isSecureHardwareUnavailable(),
  ),
  _CheckEntry(
    'hasObfuscationIssues',
    'obfuscationIssues',
    true,
    (r) => r.hasObfuscationIssues(),
  ),
  _CheckEntry('isTimeSpoofed', 'timeSpoofing', true, (r) => r.isTimeSpoofed()),
  _CheckEntry(
    'isLocationSpoofed',
    'locationSpoofing',
    true,
    (r) => r.isLocationSpoofed(),
  ),
  _CheckEntry('isMultiInstance', 'multiInstance', true, (r) => r.isMultiInstance()),
];
