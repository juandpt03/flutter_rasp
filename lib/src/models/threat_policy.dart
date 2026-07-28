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
///
/// `Threat.trustedInstall` is still detected and reported, but it's not
/// part of the presets' [exitThreats] — some install channels don't always
/// expose the installer package name (see [Threat.trustedInstall]). Add it
/// to a custom policy if you want it to terminate the app.
///
/// `Threat.deviceBinding` is also intentionally excluded from every preset:
/// it fires when a user migrates to a new phone, which is a legitimate flow.
/// Respond with re-enrollment (see [Threat.deviceBinding]) instead of
/// terminating the app.
class ThreatPolicy {
  final Set<Threat> exitThreats;

  const ThreatPolicy({this.exitThreats = const {}});

  static const none = ThreatPolicy();

  static const low = ThreatPolicy(
    exitThreats: {Threat.repackaging},
  );

  static const medium = ThreatPolicy(
    exitThreats: {
      Threat.root,
      Threat.hook,
      Threat.repackaging,
      Threat.obfuscationIssues,
      Threat.multiInstance,
    },
  );

  static const high = ThreatPolicy(
    exitThreats: {
      Threat.root,
      Threat.hook,
      Threat.repackaging,
      Threat.debug,
      Threat.adbEnabled,
      Threat.devicePasscode,
      Threat.obfuscationIssues,
      Threat.multiInstance,
      Threat.secureHardwareNotAvailable,
      Threat.locationSpoofing,
    },
  );
}
