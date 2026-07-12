import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:http/io_client.dart';

import '../backend_host.dart';

enum SslPinningStatus { idle, testing, success, warning, failure }

enum SslPinningMode { plainPem, encrypted, download, remote }

class SslPinningNotifier extends ValueNotifier<SslPinningStatus> {
  SslPinningNotifier() : super(SslPinningStatus.idle);

  String? lastError;
  String? lastMessage;
  SslPinningMode? lastMode;

  // The pinned asset is GitHub's root CA (USERTrust ECC, valid to 2038),
  // not the leaf — leaf certs rotate every ~90 days, the root doesn't.
  static const _url = 'https://api.github.com/zen';
  static const _timeout = Duration(seconds: 15);

  // ─── 1. Local, NOT encrypted: plain .pem asset, no passphrase ───

  static const _plainConfig = SslPinningConfig(
    certificateAssetPaths: ['assets/certs/api.github.com.pem'],
  );

  // ─── 2. Local, ENCRYPTED: .enc asset + passphrase ───
  // Generated with the Certificate Encryptor web tool.

  static const _encryptedConfig = SslPinningConfig(
    certificateAssetPaths: ['assets/certs/api.github.com.enc'],
    passphrase: 'flutter_rasp',
  );

  // ─── 3. Remote: downloaded from your endpoint ───
  // The mock backend serves the encrypted certificate at /cert.enc.
  // Point this at your own CDN / API endpoint in production.

  static final _remoteConfig = RemoteCertificateConfig(
    url: Uri.parse('http://$backendHost:8787/cert.enc'),
    passphrase: 'flutter_rasp',
  );

  // ─── Local, NOT encrypted (.pem) ───

  Future<void> testPlainDartIo() =>
      _testDartIo(_plainConfig, SslPinningMode.plainPem);

  Future<void> testPlainDio() => _testDio(_plainConfig, SslPinningMode.plainPem);

  Future<void> testPlainHttp() =>
      _testHttp(_plainConfig, SslPinningMode.plainPem);

  // ─── Local, ENCRYPTED (.enc + passphrase) ───

  Future<void> testEncryptedDartIo() =>
      _testDartIo(_encryptedConfig, SslPinningMode.encrypted);

  Future<void> testEncryptedDio() =>
      _testDio(_encryptedConfig, SslPinningMode.encrypted);

  Future<void> testEncryptedHttp() =>
      _testHttp(_encryptedConfig, SslPinningMode.encrypted);

  // ─── Remote certificate ───

  /// Downloads the certificate from the endpoint, always replacing the
  /// stored copy. After this, [testRemote] works synchronously.
  Future<void> downloadCertificate() async {
    _start(SslPinningMode.download);
    try {
      final downloaded = await SslPinningClient.downloadCertificate(
        _remoteConfig,
      );
      lastMessage = downloaded
          ? 'Downloaded — stored copy replaced'
          : 'Offline — restored stored copy';
      value = SslPinningStatus.success;
    } catch (e) {
      _fail(e);
    }
  }

  /// Uses the previously downloaded certificate — the pinned client is
  /// built synchronously, no await needed.
  Future<void> testRemote() async {
    _start(SslPinningMode.remote);
    try {
      final client = SslPinningClient.createRemoteHttpClient(_remoteConfig);
      await _request(client);
    } catch (e) {
      _fail(e);
    }
  }

  void reset() {
    lastError = null;
    lastMessage = null;
    lastMode = null;
    value = SslPinningStatus.idle;
  }

  Future<void> _testDartIo(SslPinningConfig config, SslPinningMode mode) async {
    _start(mode);
    try {
      final client = await SslPinningClient.createHttpClient(config);
      await _request(client);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _testDio(SslPinningConfig config, SslPinningMode mode) async {
    _start(mode);
    Dio? dio;
    try {
      final client = await SslPinningClient.createHttpClient(config);
      dio = Dio()
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => client,
        );
      // Let non-2xx statuses reach _finish instead of throwing, matching
      // the dart:io and http flows.
      final response = await dio
          .get(_url, options: Options(validateStatus: (_) => true))
          .timeout(_timeout);
      _finish(response.statusCode ?? 0);
    } catch (e) {
      _fail(e);
    } finally {
      dio?.close();
    }
  }

  Future<void> _testHttp(SslPinningConfig config, SslPinningMode mode) async {
    _start(mode);
    IOClient? httpClient;
    try {
      final client = await SslPinningClient.createHttpClient(config);
      httpClient = IOClient(client);
      final response = await httpClient.get(Uri.parse(_url)).timeout(_timeout);
      _finish(response.statusCode);
    } catch (e) {
      _fail(e);
    } finally {
      httpClient?.close();
    }
  }

  Future<void> _request(HttpClient client) async {
    try {
      final request = await client.getUrl(Uri.parse(_url)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      await response.transform(utf8.decoder).join().timeout(_timeout);
      _finish(response.statusCode);
    } finally {
      client.close();
    }
  }

  void _start(SslPinningMode mode) {
    value = SslPinningStatus.testing;
    lastError = null;
    lastMessage = null;
    lastMode = mode;
  }

  void _finish(int statusCode) {
    // Any HTTP response proves the pinned TLS handshake succeeded —
    // a pin mismatch would have thrown a HandshakeException instead.
    // Non-2xx still means the server itself had a problem.
    final ok = statusCode >= 200 && statusCode < 300;
    lastMessage = ok
        ? 'Pinned TLS OK — HTTP $statusCode'
        : 'Pin OK, but server returned HTTP $statusCode';
    value = ok ? SslPinningStatus.success : SslPinningStatus.warning;
  }

  void _fail(Object e) {
    final cause = e is DioException ? (e.error ?? e) : e;
    lastError = switch (cause) {
      TlsException _ => 'Pin mismatch: $cause',
      TimeoutException _ || SocketException _ =>
        'Network issue (not a pin failure): $cause',
      _ => cause.toString(),
    };
    value = SslPinningStatus.failure;
  }
}
