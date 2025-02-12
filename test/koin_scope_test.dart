import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

class ApiService {
  String fetchData() => "Data from API";
}

void main() {
  test('Scoped зависимости работают независимо', () {
    final container = KoinContainer();

    // Регистрируем scoped-зависимость в контейнере
    container.registerScoped<ApiService>(() => ApiService());

    // Создаём два независимых scope
    final scope1 = container.createScope("Screen1");
    final scope2 = container.createScope("Screen2");

    // Получаем ApiService в каждом scope (впервые -> создастся)
    final service1 = scope1.get<ApiService>();
    final service2 = scope2.get<ApiService>();

    // Проверяем, что объекты разные
    expect(service1 != service2, true);
  });

  test('Удаление scope удаляет зависимости', () {
    final container = KoinContainer();

    container.registerScoped<ApiService>(() => ApiService());

    final scopeName = "TempScope";
    final scope = container.createScope(scopeName);

    // Получаем scoped-зависимость
    final service = scope.get<ApiService>();
    expect(service.fetchData(), "Data from API");

    // Удаляем scope
    container.deleteScope(scopeName);

    // Теперь при попытке обратиться к этому scope:
    expect(() => container.getScope(scopeName), throwsException);
  });
}
