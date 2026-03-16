import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

void main() {
  group('KoinContainer', () {
    test('root scoped returns same instance', () {
      final container = KoinContainer();

      container.registerRootScoped<AppLogger>(() => AppLogger());

      final a = container.get<AppLogger>();
      final b = container.get<AppLogger>();

      expect(identical(a, b), isTrue);
    });

    test('factory returns new instance every time', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(() => ReceiptFactory());

      final a = container.get<ReceiptFactory>();
      final b = container.get<ReceiptFactory>();

      expect(identical(a, b), isFalse);
    });

    test('scoped returns same instance inside one scope', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(() => TableSession());

      final scope = container.createScope('table:1');

      final a = scope.get<TableSession>();
      final b = scope.get<TableSession>();

      expect(identical(a, b), isTrue);
    });

    test('scoped returns different instances across scopes', () {
      final container = KoinContainer();

      container.registerScoped<TableSession>(() => TableSession());

      final scopeA = container.createScope('table:1');
      final scopeB = container.createScope('table:2');

      final a = scopeA.get<TableSession>();
      final b = scopeB.get<TableSession>();

      expect(identical(a, b), isFalse);
    });

    test('feature scope falls back to root scope', () {
      final container = KoinContainer();

      container.registerRootScoped<CoffeeShopInfo>(() => CoffeeShopInfo());

      final scope = container.createScope('table:1');

      final fromScope = scope.get<CoffeeShopInfo>();
      final fromRoot = container.get<CoffeeShopInfo>();

      expect(identical(fromScope, fromRoot), isTrue);
    });

    test('feature scope falls back to factory', () {
      final container = KoinContainer();

      container.registerFactory<ReceiptFactory>(() => ReceiptFactory());

      final scope = container.createScope('table:1');

      final a = scope.get<ReceiptFactory>();
      final b = scope.get<ReceiptFactory>();

      expect(identical(a, b), isFalse);
    });

    test('scoped can depend on scoped via registerScopedWithScope', () {
      final container = KoinContainer();

      container.registerRootScoped<CoffeeShopInfo>(() => CoffeeShopInfo());
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory());

      container.registerScoped<TableSession>(() => TableSession());

      container.registerScopedWithScope<TableService>(
        (scope) => TableService(
          scope.get<CoffeeShopInfo>(),
          scope.get<TableSession>(),
          receiptFactory: scope.get<ReceiptFactory>(),
        ),
      );

      final scope = container.createScope('table:1');

      final serviceA = scope.get<TableService>();
      final serviceB = scope.get<TableService>();

      expect(identical(serviceA, serviceB), isTrue);
      expect(serviceA.shopInfo.title, 'Aurora Coffee');
      expect(serviceA.session.label.startsWith('session-'), isTrue);
      expect(
        serviceA.receiptFactory.makeReceipt().startsWith('receipt-'),
        isTrue,
      );
    });

    test('deleteScope disposes scoped instances', () async {
      final container = KoinContainer();

      container.registerScoped<DisposableTableSession>(
        () => DisposableTableSession(),
      );

      final scope = container.createScope('table:1');
      final session = scope.get<DisposableTableSession>();

      expect(session.disposed, isFalse);

      await container.deleteScope('table:1');

      expect(session.disposed, isTrue);
    });

    test('dispose disposes root scoped instances', () async {
      final container = KoinContainer();

      container.registerRootScoped<DisposableLogger>(() => DisposableLogger());

      final logger = container.get<DisposableLogger>();
      expect(logger.disposed, isFalse);

      await container.dispose();

      expect(logger.disposed, isTrue);
    });
  });
}

class CoffeeShopInfo {
  CoffeeShopInfo() : id = _Ids.next();

  final int id;

  String get title => 'Aurora Coffee';
}

class ReceiptFactory {
  ReceiptFactory() : id = _Ids.next();

  final int id;

  String makeReceipt() => 'receipt-$id';
}

class TableSession {
  TableSession() : id = _Ids.next();

  final int id;

  String get label => 'session-$id';
}

class TableService {
  TableService(this.shopInfo, this.session, {required this.receiptFactory})
    : id = _Ids.next();

  final int id;
  final CoffeeShopInfo shopInfo;
  final TableSession session;
  final ReceiptFactory receiptFactory;
}

class AppLogger {
  AppLogger() : id = _Ids.next();

  final int id;
}

class DisposableTableSession extends KoinDisposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class DisposableLogger extends KoinDisposable {
  bool disposed = false;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class _Ids {
  static int _value = 0;

  static int next() {
    _value += 1;
    return _value;
  }
}
