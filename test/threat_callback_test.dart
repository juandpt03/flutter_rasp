import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_rasp/src/flutter_rasp_platform_interface.dart';

import 'helpers/mock_platform.dart';

void main() {
  group('ThreatCallback dispatch', () {
    late MockFlutterRaspPlatform mockPlatform;
    late FlutterRasp rasp;

    setUp(() {
      mockPlatform = MockFlutterRaspPlatform();
      FlutterRaspPlatform.instance = mockPlatform;
      rasp = freshRasp();
    });

    /// Tests that each of the 15 ThreatCallback fields dispatches correctly.
    for (final entry in _callbackEntries) {
      test('dispatches ${entry.threatName}', () async {
        var called = false;

        await rasp.initialize(
          threatCallback: entry.buildCallback(() => called = true),
        );

        mockPlatform.controller.add([entry.threatName]);
        await Future.delayed(Duration.zero);

        expect(called, isTrue, reason: '${entry.threatName} was not dispatched');
      });
    }

    test('does not dispatch unregistered callbacks', () async {
      var hookCalled = false;

      await rasp.initialize(
        threatCallback: ThreatCallback(onHook: () => hookCalled = true),
      );

      mockPlatform.controller.add(['root']);
      await Future.delayed(Duration.zero);

      expect(hookCalled, isFalse);
    });

    test('dispatches all 15 threats at once', () async {
      final called = <String>{};

      await rasp.initialize(
        threatCallback: ThreatCallback(
          onRoot: () => called.add('root'),
          onEmulator: () => called.add('emulator'),
          onDebug: () => called.add('debug'),
          onHook: () => called.add('hook'),
          onRepackaging: () => called.add('repackaging'),
          onTrustedInstall: () => called.add('trustedInstall'),
          onVpn: () => called.add('vpn'),
          onDeveloperMode: () => called.add('developerMode'),
          onAdbEnabled: () => called.add('adbEnabled'),
          onDevicePasscode: () => called.add('devicePasscode'),
          onSecureHardwareNotAvailable: () => called.add('secureHardwareNotAvailable'),
          onObfuscationIssues: () => called.add('obfuscationIssues'),
          onTimeSpoofing: () => called.add('timeSpoofing'),
          onLocationSpoofing: () => called.add('locationSpoofing'),
          onMultiInstance: () => called.add('multiInstance'),
        ),
      );

      mockPlatform.controller.add(Threat.active.map((t) => t.name).toList());
      await Future.delayed(Duration.zero);

      expect(called.length, 15);
    });
  });
}

/// Each entry maps a threat name to the ThreatCallback field it should trigger.
class _CallbackEntry {
  final String threatName;
  final ThreatCallback Function(void Function() onCall) buildCallback;

  const _CallbackEntry(this.threatName, this.buildCallback);
}

final _callbackEntries = [
  _CallbackEntry('root', (cb) => ThreatCallback(onRoot: cb)),
  _CallbackEntry('emulator', (cb) => ThreatCallback(onEmulator: cb)),
  _CallbackEntry('debug', (cb) => ThreatCallback(onDebug: cb)),
  _CallbackEntry('hook', (cb) => ThreatCallback(onHook: cb)),
  _CallbackEntry('repackaging', (cb) => ThreatCallback(onRepackaging: cb)),
  _CallbackEntry('trustedInstall', (cb) => ThreatCallback(onTrustedInstall: cb)),
  _CallbackEntry('vpn', (cb) => ThreatCallback(onVpn: cb)),
  _CallbackEntry('developerMode', (cb) => ThreatCallback(onDeveloperMode: cb)),
  _CallbackEntry('adbEnabled', (cb) => ThreatCallback(onAdbEnabled: cb)),
  _CallbackEntry('devicePasscode', (cb) => ThreatCallback(onDevicePasscode: cb)),
  _CallbackEntry('secureHardwareNotAvailable', (cb) => ThreatCallback(onSecureHardwareNotAvailable: cb)),
  _CallbackEntry('obfuscationIssues', (cb) => ThreatCallback(onObfuscationIssues: cb)),
  _CallbackEntry('timeSpoofing', (cb) => ThreatCallback(onTimeSpoofing: cb)),
  _CallbackEntry('locationSpoofing', (cb) => ThreatCallback(onLocationSpoofing: cb)),
  _CallbackEntry('multiInstance', (cb) => ThreatCallback(onMultiInstance: cb)),
];
