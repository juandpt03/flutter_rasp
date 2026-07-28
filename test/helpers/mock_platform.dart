import 'dart:async';

import 'package:flutter_rasp/flutter_rasp.dart';
// ignore: implementation_imports
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

  Map<String, bool> checkResults = {'emulator': true};

  Map<String, bool> scanResults = {
    'root': false,
    'emulator': true,
    'debug': true,
    'hook': false,
    'repackaging': false,
    'trustedInstall': false,
    'vpn': false,
    'developerMode': false,
    'adbEnabled': false,
    'devicePasscode': false,
    'secureHardwareNotAvailable': true,
    'obfuscationIssues': false,
    'timeSpoofing': false,
    'locationSpoofing': false,
    'multiInstance': false,
    'deviceBinding': false,
  };

  // Reporter spies.
  ReporterConfig? lastReporterConfig;
  int initReporterCalls = 0;
  int disposeReporterCalls = 0;
  final List<Map<String, Object?>> breadcrumbs = <Map<String, Object?>>[];
  final List<Map<String, Object?>> capturedErrors = <Map<String, Object?>>[];
  String? lastUserId;
  int flushCalls = 0;

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
  Future<bool> checkThreat(String threatName) async =>
      checkResults[threatName] ?? false;

  @override
  Future<Map<String, bool>> scanAll(List<String> enabledThreats) async =>
      scanResults;

  @override
  Future<void> blockScreenCapture(bool enabled) async {
    screenCaptureBlocked = enabled;
  }

  @override
  Future<bool> isScreenCaptureBlocked() async => screenCaptureBlocked;

  // ── Reporter ──

  @override
  Future<void> initReporter(ReporterConfig config) async {
    lastReporterConfig = config;
    initReporterCalls++;
  }

  @override
  Future<void> disposeReporter() async {
    disposeReporterCalls++;
  }

  @override
  Future<void> addBreadcrumb({
    required int timestampMs,
    required String category,
    required String level,
    required String message,
    required String dataJson,
  }) async {
    breadcrumbs.add(<String, Object?>{
      'timestampMs': timestampMs,
      'category': category,
      'level': level,
      'message': message,
      'dataJson': dataJson,
    });
  }

  @override
  Future<void> captureError({
    required String event,
    String? message,
    String? stackTrace,
    String? library,
  }) async {
    capturedErrors.add(<String, Object?>{
      'event': event,
      'message': message,
      'stackTrace': stackTrace,
      'library': library,
    });
  }

  @override
  Future<void> setReporterUserId(String? userId) async {
    lastUserId = userId;
  }

  @override
  Future<void> flushReporter() async {
    flushCalls++;
  }
}

FlutterRasp freshRasp() {
  final rasp = FlutterRasp.instance;
  // ignore: invalid_use_of_visible_for_testing_member
  rasp.resetForTesting();
  return rasp;
}
