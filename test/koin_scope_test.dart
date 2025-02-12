import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

class ApiService {
  String fetchData() => "Data from API";
}

void main() {
  test('Scoped зависимости работают независимо', () {
    final container = KoinContainer();
    final scope1 = container.createScope("Screen1");
    final scope2 = container.createScope("Screen2");

    scope1.register<ApiService>(() => ApiService());
    scope2.register<ApiService>(() => ApiService());

    final service1 = scope1.get<ApiService>();
    final service2 = scope2.get<ApiService>();

    expect(service1 != service2, true);
  });

  test('Удаление scope удаляет зависимости', () {
    final container = KoinContainer();
    final scopeName = "TempScope";
    final scope = container.createScope(scopeName);

    scope.register<ApiService>(() => ApiService());

    final service = scope.get<ApiService>();
    expect(service.fetchData(), "Data from API");

    // Удаляем scope
    container.deleteScope(scopeName);

    // Проверяем, что доступ к scope вызывает ошибку
    expect(() => container.getScope(scopeName), throwsException);
  });
}
