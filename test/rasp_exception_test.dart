import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('RaspException', () {
    group('fromPlatform', () {
      /// All known native code -> RaspErrorCode mappings.
      final nativeCodeMappings = <String, RaspErrorCode>{
        'INVALID_ARGUMENT': RaspErrorCode.invalidArgument,
        'NO_CONTEXT': RaspErrorCode.noContext,
        'null-response': RaspErrorCode.nullResponse,
        'TIMEOUT': RaspErrorCode.timeout,
        'MONITORING_ALREADY_ACTIVE': RaspErrorCode.monitoringAlreadyActive,
        'MONITORING_NOT_ACTIVE': RaspErrorCode.monitoringNotActive,
        'SCREEN_CAPTURE_NO_ACTIVITY': RaspErrorCode.screenCaptureNoActivity,
        'EMPTY_SIGNING_HASHES': RaspErrorCode.emptySigningHashes,
        'EMPTY_BUNDLE_IDS': RaspErrorCode.emptyBundleIds,
        'EMPTY_TEAM_ID': RaspErrorCode.emptyTeamId,
        'INVALID_HASH_FORMAT': RaspErrorCode.invalidHashFormat,
      };

      for (final entry in nativeCodeMappings.entries) {
        test('maps ${entry.key} to ${entry.value.name}', () {
          final exception = RaspException.fromPlatform(
            PlatformException(code: entry.key, message: 'test'),
          );
          expect(exception.errorCode, entry.value);
          expect(exception.message, 'test');
        });
      }

      test(
        'falls back to error code message when platform message is null',
        () {
          final exception = RaspException.fromPlatform(
            PlatformException(code: 'TIMEOUT'),
          );
          expect(exception.errorCode, RaspErrorCode.timeout);
          expect(exception.message, RaspErrorCode.timeout.message);
        },
      );

      test('unknown code maps to RaspErrorCode.unknown', () {
        final exception = RaspException.fromPlatform(
          PlatformException(code: 'SOMETHING_NEW'),
        );
        expect(exception.errorCode, RaspErrorCode.unknown);
      });
    });

    group('named constructors', () {
      /// Every named factory must produce the correct errorCode and a
      /// non-empty message that matches its RaspErrorCode.message.
      final namedConstructors = <String, RaspException Function()>{
        'invalidArgument': RaspException.invalidArgument,
        'noContext': RaspException.noContext,
        'nullResponse': RaspException.nullResponse,
        'timeout': RaspException.timeout,
        'monitoringAlreadyActive': RaspException.monitoringAlreadyActive,
        'monitoringNotActive': RaspException.monitoringNotActive,
        'screenCaptureNoActivity': RaspException.screenCaptureNoActivity,
        'emptySigningHashes': RaspException.emptySigningHashes,
        'emptyBundleIds': RaspException.emptyBundleIds,
        'emptyTeamId': RaspException.emptyTeamId,
        'invalidHashFormat': RaspException.invalidHashFormat,
        'alreadyInitialized': RaspException.alreadyInitialized,
        'notInitialized': RaspException.notInitialized,
        'general': RaspException.general,
      };

      for (final entry in namedConstructors.entries) {
        test('${entry.key} has correct errorCode and message', () {
          final e = entry.value();
          expect(e.errorCode.name, entry.key);
          expect(e.message, isNotEmpty);
          expect(e.message, e.errorCode.message);
        });
      }

      test('unknown with custom message', () {
        final e = RaspException.unknown(message: 'custom');
        expect(e.errorCode, RaspErrorCode.unknown);
        expect(e.message, 'custom');
      });

      test('unknown without message uses default', () {
        final e = RaspException.unknown();
        expect(e.message, RaspErrorCode.unknown.message);
      });
    });

    test('toString includes error code and message', () {
      final e = RaspException.notInitialized();
      expect(e.toString(), contains('notInitialized'));
      expect(e.toString(), contains(RaspErrorCode.notInitialized.message));
    });
  });
}
