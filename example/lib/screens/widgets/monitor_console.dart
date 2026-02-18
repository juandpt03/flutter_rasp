import 'package:flutter/material.dart';

import '../../models/monitor_log.dart';
import '../../notifiers/monitor_notifier.dart';

class MonitorConsole extends StatefulWidget {
  const MonitorConsole({required this.notifier, super.key});

  final MonitorNotifier notifier;

  @override
  State<MonitorConsole> createState() => _MonitorConsoleState();
}

class _MonitorConsoleState extends State<MonitorConsole> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: const Color(0xFF16213E), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ConsoleHeader(
            notifier: widget.notifier,
            autoScroll: _autoScroll,
            onToggleAutoScroll: () {
              setState(() => _autoScroll = !_autoScroll);
            },
          ),
          Expanded(
            child: ValueListenableBuilder<List<MonitorLog>>(
              valueListenable: widget.notifier,
              builder: (context, logs, _) {
                if (logs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Waiting for events...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFF4A5568),
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) => _LogLine(log: logs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({
    required this.notifier,
    required this.autoScroll,
    required this.onToggleAutoScroll,
  });

  final MonitorNotifier notifier;
  final bool autoScroll;
  final VoidCallback onToggleAutoScroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'RASP Monitor',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF00E676),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<List<MonitorLog>>(
            valueListenable: notifier,
            builder: (context, logs, _) {
              final threatCount = logs
                  .where(
                    (l) =>
                        l.source == LogSource.monitor ||
                        l.source == LogSource.scan,
                  )
                  .length;
              return Text(
                '$threatCount events',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF4A5568),
                  fontSize: 10,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggleAutoScroll,
            child: Icon(
              autoScroll ? Icons.vertical_align_bottom : Icons.pause,
              color: autoScroll
                  ? const Color(0xFF00E676)
                  : const Color(0xFF4A5568),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: notifier.clear,
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFF4A5568),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.log});

  final MonitorLog log;

  @override
  Widget build(BuildContext context) {
    final Color tagColor;
    final Color messageColor;

    switch (log.source) {
      case LogSource.monitor:
        tagColor = const Color(0xFFFF6B6B);
        messageColor = const Color(0xFFFF8A80);
      case LogSource.scan:
        tagColor = const Color(0xFF64B5F6);
        messageColor = const Color(0xFF90CAF9);
      case LogSource.safeScan:
        tagColor = const Color(0xFF00E676);
        messageColor = const Color(0xFF69F0AE);
      case LogSource.system:
        tagColor = const Color(0xFF4A5568);
        messageColor = const Color(0xFF718096);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '[${log.timeFormatted}] ',
              style: const TextStyle(color: Color(0xFF4A5568)),
            ),
            TextSpan(
              text: '[${log.sourceTag}] ',
              style: TextStyle(color: tagColor, fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: log.label,
              style: TextStyle(color: messageColor),
            ),
          ],
        ),
      ),
    );
  }
}
