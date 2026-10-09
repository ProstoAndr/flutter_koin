import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('KoinContainer: registration and lifetime', () {
    test('RootScoped returns the same instance', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<AppLogger>(() => AppLogger());

      expect(identical(container.get<AppLogger>(), container.get<AppLogger>()), isTrue);
    });

    test('Factory creates a new instance on each request', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var counter = 0;
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory(++counter));

      final first = container.get<ReceiptFactory>();
      final second = container.get<ReceiptFactory>();

      expect(identical(first, second), isFalse);
      expect([first.id, second.id], [1, 2]);
    });

    test('Scoped caches instances within one feature scope', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var counter = 0;
      container.registerScoped<TableSession>(() => TableSession(++counter));
      final scope = container.createScope('table:1');

      expect(identical(scope.get<TableSession>(), scope.get<TableSession>()), isTrue);
    });

    test('Scoped creates different instances for different scopes', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var counter = 0;
      container.registerScoped<TableSession>(() => TableSession(++counter));

      final first = container.createScope('table:1').get<TableSession>();
      final second = container.createScope('table:2').get<TableSession>();

      expect(identical(first, second), isFalse);
      expect([first.id, second.id], [1, 2]);
    });

    test('Feature scope resolves RootScoped from the root', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<CoffeeShopInfo>(() => CoffeeShopInfo(1));
      final scope = container.createScope('table:1');

      expect(
        identical(scope.get<CoffeeShopInfo>(), container.get<CoffeeShopInfo>()),
        isTrue,
      );
    });

    test('Feature scope can resolve a Factory', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var counter = 0;
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory(++counter));
      final scope = container.createScope('table:1');

      expect(identical(scope.get<ReceiptFactory>(), scope.get<ReceiptFactory>()), isFalse);
    });

    test('Scoped constructor injection resolves aliases in the same scope', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var sessionId = 0;
      var receiptId = 0;

      container.registerRootScoped<CoffeeShopInfo>(
        () => CoffeeShopInfo(1),
        bindAs: [ShopInfoRepository],
      );
      container.registerScoped<TableSession>(
        () => TableSession(++sessionId),
        bindAs: [TableSessionContract],
      );
      container.registerFactory<ReceiptFactory>(
        () => ReceiptFactory(++receiptId),
        bindAs: [ReceiptGenerator],
      );
      container.registerScopedWithScope<TableService>(
        (scope) => TableService(
          scope.get<ShopInfoRepository>(),
          scope.get<TableSessionContract>(),
          receiptGenerator: scope.get<ReceiptGenerator>(),
        ),
      );

      final scope = container.createScope('table:1');
      final service = scope.get<TableService>();

      expect(identical(service, scope.get<TableService>()), isTrue);
      expect(identical(service.shopInfo, container.get<CoffeeShopInfo>()), isTrue);
      expect(identical(service.session, scope.get<TableSession>()), isTrue);
      expect(service.receiptGenerator.id, 1);
    });

    test('loadModule registers its dependencies', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final module = KoinModule()
        ..register((c) => c.registerRootScoped<AppLogger>(() => AppLogger()));

      container.loadModule(module);

      expect(container.get<AppLogger>(), isA<AppLogger>());
    });

    test('deleteScope disposes cached Scoped instances', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(),
      );
      final scope = container.createScope('table:1');
      final resource = scope.get<DisposableScopedResource>();

      await container.deleteScope('table:1');

      expect(resource.disposeCount, 1);
    });

    test('container.dispose disposes cached RootScoped instances', () async {
      final container = KoinContainer();
      container.registerRootScoped<DisposableRootResource>(
        () => DisposableRootResource(),
      );
      final resource = container.get<DisposableRootResource>();

      await container.dispose();

      expect(resource.disposeCount, 1);
    });
  });
}
