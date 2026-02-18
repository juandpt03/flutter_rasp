import 'package:flutter_rasp/flutter_rasp.dart';

class MonitorLog {
  const MonitorLog._({
    required this.threat,
    required this.message,
    required this.timestamp,
    required this.source,
  });

  factory MonitorLog.fromMonitor(Threat threat) => MonitorLog._(
    threat: threat,
    message: null,
    timestamp: DateTime.now(),
    source: LogSource.monitor,
  );

  factory MonitorLog.fromScan(Threat threat) => MonitorLog._(
    threat: threat,
    message: null,
    timestamp: DateTime.now(),
    source: LogSource.scan,
  );

  factory MonitorLog.safeScan(Threat threat) => MonitorLog._(
    threat: threat,
    message: null,
    timestamp: DateTime.now(),
    source: LogSource.safeScan,
  );

  factory MonitorLog.system(String message) => MonitorLog._(
    threat: null,
    message: message,
    timestamp: DateTime.now(),
    source: LogSource.system,
  );

  final Threat? threat;
  final String? message;
  final DateTime timestamp;
  final LogSource source;

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get label {
    if (message != null) return message!;
    if (threat != null) return _threatLabel(threat!);
    return 'SYSTEM';
  }

  static String _threatLabel(Threat threat) {
    return switch (threat) {
      Threat.root => 'ROOT',
      Threat.emulator => 'EMULATOR',
      Threat.debug => 'DEBUG',
      Threat.hook => 'HOOK',
      Threat.repackaging => 'REPACKAGING',
      Threat.trustedInstall => 'TRUSTED_INSTALL',
      Threat.vpn => 'VPN',
      Threat.developerMode => 'DEV_MODE',
      Threat.devicePasscode => 'PASSCODE',
      Threat.secureHardwareNotAvailable => 'SECURE_HW',
      Threat.obfuscationIssues => 'OBFUSCATION',
      Threat.timeSpoofing => 'TIME_SPOOF',
      Threat.locationSpoofing => 'LOC_SPOOF',
      Threat.multiInstance => 'MULTI_INSTANCE',
      Threat.undefined => 'UNKNOWN',
    };
  }

  String get sourceTag {
    switch (source) {
      case LogSource.monitor:
        return 'MONITOR';
      case LogSource.scan:
        return 'SCAN';
      case LogSource.safeScan:
        return 'SAFE';
      case LogSource.system:
        return 'SYS';
    }
  }
}

enum LogSource { monitor, scan, safeScan, system }
