import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Self-signed EC test certificate (valid 10 years).
  const testPem =
      '-----BEGIN CERTIFICATE-----\n'
      'MIIBizCCATGgAwIBAgIUV/NpLEzef0cEYN2As8oKdXoIcn0wCgYIKoZIzj0EAwIw\n'
      'GzEZMBcGA1UEAwwQdGVzdC5leGFtcGxlLmNvbTAeFw0yNjAyMTkwNDUyMTFaFw0z\n'
      'NjAyMTcwNDUyMTFaMBsxGTAXBgNVBAMMEHRlc3QuZXhhbXBsZS5jb20wWTATBgcq\n'
      'hkjOPQIBBggqhkjOPQMBBwNCAAQT8ZkJLGvyymRNo3tcGDwXYK7rD4ML10KMspNm\n'
      's2mdRcLPAoH07+YKThVBOhCoeLQzfclv9bDNQdpHhxWE9rIHo1MwUTAdBgNVHQ4E\n'
      'FgQU40lSXn5FsNdsGdcFIxBA0gQeCJMwHwYDVR0jBBgwFoAU40lSXn5FsNdsGdcF\n'
      'IxBA0gQeCJMwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiBbUSrZ\n'
      'WSkFH0rvuNg07+0YpxUiFMVSPUU6J3pYzTPnUgIhAI1CKpVEzFWxDonaskKSYuFm\n'
      'm3Vc6EX0lhszLLtSebz8\n'
      '-----END CERTIFICATE-----';

  final pemBytes = Uint8List.fromList(utf8.encode(testPem));
  // Same certificate with a trailing newline: different bytes, still valid.
  final updatedPemBytes = Uint8List.fromList(utf8.encode('$testPem\n'));

  final config = RemoteCertificateConfig(
    url: Uri.parse('https://cdn.example.com/cert.pem'),
  );

  late _FakeSecureStorage fakeStorage;

  setUp(() {
    fakeStorage = _FakeSecureStorage();
    CertificateStore.storage = fakeStorage;
    SslPinningClient.invalidateCache();
    SslPinningClient.debugFetchOverride = null;
  });

  tearDown(() {
    CertificateStore.resetStorage();
    SslPinningClient.invalidateCache();
    SslPinningClient.debugFetchOverride = null;
  });

  group('RemoteCertificateConfig', () {
    test('validate() rejects non-http(s) url', () {
      final bad = RemoteCertificateConfig(url: Uri.parse('ftp://x/cert.pem'));
      expect(bad.validate, throwsArgumentError);
    });

    test('validate() rejects non-positive timeout', () {
      final bad = RemoteCertificateConfig(
        url: Uri.parse('https://x/cert.pem'),
        timeout: Duration.zero,
      );
      expect(bad.validate, throwsArgumentError);
    });

    test('validate() rejects empty passphrase', () {
      final bad = RemoteCertificateConfig(
        url: Uri.parse('https://x/cert.enc'),
        passphrase: ' ',
      );
      expect(bad.validate, throwsArgumentError);
    });

    test('validate() rejects .enc endpoint without passphrase', () {
      final bad = RemoteCertificateConfig(url: Uri.parse('https://x/cert.enc'));
      expect(bad.validate, throwsArgumentError);
    });

    test('validate() rejects passphrase with a plain endpoint', () {
      final bad = RemoteCertificateConfig(
        url: Uri.parse('https://x/cert.pem'),
        passphrase: 'secret',
      );
      expect(bad.validate, throwsArgumentError);
    });

    test('validate() accepts extensionless endpoint with any mode', () {
      final plain = RemoteCertificateConfig(url: Uri.parse('https://x/cert'));
      final encrypted = RemoteCertificateConfig(
        url: Uri.parse('https://x/cert'),
        passphrase: 'secret',
      );
      expect(plain.validate, returnsNormally);
      expect(encrypted.validate, returnsNormally);
    });
  });

  group('SslPinningClient remote flow', () {
    test('createRemoteContext() throws before downloadCertificate()', () {
      expect(
        () => SslPinningClient.createRemoteContext(config),
        throwsA(
          isA<RaspException>().having(
            (e) => e.errorCode,
            'errorCode',
            RaspErrorCode.noCertificateAvailable,
          ),
        ),
      );
    });

    test('downloadCertificate() stores cert and enables sync access', () async {
      SslPinningClient.debugFetchOverride = (_) async => pemBytes;

      final downloaded = await SslPinningClient.downloadCertificate(config);

      expect(downloaded, isTrue);
      expect(
        SslPinningClient.createRemoteContext(config),
        isA<SecurityContext>(),
      );
      expect(
        SslPinningClient.createRemoteHttpClient(config),
        isA<HttpClient>(),
      );
      expect(SslPinningClient.cachedRemotePem(config), pemBytes);
      expect(fakeStorage.values, hasLength(1));
    });

    test('downloadCertificate() always replaces the stored copy', () async {
      SslPinningClient.debugFetchOverride = (_) async => pemBytes;
      await SslPinningClient.downloadCertificate(config);
      final firstStored = fakeStorage.values.values.single;

      SslPinningClient.debugFetchOverride = (_) async => updatedPemBytes;
      final downloaded = await SslPinningClient.downloadCertificate(config);

      expect(downloaded, isTrue);
      expect(fakeStorage.values.values.single, isNot(firstStored));
      expect(SslPinningClient.cachedRemotePem(config), updatedPemBytes);
    });

    test('download failure falls back to the stored copy', () async {
      SslPinningClient.debugFetchOverride = (_) async => pemBytes;
      await SslPinningClient.downloadCertificate(config);

      // Simulate a restart: memory gone, storage kept.
      SslPinningClient.invalidateCache();
      SslPinningClient.debugFetchOverride = (_) async =>
          throw const SocketException('offline');

      final downloaded = await SslPinningClient.downloadCertificate(config);

      expect(downloaded, isFalse);
      expect(
        SslPinningClient.createRemoteContext(config),
        isA<SecurityContext>(),
      );
    });

    test('download failure with nothing stored throws', () async {
      SslPinningClient.debugFetchOverride = (_) async =>
          throw const SocketException('offline');

      expect(
        SslPinningClient.downloadCertificate(config),
        throwsA(
          isA<RaspException>().having(
            (e) => e.errorCode,
            'errorCode',
            RaspErrorCode.certificateDownloadFailed,
          ),
        ),
      );
    });

    test('downloadCertificate() rejects invalid certificate bytes', () async {
      SslPinningClient.debugFetchOverride = (_) async =>
          Uint8List.fromList(utf8.encode('not a cert'));

      expect(
        SslPinningClient.downloadCertificate(config),
        throwsA(
          isA<RaspException>().having(
            (e) => e.errorCode,
            'errorCode',
            RaspErrorCode.certificateDownloadFailed,
          ),
        ),
      );
    });

    test('clearRemoteCertificate() removes stored and cached copies', () async {
      SslPinningClient.debugFetchOverride = (_) async => pemBytes;
      await SslPinningClient.downloadCertificate(config);

      await SslPinningClient.clearRemoteCertificate(config);

      expect(fakeStorage.values, isEmpty);
      expect(SslPinningClient.cachedRemotePem(config), isNull);
      expect(
        () => SslPinningClient.createRemoteContext(config),
        throwsA(isA<RaspException>()),
      );
    });
  });
}

/// In-memory [FlutterSecureStorage] fake.
class _FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
