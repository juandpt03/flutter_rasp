import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('Threat', () {
    test('has 15 values (14 active + undefined)', () {
      expect(Threat.values.length, 15);
    });

    test('active excludes undefined', () {
      expect(Threat.active, isNot(contains(Threat.undefined)));
      expect(Threat.active.length, 14);
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
        Threat.devicePasscode,
        Threat.secureHardwareNotAvailable,
        Threat.obfuscationIssues,
        Threat.timeSpoofing,
        Threat.locationSpoofing,
        Threat.multiInstance,
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
