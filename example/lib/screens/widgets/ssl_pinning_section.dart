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
        final (color, icon, label, subtitle) = switch (status) {
          SslPinningStatus.idle => (
            const Color(0xFF64B5F6),
            Icons.lock_outline,
            'SSL PINNING',
            'Tap to test connection',
          ),
          SslPinningStatus.testing => (
            const Color(0xFFFFB74D),
            Icons.sync,
            'SSL PINNING',
            'Testing...',
          ),
          SslPinningStatus.success => (
            const Color(0xFF00E676),
            Icons.lock,
            'SSL PINNING',
            'Pin verified — connection secure',
          ),
          SslPinningStatus.failure => (
            const Color(0xFFEF5350),
            Icons.lock_open,
            'SSL PINNING',
            notifier.lastError ?? 'Pin mismatch',
          ),
        };

        return GestureDetector(
          onTap: status == SslPinningStatus.testing ? null : notifier.testPinning,
          onLongPress: notifier.reset,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: color.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    switch (status) {
                      SslPinningStatus.idle => 'TEST',
                      SslPinningStatus.testing => '...',
                      SslPinningStatus.success => 'OK',
                      SslPinningStatus.failure => 'FAIL',
                    },
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
