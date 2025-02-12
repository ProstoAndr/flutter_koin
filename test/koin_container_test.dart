import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

class ApiService {
  String fetchData() => "Data from API";
}

void main() {
  test('Регистрация и получение глобальной зависимости', () {
    final container = KoinContainer();
    container.registerSingleton<ApiService>(ApiService());

    final apiService = container.get<ApiService>();
    expect(apiService.fetchData(), "Data from API");
  });
}
