import 'package:flutter/material.dart';

import '../../notifiers/rasp_notifier.dart';

class ControlStrip extends StatelessWidget {
  const ControlStrip({required this.notifier, super.key});

  final RaspNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        children: [
          Expanded(child: _ScanButton(onTap: notifier.runScan)),
          const SizedBox(width: 8),
          _ClearButton(onTap: notifier.clearThreats),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00E676).withValues(alpha: 0.2),
              const Color(0xFF00E676).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.3),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, color: Color(0xFF00E676), size: 16),
              SizedBox(width: 6),
              Text(
                'SCAN ALL',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            'CLR',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF4A5568),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
