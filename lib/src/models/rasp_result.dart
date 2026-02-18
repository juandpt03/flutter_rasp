import '../enums/threat.dart';

/// Result of a full security scan from [FlutterRasp.scanAll].
class RaspResult {
  final Map<Threat, bool> threats;

  const RaspResult(this.threats);

  factory RaspResult.fromMap(Map<String, bool> map) {
    final threats = <Threat, bool>{};
    for (final entry in map.entries) {
      final threat = Threat.fromName(entry.key);
      if (threat != Threat.undefined) threats[threat] = entry.value;
    }
    return RaspResult(threats);
  }

  bool get isCompromised => threats.values.any((detected) => detected);

  Set<Threat> get detectedThreats =>
      threats.entries.where((e) => e.value).map((e) => e.key).toSet();

  bool get isRooted => threats[Threat.root] ?? false;

  bool get isEmulator => threats[Threat.emulator] ?? false;

  bool get isDebugged => threats[Threat.debug] ?? false;

  bool get isHooked => threats[Threat.hook] ?? false;

  bool get isRepackaged => threats[Threat.repackaging] ?? false;

  bool get isUntrustedInstall => threats[Threat.trustedInstall] ?? false;

  bool get isVpnConnected => threats[Threat.vpn] ?? false;

  bool get isDeveloperMode => threats[Threat.developerMode] ?? false;

  bool get isDevicePasscodeDisabled => threats[Threat.devicePasscode] ?? false;

  bool get isSecureHardwareUnavailable =>
      threats[Threat.secureHardwareNotAvailable] ?? false;

  bool get hasObfuscationIssues => threats[Threat.obfuscationIssues] ?? false;

  bool get isTimeSpoofed => threats[Threat.timeSpoofing] ?? false;

  bool get isLocationSpoofed => threats[Threat.locationSpoofing] ?? false;

  bool get isMultiInstance => threats[Threat.multiInstance] ?? false;

  @override
  String toString() => 'RaspResult(detected: $detectedThreats)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RaspResult &&
          runtimeType == other.runtimeType &&
          _mapsEqual(threats, other.threats);

  @override
  int get hashCode => Object.hashAllUnordered(
    threats.entries.map((e) => Object.hash(e.key, e.value)),
  );

  static bool _mapsEqual(Map<Threat, bool> a, Map<Threat, bool> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
