import 'package:flutter/material.dart';
import 'package:flutter_rasp/flutter_rasp.dart';

import 'backend_host.dart';
import 'notifiers/notifiers.dart';
import 'screens/screens.dart';

final MonitorNotifier monitor = MonitorNotifier();
final RaspNotifier rasp = RaspNotifier(monitor: monitor);
final ScreenCaptureNotifier screenCapture = ScreenCaptureNotifier();
final SslPinningNotifier sslPinning = SslPinningNotifier();
final RaspReporterNotifier reporter = RaspReporterNotifier(monitor: monitor);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initSecurity();
    monitor.addSystemMessage('RASP initialized — monitoring active');
  } catch (error, stackTrace) {
    debugPrint('RASP init failed: $error\n$stackTrace');
    runApp(_FatalErrorApp(error: error, stackTrace: stackTrace));
    return;
  }

  runApp(const _ExampleApp());
}

Future<void> _initSecurity() async {
  // 1. SSL pinning is always initialized first.
  await SslPinningClient.createContext(
    const SslPinningConfig(
      certificateAssetPaths: ['assets/certs/api.github.com.enc'],
      passphrase: 'flutter_rasp',
    ),
  );

  // 2. RASP monitoring + reporter. The reporter's `pinnedCertPem` is
  //    optional and omitted here (the local mock backend runs over
  //    plain HTTP).
  await FlutterRasp.instance.initialize(
    config: RaspConfig(
      policy: rasp.policy,
      monitoringInterval: Duration(seconds: 5),
      androidConfig: AndroidRaspConfig(
        signingCertHashes: [
          '00:AA:11:BB:22:CC:33:DD:44:EE:55:FF:66:AA:77:BB'
              ':88:CC:99:DD:00:11:FF:22:AA:33:BB:44:CC:55:DD:66',
        ],
      ),
      iosConfig: IosRaspConfig(
        teamId: 'A1B2C3D4E5',
        bundleIds: ['com.example.flutterRaspExample'],
      ),
    ),
    onThreatDetected: rasp.updateThreats,
    reporter: ReporterConfig(
      endpoint: Uri.parse('http://$backendHost:8787/v1/ingest'),
      headers: const {'X-Project-Id': 'flutter_rasp_example'},
      httpTimeout: const Duration(milliseconds: 1200),
    ),
  );
}

class _ExampleApp extends StatelessWidget {
  const _ExampleApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_rasp · example',
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

class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'flutter_rasp example failed to start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Color(0xFFFF8A80)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      stackTrace.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
