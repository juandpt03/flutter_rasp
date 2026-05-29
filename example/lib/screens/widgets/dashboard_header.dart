import 'package:flutter/material.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({required this.policy, super.key});

  final ThreatPolicy policy;

  @override
  Widget build(BuildContext context) {
    final exits = policy.exitThreats.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF00E676), size: 20),
              const SizedBox(width: 10),
              const Text(
                'FLUTTER RASP',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFE0E0E0),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'v6.1',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF7A7A8A),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.3),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(),
                      SizedBox(width: 6),
                      Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              const Text(
                'ACTIVE CONTROLS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFFFFB066),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              if (exits.isEmpty)
                const Text(
                  '∅ report-only',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFF555566),
                    fontSize: 10,
                  ),
                )
              else
                for (final t in exits)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A1A1A).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      t.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFFF7676),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF00E676),
        shape: BoxShape.circle,
      ),
    );
  }
}
