import 'package:flutter/material.dart';

import '../main.dart';
import 'widgets/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            ScreenCaptureSection(notifier: screenCaptureNotifier),
            SslPinningSection(notifier: sslPinningNotifier),
            ControlStrip(notifier: raspNotifier),
            ThreatStatusBar(notifier: raspNotifier),
            Expanded(child: MonitorConsole(notifier: monitorNotifier)),
          ],
        ),
      ),
    );
  }
}
