import 'package:flutter_rasp/flutter_rasp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbLevel', () {
    test('defines the five canonical levels in severity order', () {
      expect(BreadcrumbLevel.values, [
        BreadcrumbLevel.debug,
        BreadcrumbLevel.info,
        BreadcrumbLevel.warning,
        BreadcrumbLevel.error,
        BreadcrumbLevel.fatal,
      ]);
    });

    test('wireName matches the enum name verbatim', () {
      for (final level in BreadcrumbLevel.values) {
        expect(level.wireName, level.name);
      }
    });

    test('fromName resolves every canonical level', () {
      for (final level in BreadcrumbLevel.values) {
        expect(BreadcrumbLevel.fromName(level.name), level);
      }
    });

    test('fromName falls back to info on unknown input', () {
      expect(BreadcrumbLevel.fromName('nope'), BreadcrumbLevel.info);
      expect(BreadcrumbLevel.fromName(''), BreadcrumbLevel.info);
    });
  });
}
