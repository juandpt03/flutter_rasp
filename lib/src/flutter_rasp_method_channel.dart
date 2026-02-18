import 'dart:async';

import 'package:flutter/services.dart';

import 'errors/rasp_exception.dart';
import 'flutter_rasp_platform_interface.dart';
import 'models/rasp_config.dart';

/// MethodChannel-based implementation of [FlutterRaspPlatform].
class MethodChannelFlutterRasp extends FlutterRaspPlatform {
  static const _methodChannel = MethodChannel(
    'com.juandpt/flutter_rasp/methods',
  );
  static const _eventChannel = EventChannel('com.juandpt/flutter_rasp/events');
  static const _timeout = Duration(seconds: 30);

  @override
  Future<void> startMonitoring(RaspConfig config) =>
      _invoke('startMonitoring', config.toMap());

  @override
  Future<void> stopMonitoring() => _invoke('stopMonitoring');

  late final Stream<List<String>> _threatStream = _eventChannel
      .receiveBroadcastStream()
      .map((event) {
        if (event is List) {
          return event.whereType<String>().toList();
        }
        return <String>[];
      });

  @override
  Stream<List<String>> get threatStream => _threatStream;

  @override
  Future<bool> checkThreat(String threatName) async {
    final result = await _invoke<bool>('checkThreat', {
      'threatName': threatName,
    });
    if (result == null) throw RaspException.nullResponse();
    return result;
  }

  @override
  Future<Map<String, bool>> scanAll(List<String> enabledThreats) async {
    final result = await _invoke<Map>('scanAll', {
      'enabledThreats': enabledThreats,
    });
    if (result == null) throw RaspException.nullResponse();
    final map = <String, bool>{};
    for (final entry in result.entries) {
      if (entry.key is String && entry.value is bool) {
        map[entry.key as String] = entry.value as bool;
      }
    }
    return map;
  }

  @override
  Future<void> blockScreenCapture(bool enabled) =>
      _invoke('blockScreenCapture', {'enabled': enabled});

  @override
  Future<bool> isScreenCaptureBlocked() async {
    final result = await _invoke<bool>('isScreenCaptureBlocked');
    if (result == null) throw RaspException.nullResponse();
    return result;
  }

  Future<T?> _invoke<T>(String method, [dynamic arguments]) async {
    try {
      return await _methodChannel
          .invokeMethod<T>(method, arguments)
          .timeout(_timeout);
    } on PlatformException catch (e) {
      throw RaspException.fromPlatform(e);
    } on TimeoutException {
      throw RaspException.timeout();
    }
  }
}
