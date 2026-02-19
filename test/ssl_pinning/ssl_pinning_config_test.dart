import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('SslPinningConfig', () {
    test('validate() succeeds with valid asset paths', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/chain.pem'],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with multiple asset paths', () {
      const config = SslPinningConfig(
        certificateAssetPaths: [
          'assets/certs/api_chain.pem',
          'assets/certs/cdn_chain.pem',
        ],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() throws on empty list', () {
      const config = SslPinningConfig(certificateAssetPaths: []);
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on empty path string', () {
      const config = SslPinningConfig(certificateAssetPaths: ['']);
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on whitespace-only path', () {
      const config = SslPinningConfig(certificateAssetPaths: ['   ']);
      expect(() => config.validate(), throwsArgumentError);
    });
  });
}
