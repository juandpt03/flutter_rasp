import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('ThreatPolicy', () {
    test('none has empty exitThreats', () {
      expect(ThreatPolicy.none.exitThreats, isEmpty);
    });

    test('low exits on repackaging and trustedInstall', () {
      expect(ThreatPolicy.low.exitThreats, {
        Threat.repackaging,
        Threat.trustedInstall,
      });
    });

    test('medium exits on core + obfuscation + multiInstance', () {
      expect(ThreatPolicy.medium.exitThreats, {
        Threat.root,
        Threat.hook,
        Threat.repackaging,
        Threat.trustedInstall,
        Threat.obfuscationIssues,
        Threat.multiInstance,
      });
    });

    test('high exits on most threats', () {
      expect(ThreatPolicy.high.exitThreats, {
        Threat.root,
        Threat.hook,
        Threat.repackaging,
        Threat.trustedInstall,
        Threat.debug,
        Threat.adbEnabled,
        Threat.devicePasscode,
        Threat.obfuscationIssues,
        Threat.multiInstance,
        Threat.secureHardwareNotAvailable,
        Threat.locationSpoofing,
        Threat.deviceBinding,
      });
    });

    test('presets never contain undefined', () {
      for (final policy in [
        ThreatPolicy.none,
        ThreatPolicy.low,
        ThreatPolicy.medium,
        ThreatPolicy.high,
      ]) {
        expect(policy.exitThreats, isNot(contains(Threat.undefined)));
      }
    });

    test('custom policy with specific threats', () {
      const policy = ThreatPolicy(exitThreats: {Threat.vpn, Threat.emulator});
      expect(policy.exitThreats, {Threat.vpn, Threat.emulator});
    });
  });
}
