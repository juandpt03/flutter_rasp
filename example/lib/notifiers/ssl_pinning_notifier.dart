import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:http/io_client.dart';

enum SslPinningStatus { idle, testing, success, failure }

enum SslPinningMode { plainPem, encrypted, remote }

class SslPinningNotifier extends ValueNotifier<SslPinningStatus> {
  SslPinningNotifier() : super(SslPinningStatus.idle);

  String? lastError;
  SslPinningMode? lastMode;

  static const _url = 'https://httpbin.org/get';
  static const _timeout = Duration(seconds: 10);

  static const _plainConfig = SslPinningConfig(
    certificateAssetPaths: ['assets/certs/httpbin.org.pem'],
  );

  static const _encryptedConfig = SslPinningConfig(
    certificateAssetPaths: ['assets/certs/httpbin.org.enc'],
    passphrase: 'flutter_rasp',
  );


  Future<void> testWithDartIo() async {
    _start(SslPinningMode.plainPem);
    try {
      final client = await SslPinningClient.createHttpClient(_plainConfig);
      await _request(client);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> testWithDio() async {
    _start(SslPinningMode.plainPem);
    try {
      final client = await SslPinningClient.createHttpClient(_plainConfig);
      final dio = Dio()
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => client,
        );
      final response = await dio.get(_url).timeout(_timeout);
      _finish(response.statusCode ?? 0, response.data?.toString() ?? '');
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> testWithHttp() async {
    _start(SslPinningMode.plainPem);
    try {
      final client = await SslPinningClient.createHttpClient(_plainConfig);
      final httpClient = IOClient(client);
      final response = await httpClient.get(Uri.parse(_url)).timeout(_timeout);
      _finish(response.statusCode, response.body);
    } catch (e) {
      _fail(e);
    }
  }


  Future<void> testWithEncrypted() async {
    _start(SslPinningMode.encrypted);
    try {
      final client = await SslPinningClient.createHttpClient(_encryptedConfig);
      await _request(client);
    } catch (e) {
      _fail(e);
    }
  }


  Future<void> testWithRemote() async {
    _start(SslPinningMode.remote);
    try {
      final client = await SslPinningClient.createHttpClient(
        _encryptedConfig,
        onFetchRemote: () async {
          final httpClient = HttpClient()
            ..connectionTimeout = const Duration(seconds: 3);
          try {
            final request = await httpClient
                .getUrl(Uri.parse('https://example.invalid/cert.enc'))
                .timeout(const Duration(seconds: 3));
            final response = await request.close();
            final builder = BytesBuilder();
            await for (final chunk in response) {
              builder.add(chunk);
            }
            return builder.toBytes();
          } catch (_) {
            return null;
          } finally {
            httpClient.close();
          }
        },
      );
      await _request(client);
    } catch (e) {
      _fail(e);
    }
  }

  void reset() {
    lastError = null;
    lastMode = null;
    value = SslPinningStatus.idle;
  }


  Future<void> _request(HttpClient client) async {
    final request = await client.getUrl(Uri.parse(_url)).timeout(_timeout);
    final response = await request.close().timeout(_timeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    _finish(response.statusCode, body);
  }

  void _start(SslPinningMode mode) {
    value = SslPinningStatus.testing;
    lastError = null;
    lastMode = mode;
  }

  void _finish(int statusCode, String body) {
    if (statusCode == 200 && body.isNotEmpty) {
      value = SslPinningStatus.success;
    } else {
      lastError = 'HTTP $statusCode';
      value = SslPinningStatus.failure;
    }
  }

  void _fail(Object e) {
    lastError = e.toString();
    value = SslPinningStatus.failure;
  }
}
