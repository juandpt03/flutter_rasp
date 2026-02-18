import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_rasp/flutter_rasp.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scanAll returns a result', (WidgetTester tester) async {
    await FlutterRasp.instance.initialize(onThreatDetected: (_) {});
    final result = await FlutterRasp.instance.scanAll();
    expect(result.threats.isNotEmpty, true);
  });
}
