import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('has / hasByType', () {
    test('Root sees RootScoped and Factory, but not Scoped', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<AppLogger>(() => AppLogger());
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory(1));
      container.registerScoped<TableSession>(() => TableSession(1));

      expect(container.rootScope.has<AppLogger>(), isTrue);
      expect(container.rootScope.has<ReceiptFactory>(), isTrue);
      expect(container.rootScope.has<TableSession>(), isFalse);
    });

    test('Feature sees its Scoped, RootScoped and Factory dependencies', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<AppLogger>(() => AppLogger());
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory(1));
      container.registerScoped<TableSession>(() => TableSession(1));
      final scope = container.createScope('feature');

      expect(scope.has<AppLogger>(), isTrue);
      expect(scope.has<ReceiptFactory>(), isTrue);
      expect(scope.has<TableSession>(), isTrue);
    });

    test('has recognizes bindAs aliases', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<CoffeeShopInfo>(
        () => CoffeeShopInfo(1),
        bindAs: [ShopInfoRepository],
      );
      container.registerScoped<TableSession>(
        () => TableSession(1),
        bindAs: [TableSessionContract],
      );
      final scope = container.createScope('feature');

      expect(container.rootScope.has<ShopInfoRepository>(), isTrue);
      expect(container.rootScope.has<TableSessionContract>(), isFalse);
      expect(scope.has<ShopInfoRepository>(), isTrue);
      expect(scope.has<TableSessionContract>(), isTrue);
      expect(scope.hasByType(TableSessionContract), isTrue);
    });

    test('has returns false for missing dependencies', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final scope = container.createScope('feature');

      expect(container.rootScope.has<MissingDependency>(), isFalse);
      expect(scope.has<MissingDependency>(), isFalse);
      expect(scope.hasByType(MissingDependency), isFalse);
    });
  });
}
