import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import '../models/monitor_log.dart';

class MonitorNotifier extends ValueNotifier<List<MonitorLog>> {
  MonitorNotifier() : super(const []);

  static const _maxEntries = 200;

  void addThreat(Threat threat) {
    final entry = MonitorLog.fromMonitor(threat);
    _append(entry);
  }

  void addScanResults(RaspResult result) {
    if (result.threats.isEmpty) {
      _append(MonitorLog.system('Scan completed — no threats evaluated'));
      return;
    }

    for (final entry in result.threats.entries) {
      _append(
        entry.value
            ? MonitorLog.fromScan(entry.key)
            : MonitorLog.safeScan(entry.key),
      );
    }
  }

  void addSystemMessage(String message) {
    _append(MonitorLog.system(message));
  }

  void clear() {
    value = const [];
  }

  void _append(MonitorLog entry) {
    final updated = [...value, entry];
    if (updated.length > _maxEntries) {
      value = updated.sublist(updated.length - _maxEntries);
    } else {
      value = updated;
    }
  }
}
