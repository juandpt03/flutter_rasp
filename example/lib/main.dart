import 'package:flutter/material.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import 'notifiers/notifiers.dart';
import 'screens/screens.dart';

final monitorNotifier = MonitorNotifier();
final raspNotifier = RaspNotifier(monitor: monitorNotifier);
final screenCaptureNotifier = ScreenCaptureNotifier();
final sslPinningNotifier = SslPinningNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterRasp.instance.initialize(
    config: const RaspConfig(
      policy: ThreatPolicy.none,
      monitoringInterval: Duration(seconds: 5),
      androidConfig: AndroidRaspConfig(
        signingCertHashes: ['00:AA:11:BB:22:CC:33:DD:44:EE:55:FF:66:AA:77:BB:88:CC:99:DD:00:11:FF:22:AA:33:BB:44:CC:55:DD:66'],
      ),
      iosConfig: IosRaspConfig(
        teamId: 'A1B2C3D4E5',
        bundleIds: ['com.example.flutterRaspExample'],
      ),
    ),
    onThreatDetected: raspNotifier.updateThreats,
  );

  monitorNotifier.addSystemMessage('RASP initialized \u2014 monitoring active');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter RASP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      home: const HomePage(),
    );
  }
}
