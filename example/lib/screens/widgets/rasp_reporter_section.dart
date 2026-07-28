import 'package:flutter/material.dart';

import '../../notifiers/rasp_reporter_notifier.dart';

class RaspReporterSection extends StatelessWidget {
  const RaspReporterSection({required this.notifier, super.key});

  final RaspReporterNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RaspReporterState>(
      valueListenable: notifier,
      builder: (context, state, _) {
        const accent = Color(0xFF7C4DFF);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SECURITY REPORTER',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              if (state.lastReportSummary != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.lastReportSummary!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: accent.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _ActionChip(
                    label: 'Force Dart error',
                    color: accent,
                    onTap: notifier.forceDartError,
                  ),
                  _ActionChip(
                    label: 'Flush pending',
                    color: accent,
                    onTap: notifier.flushNow,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async => onTap(),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
