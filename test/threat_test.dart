import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('Threat', () {
    test('has 17 values (16 active + undefined)', () {
      expect(Threat.values.length, 17);
    });

    test('active excludes undefined', () {
      expect(Threat.active, isNot(contains(Threat.undefined)));
      expect(Threat.active.length, 16);
    });

    test('active contains all threats', () {
      expect(Threat.active, containsAll([
        Threat.root,
        Threat.emulator,
        Threat.debug,
        Threat.hook,
        Threat.repackaging,
        Threat.trustedInstall,
        Threat.vpn,
        Threat.developerMode,
        Threat.adbEnabled,
        Threat.devicePasscode,
        Threat.secureHardwareNotAvailable,
        Threat.obfuscationIssues,
        Threat.timeSpoofing,
        Threat.locationSpoofing,
        Threat.multiInstance,
        Threat.deviceBinding,
      ]));
    });

    test('fromName resolves known threats', () {
      for (final threat in Threat.active) {
        expect(Threat.fromName(threat.name), threat);
      }
    });

    test('fromName returns undefined for unknown names', () {
      expect(Threat.fromName('nonexistent'), Threat.undefined);
      expect(Threat.fromName(''), Threat.undefined);
    });

    test('active set is unmodifiable', () {
      expect(() => Threat.active.add(Threat.undefined), throwsUnsupportedError);
    });
  });
}
