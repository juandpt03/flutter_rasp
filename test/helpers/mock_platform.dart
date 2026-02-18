import 'dart:async';

import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_rasp/src/flutter_rasp_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterRaspPlatform
    with MockPlatformInterfaceMixin
    implements FlutterRaspPlatform {
  final StreamController<List<String>> controller =
      StreamController<List<String>>.broadcast();

  bool monitoringStarted = false;
  bool monitoringStopped = false;
  bool screenCaptureBlocked = false;

  /// Map threat name -> result for [checkThreat].
  /// Defaults to false for unknown threats.
  Map<String, bool> checkResults = {'emulator': true};

  /// Fixed results for [scanAll].
  Map<String, bool> scanResults = {
    'root': false,
    'emulator': true,
    'debug': true,
    'hook': false,
    'repackaging': false,
    'trustedInstall': false,
    'vpn': false,
    'developerMode': false,
    'devicePasscode': false,
    'secureHardwareNotAvailable': true,
    'obfuscationIssues': false,
    'timeSpoofing': false,
    'locationSpoofing': false,
    'multiInstance': false,
  };

  @override
  Future<void> startMonitoring(RaspConfig config) async {
    monitoringStarted = true;
  }

  @override
  Future<void> stopMonitoring() async {
    monitoringStopped = true;
  }

  @override
  Stream<List<String>> get threatStream => controller.stream;

  @override
  Future<bool> checkThreat(String threatName) async {
    return checkResults[threatName] ?? false;
  }

  @override
  Future<Map<String, bool>> scanAll(List<String> enabledThreats) async {
    return scanResults;
  }

  @override
  Future<void> blockScreenCapture(bool enabled) async {
    screenCaptureBlocked = enabled;
  }

  @override
  Future<bool> isScreenCaptureBlocked() async {
    return screenCaptureBlocked;
  }
}

FlutterRasp freshRasp() {
  final rasp = FlutterRasp.instance;
  // ignore: invalid_use_of_visible_for_testing_member
  rasp.resetForTesting();
  return rasp;
}
