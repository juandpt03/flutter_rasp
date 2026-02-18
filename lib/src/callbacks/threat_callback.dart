import 'package:flutter/foundation.dart';

/// Per-threat callbacks invoked by [FlutterRasp] when threats are detected.
///
/// Pass to [FlutterRasp.initialize] or [FlutterRasp.attachListener]:
///
/// ```dart
/// ThreatCallback(
///   onRoot: () => debugPrint('Rooted!'),
///   onVpn: () => debugPrint('VPN active!'),
/// );
/// ```
class ThreatCallback {
  const ThreatCallback({
    this.onRoot,
    this.onEmulator,
    this.onDebug,
    this.onHook,
    this.onRepackaging,
    this.onTrustedInstall,
    this.onVpn,
    this.onDeveloperMode,
    this.onDevicePasscode,
    this.onSecureHardwareNotAvailable,
    this.onObfuscationIssues,
    this.onTimeSpoofing,
    this.onLocationSpoofing,
    this.onMultiInstance,
  });

  final VoidCallback? onRoot;
  final VoidCallback? onEmulator;
  final VoidCallback? onDebug;
  final VoidCallback? onHook;
  final VoidCallback? onRepackaging;
  final VoidCallback? onTrustedInstall;
  final VoidCallback? onVpn;
  final VoidCallback? onDeveloperMode;
  final VoidCallback? onDevicePasscode;
  final VoidCallback? onSecureHardwareNotAvailable;
  final VoidCallback? onObfuscationIssues;
  final VoidCallback? onTimeSpoofing;
  final VoidCallback? onLocationSpoofing;
  final VoidCallback? onMultiInstance;
}
