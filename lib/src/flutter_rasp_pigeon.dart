import 'dart:async';

import 'package:flutter/services.dart';

import 'errors/rasp_exception.dart';
import 'flutter_rasp_platform_interface.dart';
import 'generated/rasp_api.g.dart';
import 'models/rasp_config.dart';

/// Pigeon-based implementation of [FlutterRaspPlatform].
///
/// Replaces the manual [MethodChannel]/[EventChannel] approach with
/// type-safe generated code. Native-to-Dart threat events are received
/// via [FlutterRaspFlutterApi] and exposed as a broadcast [Stream].
class PigeonFlutterRasp extends FlutterRaspPlatform
    implements FlutterRaspFlutterApi {
  static const _timeout = Duration(seconds: 30);

  final FlutterRaspHostApi _hostApi = FlutterRaspHostApi();
  final StreamController<List<String>> _threatController =
      StreamController<List<String>>.broadcast();
  bool _flutterApiSetUp = false;

  void _ensureFlutterApiSetUp() {
    if (!_flutterApiSetUp) {
      FlutterRaspFlutterApi.setUp(this);
      _flutterApiSetUp = true;
    }
  }

  @override
  Future<void> startMonitoring(RaspConfig config) async {
    _ensureFlutterApiSetUp();
    final message = _configToMessage(config);
    await _call(() => _hostApi.startMonitoring(message));
  }

  @override
  Future<void> stopMonitoring() => _call(() => _hostApi.stopMonitoring());

  @override
  Stream<List<String>> get threatStream => _threatController.stream;

  @override
  Future<bool> checkThreat(String threatName) =>
      _call(() => _hostApi.checkThreat(threatName));

  @override
  Future<Map<String, bool>> scanAll(List<String> enabledThreats) async {
    final result = await _call(() => _hostApi.scanAll(enabledThreats));
    return {
      for (final entry in result.results) entry.threatName: entry.detected,
    };
  }

  @override
  Future<void> blockScreenCapture(bool enabled) =>
      _call(() => _hostApi.blockScreenCapture(enabled));

  @override
  Future<bool> isScreenCaptureBlocked() =>
      _call(() => _hostApi.isScreenCaptureBlocked());

  // -- FlutterApi: called from native --

  @override
  void onThreatsDetected(List<String> threats) {
    _threatController.add(threats);
  }

  // -- Internal --

  Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn().timeout(_timeout);
    } on PlatformException catch (e) {
      throw RaspException.fromPlatform(e);
    } on TimeoutException {
      throw RaspException.timeout();
    }
  }

  static RaspConfigMessage _configToMessage(RaspConfig config) {
    final map = config.toMap();
    return RaspConfigMessage(
      enabledThreats: (map['enabledThreats'] as List).cast<String>(),
      exitThreats: (map['exitThreats'] as List).cast<String>(),
      monitoringIntervalMs: map['monitoringInterval'] as int,
      androidConfig: _toAndroidConfig(map['androidConfig']),
      iosConfig: _toIosConfig(map['iosConfig']),
    );
  }

  static AndroidConfigMessage? _toAndroidConfig(dynamic raw) {
    if (raw == null) return null;
    final m = raw as Map<String, dynamic>;
    return AndroidConfigMessage(
      signingCertHashes: (m['signingCertHashes'] as List).cast<String>(),
      supportedStores: (m['supportedStores'] as List).cast<String>(),
    );
  }

  static IosConfigMessage? _toIosConfig(dynamic raw) {
    if (raw == null) return null;
    final m = raw as Map<String, dynamic>;
    return IosConfigMessage(
      teamId: m['teamId'] as String,
      bundleIds: (m['bundleIds'] as List).cast<String>(),
    );
  }
}
