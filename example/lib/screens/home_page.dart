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
            DashboardHeader(policy: rasp.policy),
            ScreenCaptureSection(notifier: screenCapture),
            SslPinningSection(notifier: sslPinning),
            RaspReporterSection(notifier: reporter),
            ControlStrip(notifier: rasp),
            ThreatStatusBar(notifier: rasp),
            Expanded(child: MonitorConsole(notifier: monitor)),
          ],
        ),
      ),
    );
  }
}
