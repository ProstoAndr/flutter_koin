import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin_example_test/main.dart' as demo;

void main() {
  group('Generated koinModule integration', () {
    test('RootScoped bindAs resolves to the same instance', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.loadModule(demo.koinModule);

      final concrete = container.get<demo.CoffeeShopInfo>();
      final alias = container.get<demo.ShopInfoRepository>();

      expect(identical(concrete, alias), isTrue);
      expect(alias.title, 'Aurora Coffee');
    });

    test('Factory bindAs produces a new instance each time', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.loadModule(demo.koinModule);

      final first = container.get<demo.ReceiptGenerator>();
      final second = container.get<demo.ReceiptGenerator>();

      expect(identical(first, second), isFalse);
    });

    test('Scoped aliases and constructor injection work end to end', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.loadModule(demo.koinModule);
      final scope = container.createScope('generated:table');

      final session = scope.get<demo.TableSessionContract>();
      final service = scope.get<demo.TableOrderService>();

      expect(identical(session, scope.get<demo.TableSession>()), isTrue);
      expect(identical(service, scope.get<demo.TableService>()), isTrue);
      expect(service.describeOrder(), contains(session.label));
      expect(service.describeOrder(), contains('Aurora Coffee'));
    });

    test('Opening a new feature scope creates a new Scoped instance', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.loadModule(demo.koinModule);
      final first = container.createScope('first');
      final second = container.createScope('second');

      expect(
        identical(
          first.get<demo.TableSessionContract>(),
          second.get<demo.TableSessionContract>(),
        ),
        isFalse,
      );
    });
  });
}
