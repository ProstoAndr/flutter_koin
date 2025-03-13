library koin_generator_test;

// Импорты для тестов
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

// !!! Важно: объявляем part, чтобы генератор мог создать koin_generator_test.koin.dart
part 'koin_generator_test.koin.dart';

// Тестовые классы, которые будут аннотированы
@Factory()
class TestFactoryService {
  void doSomething() => print("TestFactoryService: Doing something...");
}

@Scoped()
class TestScopedService {
  void doScopedWork() => print("TestScopedService: Doing scoped work...");
}

// Собственно тесты
void main() {
  group('Koin generator all-in-one test file', () {
    test('Factory dependencies produce new instances each time', () {
      final container = KoinContainer();
      // koinModule придёт из koin_generator_test.koin.dart
      container.loadModule(koinModule);

      final serviceA = container.get<TestFactoryService>();
      final serviceB = container.get<TestFactoryService>();

      // Проверяем, что объекты разные
      expect(identical(serviceA, serviceB), isFalse);
    });

    test('Scoped dependencies return same instance in one scope', () {
      final container = KoinContainer();
      container.loadModule(koinModule);

      final scope1 = container.createScope("Scope1");
      final scope2 = container.createScope("Scope2");

      final s1Obj1 = scope1.get<TestScopedService>();
      final s1Obj2 = scope1.get<TestScopedService>();
      final s2Obj = scope2.get<TestScopedService>();

      // Один scope -> один объект
      expect(identical(s1Obj1, s1Obj2), isTrue);

      // Другой scope -> другой объект
      expect(identical(s1Obj1, s2Obj), isFalse);
    });
  });
}
