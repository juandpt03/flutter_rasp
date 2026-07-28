import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SslPinningClient', () {
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

    late _FakeAssetBundle fakeBundle;

    setUp(() {
      fakeBundle = _FakeAssetBundle({'assets/certs/test.pem': testPem});
    });

    test('createContext() returns a SecurityContext with valid PEM', () async {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/test.pem'],
      );
      final context = await SslPinningClient.createContext(
        config,
        bundle: fakeBundle,
      );
      expect(context, isA<SecurityContext>());
    });

    test('createHttpClient() returns an HttpClient', () async {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/test.pem'],
      );
      final client = await SslPinningClient.createHttpClient(
        config,
        bundle: fakeBundle,
      );
      expect(client, isA<HttpClient>());
      client.close();
    });

    test('createContext() throws on empty certificates', () async {
      const config = SslPinningConfig(certificateAssetPaths: []);
      expect(
        () => SslPinningClient.createContext(config, bundle: fakeBundle),
        throwsArgumentError,
      );
    });

    test('createContext() throws on invalid PEM content', () async {
      final badBundle = _FakeAssetBundle({
        'assets/certs/bad.pem':
            '-----BEGIN CERTIFICATE-----\n'
            'not-valid-base64!!!\n'
            '-----END CERTIFICATE-----',
      });
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/bad.pem'],
      );
      expect(
        () => SslPinningClient.createContext(config, bundle: badBundle),
        throwsA(isA<TlsException>()),
      );
    });

    test('createContext() throws on missing asset', () async {
      const config = SslPinningConfig(
        certificateAssetPaths: ['assets/certs/missing.pem'],
      );
      expect(
        SslPinningClient.createContext(config, bundle: fakeBundle),
        throwsA(isA<FlutterError>()),
      );
    });
  });
}

/// Minimal [AssetBundle] fake for unit testing.
class _FakeAssetBundle extends CachingAssetBundle {
  final Map<String, String> _assets;

  _FakeAssetBundle(this._assets);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (!_assets.containsKey(key)) {
      throw FlutterError('Asset not found: $key');
    }
    return _assets[key]!;
  }

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }
}
