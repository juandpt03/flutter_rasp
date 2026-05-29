import 'dart:typed_data';

/// Configuration for [RaspReporter].
class ReporterConfig {
  const ReporterConfig({
    required this.endpoint,
    this.headers = const <String, String>{},
    this.hmacKey,
    this.pinnedCertPem,
    this.exitTimeout = const Duration(milliseconds: 1500),
    this.httpTimeout = const Duration(milliseconds: 1200),
    this.maxBreadcrumbs = 50,
    this.maxPendingReports = 50,
    this.retryBackoffs = const <Duration>[
      Duration(seconds: 3),
      Duration(seconds: 9),
      Duration(seconds: 27),
    ],
    this.captureFlutterErrors = false,
    this.capturePlatformErrors = false,
    this.captureExitThreats = true,
    this.captureDetectedThreats = true,
    this.userId,
  });

  /// HTTPS endpoint that receives the JSON payload via `POST`.
  final Uri endpoint;

  /// Extra headers appended to every request (e.g. API keys).
  final Map<String, String> headers;

  /// Optional shared secret. When set, every body is signed with
  /// `HMAC-SHA256` and forwarded as `X-Rasp-Signature` (hex).
  final String? hmacKey;

  /// Raw PEM bytes for SSL pinning. When `null`, the native HTTP
  /// client falls back to system TLS validation (no pinning).
  final Uint8List? pinnedCertPem;

  /// Maximum time the native worker thread waits for the exit report
  /// to ship before killing the process.
  final Duration exitTimeout;

  /// Per-attempt HTTP timeout (connect + read).
  final Duration httpTimeout;

  /// Max in-memory breadcrumbs. Older entries are evicted (FIFO).
  final int maxBreadcrumbs;

  /// FIFO cap on the on-disk queue of pending reports.
  final int maxPendingReports;

  /// Backoff schedule applied after a transient delivery failure.
  /// List length defines the max retries per report.
  final List<Duration> retryBackoffs;

  /// Install a global `FlutterError.onError` handler that captures
  /// framework errors. Previous handler is chained.
  ///
  /// Disabled by default: in development these errors can be very
  /// noisy. Opt in by setting it to `true` when you want framework
  /// errors shipped to your backend.
  final bool captureFlutterErrors;

  /// Install a global `PlatformDispatcher.instance.onError` handler
  /// that captures uncaught Dart errors. Previous handler is chained.
  ///
  /// Disabled by default: in development these errors can be very
  /// noisy. Opt in by setting it to `true` when you want uncaught
  /// Dart errors shipped to your backend.
  final bool capturePlatformErrors;

  /// Build + ship a report before RASP kills the process.
  final bool captureExitThreats;

  /// Auto-ship a `threatDetected` report each time a new threat
  /// appears during monitoring (deduped per session).
  final bool captureDetectedThreats;

  /// Optional `user.id` shipped in each payload.
  final String? userId;
}
