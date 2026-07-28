import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('RaspResult', () {
    test('fromMap filters undefined threats', () {
      final result = RaspResult.fromMap({'root': true, 'nonexistent': true});
      expect(result.threats.containsKey(Threat.undefined), isFalse);
      expect(result.isRooted, isTrue);
    });

    test('isCompromised true when any threat detected', () {
      final result = RaspResult.fromMap({'emulator': true});
      expect(result.isCompromised, isTrue);
    });

    test('isCompromised false when all clean', () {
      final result = RaspResult.fromMap({'root': false, 'emulator': false});
      expect(result.isCompromised, isFalse);
    });

    test('detectedThreats returns only active threats', () {
      final result = RaspResult.fromMap({
        'root': true,
        'emulator': false,
        'hook': true,
      });
      expect(result.detectedThreats, {Threat.root, Threat.hook});
    });

    group('getters for all 16 threats', () {
      final allTrue = RaspResult.fromMap({
        for (final t in Threat.active) t.name: true,
      });
      final allFalse = RaspResult.fromMap({
        for (final t in Threat.active) t.name: false,
      });

      test('isRooted', () {
        expect(allTrue.isRooted, isTrue);
        expect(allFalse.isRooted, isFalse);
      });

      test('isEmulator', () {
        expect(allTrue.isEmulator, isTrue);
        expect(allFalse.isEmulator, isFalse);
      });

      test('isDebugged', () {
        expect(allTrue.isDebugged, isTrue);
        expect(allFalse.isDebugged, isFalse);
      });

      test('isHooked', () {
        expect(allTrue.isHooked, isTrue);
        expect(allFalse.isHooked, isFalse);
      });

      test('isRepackaged', () {
        expect(allTrue.isRepackaged, isTrue);
        expect(allFalse.isRepackaged, isFalse);
      });

      test('isUntrustedInstall', () {
        expect(allTrue.isUntrustedInstall, isTrue);
        expect(allFalse.isUntrustedInstall, isFalse);
      });

      test('isVpnConnected', () {
        expect(allTrue.isVpnConnected, isTrue);
        expect(allFalse.isVpnConnected, isFalse);
      });

      test('isDeveloperMode', () {
        expect(allTrue.isDeveloperMode, isTrue);
        expect(allFalse.isDeveloperMode, isFalse);
      });

      test('isAdbEnabled', () {
        expect(allTrue.isAdbEnabled, isTrue);
        expect(allFalse.isAdbEnabled, isFalse);
      });

      test('isDevicePasscodeDisabled', () {
        expect(allTrue.isDevicePasscodeDisabled, isTrue);
        expect(allFalse.isDevicePasscodeDisabled, isFalse);
      });

      test('isSecureHardwareUnavailable', () {
        expect(allTrue.isSecureHardwareUnavailable, isTrue);
        expect(allFalse.isSecureHardwareUnavailable, isFalse);
      });

      test('hasObfuscationIssues', () {
        expect(allTrue.hasObfuscationIssues, isTrue);
        expect(allFalse.hasObfuscationIssues, isFalse);
      });

      test('isTimeSpoofed', () {
        expect(allTrue.isTimeSpoofed, isTrue);
        expect(allFalse.isTimeSpoofed, isFalse);
      });

      test('isLocationSpoofed', () {
        expect(allTrue.isLocationSpoofed, isTrue);
        expect(allFalse.isLocationSpoofed, isFalse);
      });

      test('isMultiInstance', () {
        expect(allTrue.isMultiInstance, isTrue);
        expect(allFalse.isMultiInstance, isFalse);
      });

      test('isDeviceBindingCompromised', () {
        expect(allTrue.isDeviceBindingCompromised, isTrue);
        expect(allFalse.isDeviceBindingCompromised, isFalse);
      });
    });

    test('getter defaults to false for missing threat', () {
      final empty = RaspResult.fromMap({});
      expect(empty.isRooted, isFalse);
      expect(empty.isVpnConnected, isFalse);
    });

    test('equality', () {
      final a = RaspResult.fromMap({'root': true, 'emulator': false});
      final b = RaspResult.fromMap({'root': true, 'emulator': false});
      final c = RaspResult.fromMap({'root': false, 'emulator': false});

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes detected threats', () {
      final result = RaspResult.fromMap({'root': true, 'emulator': false});
      expect(result.toString(), contains('root'));
      expect(result.toString(), startsWith('RaspResult('));
    });
  });
}
