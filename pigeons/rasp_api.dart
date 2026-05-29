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
// DTOs — Threat detection (existing)
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
// DTOs — Reporter (new, native-driven)
// ──────────────────────────────────────────

/// All-in-one config for the native Reporter living in flutter_rasp_core.
class ReporterConfigMessage {
  ReporterConfigMessage({
    required this.endpoint,
    required this.headers,
    this.hmacKey,
    this.pinnedCertPem,
    required this.exitTimeoutMs,
    required this.httpTimeoutMs,
    required this.maxBreadcrumbs,
    required this.maxPendingReports,
    required this.retryBackoffsMs,
    required this.captureFlutterErrors,
    required this.capturePlatformErrors,
    required this.captureExitThreats,
    required this.captureDetectedThreats,
    this.userId,
  });

  final String endpoint;
  final Map<String, String> headers;
  final String? hmacKey;

  /// Raw PEM bytes for SSL pinning. `null` means no pinning (default
  /// system TLS validation).
  final Uint8List? pinnedCertPem;

  final int exitTimeoutMs;
  final int httpTimeoutMs;
  final int maxBreadcrumbs;
  final int maxPendingReports;
  final List<int> retryBackoffsMs;
  final bool captureFlutterErrors;
  final bool capturePlatformErrors;
  final bool captureExitThreats;
  final bool captureDetectedThreats;
  final String? userId;
}

class BreadcrumbMessage {
  BreadcrumbMessage({
    required this.timestampMs,
    required this.category,
    required this.level,
    required this.message,
    required this.dataJson,
  });

  final int timestampMs;
  final String category;

  /// `'debug' | 'info' | 'warning' | 'error' | 'fatal'`.
  final String level;
  final String message;

  /// Optional structured payload encoded as JSON string. Empty when
  /// no extra data.
  final String dataJson;
}

class CaptureErrorMessage {
  CaptureErrorMessage({
    required this.event,
    this.message,
    this.stackTrace,
    this.library,
  });

  /// `'flutterError' | 'dartError' | 'manualCapture'`.
  final String event;
  final String? message;
  final String? stackTrace;
  final String? library;
}

// ──────────────────────────────────────────
// HostApi: Dart -> Native
// ──────────────────────────────────────────

@HostApi()
abstract class FlutterRaspHostApi {
  // Threat monitoring
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

  // Reporter — everything lives natively in flutter_rasp_core
  @async
  void initReporter(ReporterConfigMessage config);

  @async
  void disposeReporter();

  @async
  void addBreadcrumb(BreadcrumbMessage breadcrumb);

  @async
  void captureError(CaptureErrorMessage error);

  @async
  void setReporterUserId(String? userId);

  @async
  void flushReporter();
}

// ──────────────────────────────────────────
// FlutterApi: Native -> Dart
// ──────────────────────────────────────────

@FlutterApi()
abstract class FlutterRaspFlutterApi {
  /// Fired by native each time the monitoring loop spots one or more
  /// non-exit threats. Used by `FlutterRasp.onThreatDetected` and the
  /// per-threat `ThreatCallback`.
  void onThreatsDetected(List<String> threats);
}
