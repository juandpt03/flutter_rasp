import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_rasp_method_channel.dart';
import 'models/rasp_config.dart';

/// Platform interface for flutter_rasp native communication.
abstract class FlutterRaspPlatform extends PlatformInterface {
  FlutterRaspPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterRaspPlatform _instance = MethodChannelFlutterRasp();

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
}
