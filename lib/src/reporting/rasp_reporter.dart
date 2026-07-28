import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../enums/breadcrumb_level.dart';
import '../errors/rasp_exception.dart';
import '../flutter_rasp_platform_interface.dart';
import 'rasp_reporter_config.dart';

/// Dart entry point for the native security reporter. Reports are
/// built and shipped natively — inspect them at your backend.
class RaspReporter {
  RaspReporter._();

  static final RaspReporter instance = RaspReporter._();

  FlutterRaspPlatform get _platform => FlutterRaspPlatform.instance;

  ReporterConfig? _config;
  FlutterExceptionHandler? _previousFlutterOnError;
  ErrorCallback? _previousPlatformOnError;

  bool get isInitialized => _config != null;
  ReporterConfig? get config => _config;

  /// Initializes the native reporter and installs the global error
  /// handlers. Throws [RaspException] if already initialized — call
  /// [dispose] first if you need to re-configure.
  Future<void> initialize(ReporterConfig config) async {
    if (_config != null) {
      throw RaspException.raspReporterAlreadyInitialized();
    }
    await _platform.initReporter(config);
    _config = config;

    if (config.captureFlutterErrors) {
      _previousFlutterOnError = FlutterError.onError;
      FlutterError.onError = _onFlutterError;
    }
    if (config.capturePlatformErrors) {
      _previousPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = _onPlatformError;
    }
  }

  /// Removes the global handlers and tears down the native reporter.
  /// Order matters: uninstall the handlers FIRST (so no late errors
  /// queue a `captureError` against a disposed native reporter), then
  /// flip the local flag, then tear native down.
  Future<void> dispose() async {
    final config = _config;
    if (config == null) return;
    if (config.captureFlutterErrors) {
      FlutterError.onError = _previousFlutterOnError;
      _previousFlutterOnError = null;
    }
    if (config.capturePlatformErrors) {
      PlatformDispatcher.instance.onError = _previousPlatformOnError;
      _previousPlatformOnError = null;
    }
    _config = null;
    await _platform.disposeReporter();
  }

  /// Appends a breadcrumb. No-op when not initialized.
  Future<void> addBreadcrumb({
    required String message,
    String category = 'app',
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, Object?> data = const <String, Object?>{},
  }) async {
    if (_config == null) return;
    await _platform.addBreadcrumb(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      category: category,
      level: level.wireName,
      message: message,
      dataJson: data.isEmpty ? '' : jsonEncode(data),
    );
  }

  /// Manually report an error from app code.
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (_config == null) return;
    await _platform.captureError(
      event: 'manualCapture',
      message: hint ?? error.toString(),
      stackTrace: stackTrace?.toString(),
      library: null,
    );
  }

  /// Sets the optional `user.id` field shipped with each report.
  Future<void> setUserId(String? userId) async {
    if (_config == null) return;
    await _platform.setReporterUserId(userId);
  }

  /// Asks the native worker to drain the persisted queue.
  Future<void> flushPending() async {
    if (_config == null) return;
    await _platform.flushReporter();
  }

  void _onFlutterError(FlutterErrorDetails details) {
    _previousFlutterOnError?.call(details);
    unawaited(
      _platform
          .captureError(
            event: 'flutterError',
            message: details.exceptionAsString(),
            stackTrace: details.stack?.toString(),
            library: details.library,
          )
          .catchError(
            (e) => debugPrint('flutter_rasp: captureError flutterError — $e'),
          ),
    );
  }

  bool _onPlatformError(Object error, StackTrace stackTrace) {
    final handled = _previousPlatformOnError?.call(error, stackTrace) ?? false;
    unawaited(
      _platform
          .captureError(
            event: 'dartError',
            message: error.toString(),
            stackTrace: stackTrace.toString(),
            library: null,
          )
          .catchError(
            (e) => debugPrint('flutter_rasp: captureError dartError — $e'),
          ),
    );
    return handled;
  }

  @visibleForTesting
  Future<void> resetForTesting() async {
    _config = null;
    _previousFlutterOnError = null;
    _previousPlatformOnError = null;
  }
}
