import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import '../../notifiers/rasp_notifier.dart';

class ThreatStatusBar extends StatelessWidget {
  const ThreatStatusBar({required this.notifier, super.key});

  final RaspNotifier notifier;

  static final List<Threat> _threats = [
    Threat.root,
    Threat.emulator,
    Threat.debug,
    Threat.hook,
    Threat.repackaging,
    Threat.trustedInstall,
    Threat.vpn,
    if (Platform.isAndroid) Threat.developerMode,
    if (Platform.isAndroid) Threat.adbEnabled,
    Threat.devicePasscode,
    Threat.secureHardwareNotAvailable,
    if (Platform.isAndroid) Threat.obfuscationIssues,
    if (Platform.isAndroid) Threat.timeSpoofing,
    if (Platform.isAndroid) Threat.locationSpoofing,
    if (Platform.isAndroid) Threat.multiInstance,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RaspState>(
      valueListenable: notifier,
      builder: (context, state, _) {
        final detectedCount = _threats.where((t) {
          return state.detectedThreats.contains(t) ||
              (state.scanResult?.threats[t] ?? false);
        }).length;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2A2A4A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                hasScanned:
                    state.scanResult != null ||
                    state.detectedThreats.isNotEmpty,
                detectedCount: detectedCount,
                total: _threats.length,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _threats.map((threat) {
                  final status = _resolveStatus(threat, state);
                  return Tooltip(
                    message: _threatDescription(threat),
                    preferBelow: true,
                    triggerMode: TooltipTriggerMode.tap,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2A2A4A),
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFE0E0E0),
                      fontSize: 11,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _ThreatCell(
                      label: _shortLabel(threat),
                      icon: _threatIcon(threat),
                      status: status,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  _CellStatus _resolveStatus(Threat threat, RaspState state) {
    final fromMonitor = state.detectedThreats.contains(threat);
    final fromScan = state.scanResult?.threats[threat] ?? false;

    if (fromMonitor || fromScan) return _CellStatus.detected;

    if (state.scanResult != null) return _CellStatus.safe;

    return _CellStatus.unscanned;
  }

  String _shortLabel(Threat threat) {
    return switch (threat) {
      Threat.root => 'ROOT',
      Threat.emulator => 'EMU',
      Threat.debug => 'DBG',
      Threat.hook => 'HOOK',
      Threat.repackaging => 'RPKG',
      Threat.trustedInstall => 'INST',
      Threat.vpn => 'VPN',
      Threat.developerMode => 'DEV',
      Threat.adbEnabled => 'ADB',
      Threat.devicePasscode => 'PASS',
      Threat.secureHardwareNotAvailable => 'HW',
      Threat.obfuscationIssues => 'OBF',
      Threat.timeSpoofing => 'TIME',
      Threat.locationSpoofing => 'LOC',
      Threat.multiInstance => 'MULTI',
      Threat.undefined => '???',
    };
  }

  IconData _threatIcon(Threat threat) {
    return switch (threat) {
      Threat.root => Icons.key,
      Threat.emulator => Icons.computer,
      Threat.debug => Icons.bug_report,
      Threat.hook => Icons.phishing,
      Threat.repackaging => Icons.fingerprint,
      Threat.trustedInstall => Icons.store,
      Threat.vpn => Icons.vpn_lock,
      Threat.developerMode => Icons.developer_mode,
      Threat.adbEnabled => Icons.usb,
      Threat.devicePasscode => Icons.lock_open,
      Threat.secureHardwareNotAvailable => Icons.memory,
      Threat.obfuscationIssues => Icons.visibility_off,
      Threat.timeSpoofing => Icons.schedule,
      Threat.locationSpoofing => Icons.location_off,
      Threat.multiInstance => Icons.content_copy,
      Threat.undefined => Icons.help_outline,
    };
  }

  String _threatDescription(Threat threat) {
    return switch (threat) {
      Threat.root => 'Root / Jailbreak detected',
      Threat.emulator => 'Running on emulator / simulator',
      Threat.debug => 'Debugger attached',
      Threat.hook => 'Frida / Xposed / Cycript hooks',
      Threat.repackaging => 'Invalid signing certificate',
      Threat.trustedInstall => 'Sideloaded / untrusted source',
      Threat.vpn => 'VPN connection active',
      Threat.developerMode => 'Developer options enabled',
      Threat.adbEnabled => 'ADB debugging enabled',
      Threat.devicePasscode => 'No screen lock configured',
      Threat.secureHardwareNotAvailable => 'No TEE / Secure Enclave',
      Threat.obfuscationIssues => 'Unobfuscated binary detected',
      Threat.timeSpoofing => 'Auto time sync disabled',
      Threat.locationSpoofing => 'Mock location detected',
      Threat.multiInstance => 'Cloned / dual-app environment',
      Threat.undefined => 'Unknown threat',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.hasScanned,
    required this.detectedCount,
    required this.total,
  });

  final bool hasScanned;
  final int detectedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.grid_view_rounded, color: Color(0xFF4A5568), size: 12),
        const SizedBox(width: 6),
        const Text(
          'THREAT STATUS',
          style: TextStyle(
            fontFamily: 'monospace',
            color: Color(0xFF4A5568),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        if (hasScanned)
          Text(
            '$detectedCount/$total',
            style: TextStyle(
              fontFamily: 'monospace',
              color: detectedCount > 0
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF00E676),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          const Text(
            'NOT SCANNED',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF4A5568),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

enum _CellStatus { safe, detected, unscanned }

class _ThreatCell extends StatelessWidget {
  const _ThreatCell({
    required this.label,
    required this.icon,
    required this.status,
  });

  final String label;
  final IconData icon;
  final _CellStatus status;

  Color get _dotColor => switch (status) {
    _CellStatus.safe => const Color(0xFF00E676),
    _CellStatus.detected => const Color(0xFFFF6B6B),
    _CellStatus.unscanned => const Color(0xFF4A5568),
  };

  Color get _bgColor => switch (status) {
    _CellStatus.safe => const Color(0xFF00E676).withValues(alpha: 0.08),
    _CellStatus.detected => const Color(0xFFFF6B6B).withValues(alpha: 0.12),
    _CellStatus.unscanned => Colors.transparent,
  };

  Color get _borderColor => switch (status) {
    _CellStatus.safe => const Color(0xFF00E676).withValues(alpha: 0.2),
    _CellStatus.detected => const Color(0xFFFF6B6B).withValues(alpha: 0.3),
    _CellStatus.unscanned => const Color(0xFF2A2A4A),
  };

  Color get _textColor => switch (status) {
    _CellStatus.safe => const Color(0xFF00E676),
    _CellStatus.detected => const Color(0xFFFF8A80),
    _CellStatus.unscanned => const Color(0xFF4A5568),
  };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 12, color: _textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
