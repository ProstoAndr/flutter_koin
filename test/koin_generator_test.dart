import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_koin/my_services.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('flutter_koin codegen test', () {
    test('Factory dependencies produce new instances each time', () {
      final container = KoinContainer();
      container.loadModule(koinModule);

      final myServiceA = container.get<MyService>();
      final myServiceB = container.get<MyService>();

      // Проверяем, что объекты разные
      expect(myServiceA, isNot(same(myServiceB)));
    });

    test('Scoped dependencies return the same instance within one scope', () {
      final container = KoinContainer();
      container.loadModule(koinModule);

      final scope1 = container.createScope("Scope1");
      final scope2 = container.createScope("Scope2");

      final s1Obj1 = scope1.get<MyScopedService>();
      final s1Obj2 = scope1.get<MyScopedService>();
      final s2Obj = scope2.get<MyScopedService>();

      // В пределах одного scope объекты совпадают
      expect(s1Obj1, same(s1Obj2));

      // В другом scope объект уже другой
      expect(s1Obj1, isNot(same(s2Obj)));
    });
  });
}
