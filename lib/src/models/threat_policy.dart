import '../enums/threat.dart';

/// Defines which threats should terminate the app at the native level.
///
/// When a threat in [exitThreats] is detected, the native layer calls
/// `exit(1)` (iOS) or `Runtime.exit(1)` (Android) before Dart code
/// can react.
///
/// ```dart
/// const policy = ThreatPolicy(exitThreats: {Threat.root, Threat.repackaging});
/// ```
class ThreatPolicy {
  final Set<Threat> exitThreats;

  const ThreatPolicy({this.exitThreats = const {}});

  static const none = ThreatPolicy();

  static const low = ThreatPolicy(
    exitThreats: {Threat.repackaging, Threat.trustedInstall},
  );

  static const medium = ThreatPolicy(
    exitThreats: {
      Threat.root,
      Threat.hook,
      Threat.repackaging,
      Threat.trustedInstall,
      Threat.obfuscationIssues,
      Threat.multiInstance,
    },
  );

  static const high = ThreatPolicy(
    exitThreats: {
      Threat.root,
      Threat.hook,
      Threat.repackaging,
      Threat.trustedInstall,
      Threat.debug,
      Threat.adbEnabled,
      Threat.devicePasscode,
      Threat.obfuscationIssues,
      Threat.multiInstance,
      Threat.secureHardwareNotAvailable,
      Threat.locationSpoofing,
      Threat.deviceBinding,
    },
  );
}
