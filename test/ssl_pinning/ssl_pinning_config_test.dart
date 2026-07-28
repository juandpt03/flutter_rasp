import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  group('SslPinningConfig', () {
    test('validate() succeeds with .pem path', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/chain.pem'],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with .crt path', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/chain.crt'],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with .cer path', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/chain.cer'],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with multiple plain paths', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.pem', 'assets/certs/cdn.crt'],
      );
      expect(() => config.validate(), returnsNormally);
    });

    test('validate() succeeds with .enc path and passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.enc'],
        passphrase: 'my_secret',
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

    test('validate() throws on empty passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.enc'],
        passphrase: '',
      );
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on whitespace-only passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.enc'],
        passphrase: '   ',
      );
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on .enc without passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.enc'],
      );
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on .pem with passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.pem'],
        passphrase: 'secret',
      );
      expect(() => config.validate(), throwsArgumentError);
    });

    test('validate() throws on unknown extension without passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.bin'],
      );
      expect(() => config.validate(), throwsArgumentError);
    });

    test('isEncrypted returns true with passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.enc'],
        passphrase: 'secret',
      );
      expect(config.isEncrypted, isTrue);
    });

    test('isEncrypted returns false without passphrase', () {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/api.pem'],
      );
      expect(config.isEncrypted, isFalse);
    });
  });
}
