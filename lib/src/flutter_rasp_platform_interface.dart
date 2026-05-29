import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_rasp_pigeon.dart';
import 'models/rasp_config.dart';
import 'reporting/rasp_reporter_config.dart';

/// Platform interface for flutter_rasp native communication.
abstract class FlutterRaspPlatform extends PlatformInterface {
  FlutterRaspPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRaspPlatform _instance = PigeonFlutterRasp();

  static FlutterRaspPlatform get instance => _instance;

  static set instance(FlutterRaspPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }


  Future<void> startMonitoring(RaspConfig config);
  Future<void> stopMonitoring();
  Stream<List<String>> get threatStream;
  Future<bool> checkThreat(String threatName);
  Future<Map<String, bool>> scanAll(List<String> enabledThreats);
  Future<void> blockScreenCapture(bool enabled);
  Future<bool> isScreenCaptureBlocked();


  Future<void> initReporter(ReporterConfig config);
  Future<void> disposeReporter();
  Future<void> addBreadcrumb({
    required int timestampMs,
    required String category,
    required String level,
    required String message,
    required String dataJson,
  });
  Future<void> captureError({
    required String event,
    String? message,
    String? stackTrace,
    String? library,
  });
  Future<void> setReporterUserId(String? userId);
  Future<void> flushReporter();
}
