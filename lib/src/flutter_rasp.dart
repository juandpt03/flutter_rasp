import 'dart:async';

import 'package:flutter/foundation.dart';

import 'callbacks/threat_callback.dart';
import 'enums/threat.dart';
import 'errors/rasp_exception.dart';
import 'flutter_rasp_platform_interface.dart';
import 'models/rasp_config.dart';
import 'models/rasp_result.dart';

/// Main entry point for the flutter_rasp plugin.
///
/// Provides real-time threat monitoring, on-demand security scans,
/// and screen capture protection for Android and iOS.
class FlutterRasp {
  FlutterRasp._();

  static final FlutterRasp instance = FlutterRasp._();

  FlutterRaspPlatform get _platform => FlutterRaspPlatform.instance;

  StreamSubscription<List<String>>? _subscription;
  RaspConfig? _config;
  ThreatCallback? _threatCallback;

  bool get isInitialized => _config != null;

  /// Starts real-time threat monitoring.
  ///
  /// At least one of [onThreatDetected] or [threatCallback] must be provided.
  /// Throws [RaspException] if already initialized or both callbacks are null.
  Future<void> initialize({
    RaspConfig config = RaspConfig.defaultConfig,
    void Function(Set<Threat> threats)? onThreatDetected,
    ThreatCallback? threatCallback,
  }) async {
    if (_config != null) {
      throw RaspException.alreadyInitialized();
    }
    if (onThreatDetected == null && threatCallback == null) {
      throw RaspException.invalidArgument();
    }
    config.validate();
    _config = config;
    _threatCallback = threatCallback;

    await _platform.startMonitoring(config);

    _subscription = _platform.threatStream.listen(
      (threatNames) {
        final threats = threatNames
            .map(Threat.fromName)
            .where((t) => t != Threat.undefined)
            .toSet();
        if (threats.isEmpty) return;
        onThreatDetected?.call(threats);
        _dispatchThreats(threats);
      },
      onError: (error) {
        debugPrint('FlutterRasp stream error: $error');
      },
      onDone: () {
        _config = null;
        _subscription = null;
        _threatCallback = null;
      },
    );
  }

  /// Replaces the current [ThreatCallback] at runtime.
  ///
  /// Throws [RaspException] if not initialized.
  void attachListener(ThreatCallback callback) {
    _ensureInitialized();
    _threatCallback = callback;
  }

  void detachListener() {
    _threatCallback = null;
  }

  /// Runs a one-time scan. If [enabledThreats] is empty, all threats are scanned.
  Future<RaspResult> scanAll({Set<Threat> enabledThreats = const {}}) async {
    _ensureInitialized();
    final threats = enabledThreats.isEmpty
        ? Threat.active
        : enabledThreats.intersection(Threat.active);
    final result = await _platform.scanAll(threats.map((t) => t.name).toList());
    return RaspResult.fromMap(result);
  }

  Future<bool> isRooted() => _check(Threat.root);

  Future<bool> isEmulator() => _check(Threat.emulator);

  Future<bool> isDebugged() => _check(Threat.debug);

  Future<bool> isHooked() => _check(Threat.hook);

  Future<bool> isRepackaged() => _check(Threat.repackaging);

  Future<bool> isUntrustedInstall() => _check(Threat.trustedInstall);

  Future<bool> isVpnConnected() => _check(Threat.vpn);

  Future<bool> isDeveloperMode() => _check(Threat.developerMode);

  Future<bool> isAdbEnabled() => _check(Threat.adbEnabled);

  Future<bool> isDevicePasscodeDisabled() => _check(Threat.devicePasscode);

  Future<bool> isSecureHardwareUnavailable() =>
      _check(Threat.secureHardwareNotAvailable);

  Future<bool> hasObfuscationIssues() => _check(Threat.obfuscationIssues);

  Future<bool> isTimeSpoofed() => _check(Threat.timeSpoofing);

  Future<bool> isLocationSpoofed() => _check(Threat.locationSpoofing);

  Future<bool> isMultiInstance() => _check(Threat.multiInstance);

  /// When `true`, hides app content from screenshots and screen recordings.
  Future<void> blockScreenCapture(bool enabled) {
    _ensureInitialized();
    return _platform.blockScreenCapture(enabled);
  }

  Future<bool> isScreenCaptureBlocked() {
    _ensureInitialized();
    return _platform.isScreenCaptureBlocked();
  }

  /// Stops monitoring and releases all resources.
  Future<void> dispose() async {
    _subscription?.cancel();
    _subscription = null;
    _config = null;
    _threatCallback = null;
    await _platform.stopMonitoring();
  }

  @visibleForTesting
  void resetForTesting() {
    _subscription?.cancel();
    _subscription = null;
    _config = null;
    _threatCallback = null;
  }

  void _ensureInitialized() {
    if (_config == null) throw RaspException.notInitialized();
  }

  Future<bool> _check(Threat threat) {
    _ensureInitialized();
    return _platform.checkThreat(threat.name);
  }

  void _dispatchThreats(Set<Threat> threats) {
    final callback = _threatCallback;
    if (callback == null) return;
    for (final threat in threats) {
      _dispatchToCallback(threat, callback);
    }
  }

  void _dispatchToCallback(Threat threat, ThreatCallback callback) {
    switch (threat) {
      case Threat.root:
        callback.onRoot?.call();
      case Threat.emulator:
        callback.onEmulator?.call();
      case Threat.debug:
        callback.onDebug?.call();
      case Threat.hook:
        callback.onHook?.call();
      case Threat.repackaging:
        callback.onRepackaging?.call();
      case Threat.trustedInstall:
        callback.onTrustedInstall?.call();
      case Threat.vpn:
        callback.onVpn?.call();
      case Threat.developerMode:
        callback.onDeveloperMode?.call();
      case Threat.adbEnabled:
        callback.onAdbEnabled?.call();
      case Threat.devicePasscode:
        callback.onDevicePasscode?.call();
      case Threat.secureHardwareNotAvailable:
        callback.onSecureHardwareNotAvailable?.call();
      case Threat.obfuscationIssues:
        callback.onObfuscationIssues?.call();
      case Threat.timeSpoofing:
        callback.onTimeSpoofing?.call();
      case Threat.locationSpoofing:
        callback.onLocationSpoofing?.call();
      case Threat.multiInstance:
        callback.onMultiInstance?.call();
      case Threat.undefined:
        break;
    }
  }
}
