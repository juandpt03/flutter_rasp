import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_rasp_example/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('FLUTTER RASP'), findsOneWidget);
    expect(find.text('SCAN ALL'), findsOneWidget);
    expect(find.text('RASP Monitor'), findsOneWidget);
  });
}
