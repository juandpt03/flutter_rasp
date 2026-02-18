import 'package:flutter/material.dart';

import '../../notifiers/screen_capture_notifier.dart';

class ScreenCaptureSection extends StatelessWidget {
  const ScreenCaptureSection({required this.notifier, super.key});

  final ScreenCaptureNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (context, isBlocked, _) {
        final color = isBlocked
            ? const Color(0xFF00E676)
            : const Color(0xFFFFB74D);

        return GestureDetector(
          onTap: notifier.toggle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  isBlocked ? Icons.shield : Icons.screenshot_monitor,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCREEN CAPTURE',
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
                        isBlocked
                            ? 'Screenshots blocked'
                            : 'Screenshots allowed',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: color.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
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
                    isBlocked ? 'ON' : 'OFF',
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
