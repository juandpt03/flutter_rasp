import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import 'monitor_notifier.dart';

class RaspReporterState {
  const RaspReporterState({this.lastReportSummary});

  final String? lastReportSummary;
}

class RaspReporterNotifier extends ValueNotifier<RaspReporterState> {
  RaspReporterNotifier({this.monitor}) : super(const RaspReporterState());

  final MonitorNotifier? monitor;

  Future<void> forceDartError() async {
    monitor?.addSystemMessage('Forcing manual Dart error...');
    try {
      throw StateError('Simulated crash from example app');
    } catch (e, st) {
      await RaspReporter.instance.captureException(
        e,
        stackTrace: st,
        hint: 'simulated:button-press',
      );
    }
    _updateSummary('Sent manual error');
  }

  Future<void> flushNow() async {
    monitor?.addSystemMessage('Flushing pending reports...');
    await RaspReporter.instance.flushPending();
    _updateSummary('Flush requested');
  }

  void _updateSummary(String message) {
    value = RaspReporterState(lastReportSummary: message);
  }
}
