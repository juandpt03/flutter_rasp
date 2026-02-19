import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:http/io_client.dart';

enum SslPinningStatus { idle, testing, success, failure }

enum HttpClientType { dartIo, dio, http }

class SslPinningNotifier extends ValueNotifier<SslPinningStatus> {
  SslPinningNotifier() : super(SslPinningStatus.idle);

  String? lastError;
  HttpClientType? lastClientType;

  static const _url = 'https://httpbin.org/get';
  static const _timeout = Duration(seconds: 10);
  static const _config = SslPinningConfig(
    certificateAssetPaths: ['assets/certs/httpbin.org.pem'],
  );

  Future<void> testWithDartIo() async {
    _start(HttpClientType.dartIo);
    try {
      final client = await SslPinningClient.createHttpClient(_config);
      final request = await client.getUrl(Uri.parse(_url)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_timeout);

      _finish(response.statusCode, body);
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> testWithDio() async {
    _start(HttpClientType.dio);
    try {
      final client = await SslPinningClient.createHttpClient(_config);
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
    _start(HttpClientType.http);
    try {
      final client = await SslPinningClient.createHttpClient(_config);
      final httpClient = IOClient(client);

      final response = await httpClient.get(Uri.parse(_url)).timeout(_timeout);

      _finish(response.statusCode, response.body);
    } catch (e) {
      _fail(e);
    }
  }

  void reset() {
    lastError = null;
    lastClientType = null;
    value = SslPinningStatus.idle;
  }

  void _start(HttpClientType type) {
    value = SslPinningStatus.testing;
    lastError = null;
    lastClientType = type;
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
