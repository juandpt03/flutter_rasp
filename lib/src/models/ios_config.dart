/// iOS-specific configuration for repackaging detection.
class IosRaspConfig {
  /// Apple Developer Team ID (e.g. `'A1B2C3D4E5'`).
  final String teamId;

  /// Expected bundle identifiers (e.g. `['com.example.app']`).
  final List<String> bundleIds;

  const IosRaspConfig({required this.teamId, required this.bundleIds});

  Map<String, dynamic> toMap() => {'teamId': teamId, 'bundleIds': bundleIds};
}
