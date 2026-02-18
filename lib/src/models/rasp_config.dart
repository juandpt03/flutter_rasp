import '../enums/threat.dart';
import '../utils/config_verifier.dart';
import 'android_config.dart';
import 'ios_config.dart';
import 'threat_policy.dart';

/// Configuration for [FlutterRasp.initialize].
///
/// Controls which threats to monitor, the enforcement policy,
/// the monitoring interval, and platform-specific settings.
class RaspConfig {
  /// An empty set enables all threats.
  final Set<Threat> enabledThreats;

  final ThreatPolicy policy;

  /// Clamped to [minInterval].
  final Duration monitoringInterval;

  final AndroidRaspConfig? androidConfig;

  final IosRaspConfig? iosConfig;

  const RaspConfig({
    this.enabledThreats = const {},
    this.policy = const ThreatPolicy(),
    this.monitoringInterval = const Duration(seconds: 10),
    this.androidConfig,
    this.iosConfig,
  });

  static const defaultConfig = RaspConfig();

  static const Duration minInterval = Duration(seconds: 1);

  Set<Threat> get _resolvedThreats => enabledThreats.isEmpty
      ? Threat.active
      : enabledThreats.intersection(Threat.active);

  void validate() {
    if (androidConfig != null) ConfigVerifier.verifyAndroid(androidConfig!);
    if (iosConfig != null) ConfigVerifier.verifyIOS(iosConfig!);
  }

  Map<String, dynamic> toMap() {
    final effectiveInterval = monitoringInterval < minInterval
        ? minInterval
        : monitoringInterval;
    return {
      'enabledThreats': _resolvedThreats.map((t) => t.name).toList(),
      'exitThreats': policy.exitThreats
          .intersection(Threat.active)
          .map((t) => t.name)
          .toList(),
      'monitoringInterval': effectiveInterval.inMilliseconds,
      if (androidConfig != null) 'androidConfig': androidConfig!.toMap(),
      if (iosConfig != null) 'iosConfig': iosConfig!.toMap(),
    };
  }
}
