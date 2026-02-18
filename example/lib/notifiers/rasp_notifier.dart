import 'package:flutter/foundation.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import 'monitor_notifier.dart';

class RaspState {
  const RaspState._({required this.detectedThreats, required this.scanResult});

  factory RaspState.initial() =>
      const RaspState._(detectedThreats: {}, scanResult: null);

  final Set<Threat> detectedThreats;
  final RaspResult? scanResult;

  RaspState copyWith({Set<Threat>? detectedThreats, RaspResult? scanResult}) =>
      RaspState._(
        detectedThreats: detectedThreats ?? this.detectedThreats,
        scanResult: scanResult ?? this.scanResult,
      );
}

class RaspNotifier extends ValueNotifier<RaspState> {
  RaspNotifier({this.monitor}) : super(RaspState.initial());

  final MonitorNotifier? monitor;

  void updateThreats(Set<Threat> current) {
    value = value.copyWith(detectedThreats: current);
    for (final threat in current) {
      monitor?.addThreat(threat);
    }
  }

  Future<void> runScan() async {
    monitor?.addSystemMessage('Running full scan...');
    final result = await FlutterRasp.instance.scanAll();
    value = value.copyWith(detectedThreats: const {}, scanResult: result);
    monitor?.addScanResults(result);
  }

  void clearThreats() {
    value = RaspState.initial();
    monitor?.addSystemMessage('State cleared');
  }
}
