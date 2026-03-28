import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/rasp_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/juandpt/flutter_rasp/RaspApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.juandpt.flutter_rasp'),
    swiftOut: 'ios/flutter_rasp/Sources/flutter_rasp/RaspApi.g.swift',
  ),
)

// ──────────────────────────────────────────
// DTOs
// ──────────────────────────────────────────

class AndroidConfigMessage {
  AndroidConfigMessage({
    required this.signingCertHashes,
    required this.supportedStores,
  });

  final List<String> signingCertHashes;
  final List<String> supportedStores;
}

class IosConfigMessage {
  IosConfigMessage({required this.teamId, required this.bundleIds});

  final String teamId;
  final List<String> bundleIds;
}

class RaspConfigMessage {
  RaspConfigMessage({
    required this.enabledThreats,
    required this.exitThreats,
    required this.monitoringIntervalMs,
    this.androidConfig,
    this.iosConfig,
  });

  final List<String> enabledThreats;
  final List<String> exitThreats;
  final int monitoringIntervalMs;
  final AndroidConfigMessage? androidConfig;
  final IosConfigMessage? iosConfig;
}

class ThreatResultEntry {
  ThreatResultEntry({required this.threatName, required this.detected});

  final String threatName;
  final bool detected;
}

class ScanResultMessage {
  ScanResultMessage({required this.results});

  final List<ThreatResultEntry> results;
}

// ──────────────────────────────────────────
// HostApi: Dart -> Native
// ──────────────────────────────────────────

@HostApi()
abstract class FlutterRaspHostApi {
  @async
  void startMonitoring(RaspConfigMessage config);

  @async
  void stopMonitoring();

  @async
  bool checkThreat(String threatName);

  @async
  ScanResultMessage scanAll(List<String> enabledThreats);

  @async
  void blockScreenCapture(bool enabled);

  @async
  bool isScreenCaptureBlocked();
}

// ──────────────────────────────────────────
// FlutterApi: Native -> Dart (replaces EventChannel)
// ──────────────────────────────────────────

@FlutterApi()
abstract class FlutterRaspFlutterApi {
  void onThreatsDetected(List<String> threats);
}
