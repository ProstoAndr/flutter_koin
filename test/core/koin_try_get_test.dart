import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

void main() {
  group('tryGet<T>()', () {
    test('container returns root scoped dependency', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
      );

      final logger = container.tryGet<ApplicationLogger>();

      expect(logger, isNotNull);
      expect(logger, isA<ApplicationLogger>());
    });

    test('container returns root scoped dependency by alias', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
        bindAs: [LoggerContract],
      );

      final logger = container.tryGet<LoggerContract>();

      expect(logger, isNotNull);
      expect(logger, isA<ApplicationLogger>());
    });

    test('container returns factory dependency', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
      );

      final firstFactory = container.tryGet<ReceiptFactory>();
      final secondFactory = container.tryGet<ReceiptFactory>();

      expect(firstFactory, isNotNull);
      expect(secondFactory, isNotNull);
      expect(identical(firstFactory, secondFactory), isFalse);
    });

    test('container returns null for unknown dependency', () {
      final container = KoinContainer();

      final unknownService = container.tryGet<UnknownService>();

      expect(unknownService, isNull);
    });

    test('feature scope returns scoped dependency', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
      );

      final scope = container.createScope('table:7');

      final firstSession = scope.tryGet<TableSession>();
      final secondSession = scope.tryGet<TableSession>();

      expect(firstSession, isNotNull);
      expect(secondSession, isNotNull);
      expect(identical(firstSession, secondSession), isTrue);
    });

    test('feature scope returns scoped dependency by alias', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
        bindAs: [TableSessionContract],
      );

      final scope = container.createScope('table:7');

      final session = scope.tryGet<TableSessionContract>();

      expect(session, isNotNull);
      expect(session, isA<TableSession>());
    });

    test('feature scope falls back to root scoped dependency', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
      );

      final scope = container.createScope('dialog:42');

      final logger = scope.tryGet<ApplicationLogger>();

      expect(logger, isNotNull);
      expect(logger, isA<ApplicationLogger>());
    });

    test('feature scope falls back to factory dependency', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
      );

      final scope = container.createScope('dialog:42');

      final receiptFactory = scope.tryGet<ReceiptFactory>();

      expect(receiptFactory, isNotNull);
      expect(receiptFactory, isA<ReceiptFactory>());
    });

    test('feature scope returns null for unknown dependency', () {
      final container = KoinContainer();
      final scope = container.createScope('dialog:42');

      final unknownService = scope.tryGet<UnknownService>();

      expect(unknownService, isNull);
    });

    test('root scope returns null for feature-scoped-only dependency', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
      );

      final value = container.rootScope.tryGet<TableSession>();

      expect(value, isNull);
    });
  });
}

abstract class LoggerContract {}

class ApplicationLogger implements LoggerContract {}

abstract class TableSessionContract {}

class TableSession implements TableSessionContract {}

class ReceiptFactory {}

class UnknownService {}