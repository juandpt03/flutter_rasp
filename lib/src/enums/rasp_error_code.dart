/// Error codes used by [RaspException].
enum RaspErrorCode {
  invalidArgument('A required argument was missing or invalid.'),
  noContext('Android application context is not available.'),
  nullResponse('The platform returned an unexpected null response.'),
  timeout('The platform call exceeded the timeout limit.'),
  monitoringAlreadyActive(
    'Monitoring is already active. Call stopMonitoring() first.',
  ),
  monitoringNotActive(
    'Monitoring is not active. Call startMonitoring() first.',
  ),
  screenCaptureNoActivity(
    'Cannot block screen capture: no active Activity available.',
  ),
  emptySigningHashes(
    'signingCertHashes must not be empty. Provide at least one SHA-256 fingerprint.',
  ),
  emptyBundleIds(
    'bundleIds must not be empty. Provide at least one expected bundle identifier.',
  ),
  emptyTeamId(
    'teamId must not be empty. Provide your Apple Developer Team ID.',
  ),
  invalidHashFormat(
    'Invalid signing hash format. Expected SHA-256 hex fingerprint (e.g. A1:2B:3C:...).',
  ),
  alreadyInitialized('FlutterRasp is already initialized.'),
  notInitialized('FlutterRasp must be initialized. Call initialize() first.'),
  general('A general error occurred.'),
  unknown('An unknown error occurred.');

  final String message;

  const RaspErrorCode(this.message);

  static const _nativeCodeMap = <String, RaspErrorCode>{
    'INVALID_ARGUMENT': invalidArgument,
    'NO_CONTEXT': noContext,
    'null-response': nullResponse,
    'TIMEOUT': timeout,
    'MONITORING_ALREADY_ACTIVE': monitoringAlreadyActive,
    'MONITORING_NOT_ACTIVE': monitoringNotActive,
    'SCREEN_CAPTURE_NO_ACTIVITY': screenCaptureNoActivity,
    'EMPTY_SIGNING_HASHES': emptySigningHashes,
    'EMPTY_BUNDLE_IDS': emptyBundleIds,
    'EMPTY_TEAM_ID': emptyTeamId,
    'INVALID_HASH_FORMAT': invalidHashFormat,
  };

  static RaspErrorCode fromNativeCode(String code) =>
      _nativeCodeMap[code] ?? unknown;
}
