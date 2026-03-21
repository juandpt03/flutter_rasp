import 'package:flutter/material.dart';

import '../../notifiers/ssl_pinning_notifier.dart';

class SslPinningSection extends StatelessWidget {
  const SslPinningSection({required this.notifier, super.key});

  final SslPinningNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SslPinningStatus>(
      valueListenable: notifier,
      builder: (context, status, _) {
        final (color, icon, subtitle) = switch (status) {
          SslPinningStatus.idle => (
            const Color(0xFF64B5F6),
            Icons.lock_outline,
            'Tap a mode to test',
          ),
          SslPinningStatus.testing => (
            const Color(0xFFFFB74D),
            Icons.sync,
            'Testing ${notifier.lastMode?.label ?? ''}...',
          ),
          SslPinningStatus.success => (
            const Color(0xFF00E676),
            Icons.lock,
            '${notifier.lastMode?.label ?? ''} — secure',
          ),
          SslPinningStatus.failure => (
            const Color(0xFFEF5350),
            Icons.lock_open,
            notifier.lastError ?? 'Pin mismatch',
          ),
        };

        final isTesting = status == SslPinningStatus.testing;

        return GestureDetector(
          onLongPress: notifier.reset,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'SSL PINNING',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: color.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ClientButton(
                      label: 'dart:io',
                      color: color,
                      onTap: isTesting ? null : notifier.testWithDartIo,
                    ),
                    _ClientButton(
                      label: 'Dio',
                      color: color,
                      onTap: isTesting ? null : notifier.testWithDio,
                    ),
                    _ClientButton(
                      label: 'http',
                      color: color,
                      onTap: isTesting ? null : notifier.testWithHttp,
                    ),
                    _ClientButton(
                      label: 'Encrypted',
                      color: color,
                      onTap: isTesting ? null : notifier.testWithEncrypted,
                    ),
                    _ClientButton(
                      label: 'Remote',
                      color: color,
                      onTap: isTesting ? null : notifier.testWithRemote,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClientButton extends StatelessWidget {
  const _ClientButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

extension on SslPinningMode {
  String get label => switch (this) {
    SslPinningMode.plainPem => 'Plain PEM',
    SslPinningMode.encrypted => 'Encrypted',
    SslPinningMode.remote => 'Remote fallback',
  };
}
