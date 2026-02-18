import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

class ScreenCaptureNotifier extends ValueNotifier<bool> {
  ScreenCaptureNotifier() : super(false);

  Future<void> toggle() async {
    final newValue = !value;
    await FlutterRasp.instance.blockScreenCapture(newValue);
    value = newValue;
  }

  Future<void> sync() async {
    value = await FlutterRasp.instance.isScreenCaptureBlocked();
  }
}
