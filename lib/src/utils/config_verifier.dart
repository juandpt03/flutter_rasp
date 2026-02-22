import 'package:flutter/foundation.dart';

import '../errors/rasp_exception.dart';
import '../models/android_config.dart';
import '../models/ios_config.dart';
import 'hash_converter.dart';

/// Validates platform-specific configurations at runtime.
class ConfigVerifier {
  const ConfigVerifier._();

  static void verifyAndroid(AndroidRaspConfig config) {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (config.signingCertHashes.isEmpty) {
      throw RaspException.emptySigningHashes();
    }
    for (final hash in config.signingCertHashes) {
      final cleaned = hash.replaceAll(':', '');
      if (!hashConverter.isValidSha256Format(cleaned)) {
        throw RaspException.invalidHashFormat();
      }
    }
  }

  static void verifyIOS(IosRaspConfig config) {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    if (config.teamId.isEmpty) {
      throw RaspException.emptyTeamId();
    }
    if (config.bundleIds.isEmpty) {
      throw RaspException.emptyBundleIds();
    }
  }
}
