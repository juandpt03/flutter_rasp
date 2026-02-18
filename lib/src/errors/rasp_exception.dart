import 'package:flutter/services.dart';

import '../enums/rasp_error_code.dart';

/// Exception thrown by flutter_rasp operations.
///
/// Each exception carries a [RaspErrorCode] and a human-readable [message].
class RaspException implements Exception {
  final RaspErrorCode errorCode;

  final String message;

  const RaspException._(this.errorCode, this.message);

  factory RaspException.invalidArgument() => RaspException._(
    RaspErrorCode.invalidArgument,
    RaspErrorCode.invalidArgument.message,
  );

  factory RaspException.noContext() =>
      RaspException._(RaspErrorCode.noContext, RaspErrorCode.noContext.message);

  factory RaspException.nullResponse() => RaspException._(
    RaspErrorCode.nullResponse,
    RaspErrorCode.nullResponse.message,
  );

  factory RaspException.timeout() =>
      RaspException._(RaspErrorCode.timeout, RaspErrorCode.timeout.message);

  factory RaspException.monitoringAlreadyActive() => RaspException._(
    RaspErrorCode.monitoringAlreadyActive,
    RaspErrorCode.monitoringAlreadyActive.message,
  );

  factory RaspException.monitoringNotActive() => RaspException._(
    RaspErrorCode.monitoringNotActive,
    RaspErrorCode.monitoringNotActive.message,
  );

  factory RaspException.screenCaptureNoActivity() => RaspException._(
    RaspErrorCode.screenCaptureNoActivity,
    RaspErrorCode.screenCaptureNoActivity.message,
  );

  factory RaspException.emptySigningHashes() => RaspException._(
    RaspErrorCode.emptySigningHashes,
    RaspErrorCode.emptySigningHashes.message,
  );

  factory RaspException.emptyBundleIds() => RaspException._(
    RaspErrorCode.emptyBundleIds,
    RaspErrorCode.emptyBundleIds.message,
  );

  factory RaspException.emptyTeamId() => RaspException._(
    RaspErrorCode.emptyTeamId,
    RaspErrorCode.emptyTeamId.message,
  );

  factory RaspException.invalidHashFormat() => RaspException._(
    RaspErrorCode.invalidHashFormat,
    RaspErrorCode.invalidHashFormat.message,
  );

  factory RaspException.alreadyInitialized() => RaspException._(
    RaspErrorCode.alreadyInitialized,
    RaspErrorCode.alreadyInitialized.message,
  );

  factory RaspException.notInitialized() => RaspException._(
    RaspErrorCode.notInitialized,
    RaspErrorCode.notInitialized.message,
  );

  factory RaspException.general() =>
      RaspException._(RaspErrorCode.general, RaspErrorCode.general.message);

  factory RaspException.unknown({String? message}) => RaspException._(
    RaspErrorCode.unknown,
    message ?? RaspErrorCode.unknown.message,
  );

  /// Creates a [RaspException] from a native [PlatformException].
  factory RaspException.fromPlatform(PlatformException e) {
    final code = RaspErrorCode.fromNativeCode(e.code);
    return RaspException._(code, e.message ?? code.message);
  }

  @override
  String toString() => 'RaspException(${errorCode.name}): $message';
}
