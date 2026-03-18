import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

void main() {
  group('has<T>()', () {
    test('container has root scoped dependency by concrete type', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
      );

      expect(container.has<ApplicationLogger>(), isTrue);
    });

    test('container has root scoped dependency by alias type', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
        bindAs: [LoggerContract],
      );

      expect(container.has<LoggerContract>(), isTrue);
      expect(container.has<ApplicationLogger>(), isTrue);
    });

    test('container has factory dependency by concrete type', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
      );

      expect(container.has<ReceiptFactory>(), isTrue);
    });

    test('container has factory dependency by alias type', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
        bindAs: [ReceiptGenerator],
      );

      expect(container.has<ReceiptFactory>(), isTrue);
      expect(container.has<ReceiptGenerator>(), isTrue);
    });

    test('container has scoped dependency by concrete type', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
      );

      expect(container.has<TableSession>(), isTrue);
    });

    test('container has scoped dependency by alias type', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
        bindAs: [TableSessionContract],
      );

      expect(container.has<TableSession>(), isTrue);
      expect(container.has<TableSessionContract>(), isTrue);
    });

    test('container returns false for unknown type', () {
      final container = KoinContainer();

      expect(container.has<UnknownService>(), isFalse);
    });

    test('feature scope sees its own scoped dependency', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
      );

      final scope = container.createScope('table:7');

      expect(scope.has<TableSession>(), isTrue);
    });

    test('feature scope sees scoped alias', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(
            () => TableSession(),
        bindAs: [TableSessionContract],
      );

      final scope = container.createScope('table:7');

      expect(scope.has<TableSessionContract>(), isTrue);
      expect(scope.has<TableSession>(), isTrue);
    });

    test('feature scope sees root scoped dependency', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
      );

      final scope = container.createScope('dialog:42');

      expect(scope.has<ApplicationLogger>(), isTrue);
    });

    test('feature scope sees root scoped alias', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
        bindAs: [LoggerContract],
      );

      final scope = container.createScope('dialog:42');

      expect(scope.has<LoggerContract>(), isTrue);
    });

    test('feature scope sees factory dependency', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
      );

      final scope = container.createScope('dialog:42');

      expect(scope.has<ReceiptFactory>(), isTrue);
    });

    test('feature scope sees factory alias', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
        bindAs: [ReceiptGenerator],
      );

      final scope = container.createScope('dialog:42');

      expect(scope.has<ReceiptGenerator>(), isTrue);
    });

    test('feature scope returns false for unknown dependency', () {
      final container = KoinContainer();
      final scope = container.createScope('dialog:42');

      expect(scope.has<UnknownService>(), isFalse);
    });

    test('root scope sees root scoped and factory but not feature scoped only', () {
      final container = KoinContainer();

      container.registerRootScoped<ApplicationLogger>(
            () => ApplicationLogger(),
      );
      container.registerFactory<ReceiptFactory>(
            () => ReceiptFactory(),
      );
      container.registerScoped<TableSession>(
            () => TableSession(),
      );

      final rootScope = container.rootScope;

      expect(rootScope.has<ApplicationLogger>(), isTrue);
      expect(rootScope.has<ReceiptFactory>(), isTrue);
      expect(rootScope.has<TableSession>(), isFalse);
    });
  });
}

abstract class LoggerContract {}

class ApplicationLogger implements LoggerContract {}

abstract class ReceiptGenerator {
  String createReceipt();
}

class ReceiptFactory implements ReceiptGenerator {
  @override
  String createReceipt() => 'receipt';
}

abstract class TableSessionContract {}

class TableSession implements TableSessionContract {}

class UnknownService {}