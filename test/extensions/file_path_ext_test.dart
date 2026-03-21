import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/src/extensions/file_path_ext.dart';

void main() {
  group('FilePathExt', () {
    group('fileExtension', () {
      test('returns .pem', () {
        expect('assets/certs/api.pem'.fileExtension, '.pem');
      });

      test('returns .enc', () {
        expect('cert.enc'.fileExtension, '.enc');
      });

      test('returns empty for no extension', () {
        expect('certificate'.fileExtension, '');
      });

      test('returns last extension for multiple dots', () {
        expect('cert.backup.pem'.fileExtension, '.pem');
      });

      test('lowercases extension', () {
        expect('cert.PEM'.fileExtension, '.pem');
        expect('cert.ENC'.fileExtension, '.enc');
      });
    });

    group('isPlainCertificate', () {
      test('true for .pem', () {
        expect('api.pem'.isPlainCertificate, isTrue);
      });

      test('true for .crt', () {
        expect('api.crt'.isPlainCertificate, isTrue);
      });

      test('true for .cer', () {
        expect('api.cer'.isPlainCertificate, isTrue);
      });

      test('false for .enc', () {
        expect('api.enc'.isPlainCertificate, isFalse);
      });

      test('false for unknown', () {
        expect('api.bin'.isPlainCertificate, isFalse);
      });
    });

    group('isEncryptedCertificate', () {
      test('true for .enc', () {
        expect('api.enc'.isEncryptedCertificate, isTrue);
      });

      test('false for .pem', () {
        expect('api.pem'.isEncryptedCertificate, isFalse);
      });
    });
  });
}
