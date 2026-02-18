import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('RaspConfig serialization', () {
    test('default config serializes correctly', () {
      const config = RaspConfig();
      final map = config.toMap();
      final threats = map['enabledThreats'] as List;

      expect(threats, isNot(contains('undefined')));
      expect(threats.length, Threat.active.length);
      expect(map['monitoringInterval'], 10000);
      expect(map['exitThreats'], isEmpty);
    });

    test('custom config serializes correctly', () {
      const config = RaspConfig(
        enabledThreats: {Threat.root, Threat.emulator},
        policy: ThreatPolicy.high,
        monitoringInterval: Duration(seconds: 5),
      );
      final map = config.toMap();

      expect(map['enabledThreats'], containsAll(['root', 'emulator']));
      expect(map['monitoringInterval'], 5000);
      final exitThreats = map['exitThreats'] as List;
      expect(exitThreats, containsAll(['root', 'hook', 'repackaging', 'debug']));
    });

    test('interval clamps below 1 second', () {
      const config = RaspConfig(
        monitoringInterval: Duration(milliseconds: 500),
      );
      expect(config.toMap()['monitoringInterval'], 1000);
    });

    test('exitThreats filters undefined', () {
      const config = RaspConfig(
        policy: ThreatPolicy(exitThreats: {Threat.vpn, Threat.undefined}),
      );
      expect(config.toMap()['exitThreats'], ['vpn']);
    });

    test('androidConfig serializes correctly', () {
      const config = RaspConfig(
        androidConfig: AndroidRaspConfig(
          signingCertHashes: ['abc123=='],
          supportedStores: ['com.android.vending'],
        ),
      );
      final android = config.toMap()['androidConfig'] as Map<String, dynamic>;
      expect(android['signingCertHashes'], ['abc123==']);
      expect(android['supportedStores'], ['com.android.vending']);
    });

    test('iosConfig serializes correctly', () {
      const config = RaspConfig(
        iosConfig: IosRaspConfig(teamId: 'ABC123', bundleIds: ['com.example.app']),
      );
      final ios = config.toMap()['iosConfig'] as Map<String, dynamic>;
      expect(ios['teamId'], 'ABC123');
      expect(ios['bundleIds'], ['com.example.app']);
    });
  });

  group('RaspConfig validation', () {
    test('android throws on empty signingCertHashes', () {
      const config = RaspConfig(
        androidConfig: AndroidRaspConfig(signingCertHashes: []),
      );
      expect(() => config.validate(), throwsA(isA<RaspException>()));
    });

    test('iOS throws on empty teamId', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const config = RaspConfig(
        iosConfig: IosRaspConfig(teamId: '', bundleIds: ['com.app']),
      );
      expect(() => config.validate(), throwsA(isA<RaspException>()));
    });

    test('iOS throws on empty bundleIds', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      const config = RaspConfig(
        iosConfig: IosRaspConfig(teamId: 'TEAM', bundleIds: []),
      );
      expect(() => config.validate(), throwsA(isA<RaspException>()));
    });
  });

  group('AndroidRaspConfig', () {
    test('has sensible default supportedStores', () {
      const config = AndroidRaspConfig(signingCertHashes: ['hash==']);
      expect(config.supportedStores, contains('com.android.vending'));
      expect(config.supportedStores, contains('com.amazon.venezia'));
      expect(config.supportedStores, contains('com.huawei.appmarket'));
      expect(config.supportedStores, contains('com.sec.android.app.samsungapps'));
    });
  });
}
