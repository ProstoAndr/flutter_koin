import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('bindAs aliases', () {
    test('RootScoped alias and concrete share one instance', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<CoffeeShopInfo>(
        () => CoffeeShopInfo(1),
        bindAs: [ShopInfoRepository],
      );

      expect(
        identical(container.get<CoffeeShopInfo>(), container.get<ShopInfoRepository>()),
        isTrue,
      );
    });

    test('Scoped alias and concrete share one instance per scope', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var id = 0;
      container.registerScoped<TableSession>(
        () => TableSession(++id),
        bindAs: [TableSessionContract],
      );
      final firstScope = container.createScope('first');
      final secondScope = container.createScope('second');

      expect(
        identical(
          firstScope.get<TableSession>(),
          firstScope.get<TableSessionContract>(),
        ),
        isTrue,
      );
      expect(
        identical(
          firstScope.get<TableSessionContract>(),
          secondScope.get<TableSessionContract>(),
        ),
        isFalse,
      );
    });

    test('Factory alias creates a new instance each time', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var id = 0;
      container.registerFactory<ReceiptFactory>(
        () => ReceiptFactory(++id),
        bindAs: [ReceiptGenerator],
      );

      final first = container.get<ReceiptGenerator>();
      final second = container.get<ReceiptFactory>();

      expect(identical(first, second), isFalse);
      expect([first.id, second.id], [1, 2]);
    });

    test('Conflicting alias does not replace an existing registration', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<CoffeeShopInfo>(
        () => CoffeeShopInfo(1),
        bindAs: [ShopInfoRepository],
      );

      expect(
        () => container.registerRootScoped<AlternativeShopInfo>(
          () => AlternativeShopInfo(),
          bindAs: [ShopInfoRepository],
        ),
        throwsA(anything),
      );

      expect(container.get<ShopInfoRepository>(), isA<CoffeeShopInfo>());
      expect(container.rootScope.has<AlternativeShopInfo>(), isFalse);
    });
  });
}
