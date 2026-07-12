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
            '${notifier.lastMode?.label ?? ''} · '
                '${notifier.lastMessage ?? 'secure'}',
          ),
          SslPinningStatus.warning => (
            const Color(0xFFFFB74D),
            Icons.gpp_maybe,
            '${notifier.lastMode?.label ?? ''} · '
                '${notifier.lastMessage ?? 'Pin OK, server error'}',
          ),
          SslPinningStatus.failure => (
            const Color(0xFFEF5350),
            Icons.lock_open,
            '${notifier.lastMode?.label ?? ''} · '
                '${notifier.lastError ?? 'Pin mismatch'}',
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
                const SizedBox(height: 10),
                _ModeGroup(
                  title: 'LOCAL · PLAIN .PEM (not encrypted)',
                  color: color,
                  buttons: [
                    ('dart:io', notifier.testPlainDartIo),
                    ('Dio', notifier.testPlainDio),
                    ('http', notifier.testPlainHttp),
                  ],
                  enabled: !isTesting,
                ),
                const SizedBox(height: 8),
                _ModeGroup(
                  title: 'LOCAL · ENCRYPTED .ENC (passphrase)',
                  color: color,
                  buttons: [
                    ('dart:io', notifier.testEncryptedDartIo),
                    ('Dio', notifier.testEncryptedDio),
                    ('http', notifier.testEncryptedHttp),
                  ],
                  enabled: !isTesting,
                ),
                const SizedBox(height: 8),
                _ModeGroup(
                  title: 'REMOTE · DOWNLOADED FROM ENDPOINT',
                  color: color,
                  buttons: [
                    ('1. Download', notifier.downloadCertificate),
                    ('2. Use remote', notifier.testRemote),
                  ],
                  enabled: !isTesting,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeGroup extends StatelessWidget {
  const _ModeGroup({
    required this.title,
    required this.color,
    required this.buttons,
    required this.enabled,
  });

  final String title;
  final Color color;
  final List<(String, VoidCallback)> buttons;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'monospace',
            color: color.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, onTap) in buttons)
              _ClientButton(
                label: label,
                color: color,
                onTap: enabled ? onTap : null,
              ),
          ],
        ),
      ],
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
    SslPinningMode.plainPem => 'Plain .pem',
    SslPinningMode.encrypted => 'Encrypted .enc',
    SslPinningMode.download => 'Download',
    SslPinningMode.remote => 'Remote (sync)',
  };
}
