import '../core/koin_container.dart';
import '../core/koin_module.dart';
import '../core/koin_scope.dart';

/// Глобальная ссылка на контейнер (аналог getKoin() в Koin)
KoinContainer? _globalContainer;

/// Возвращает глобальный контейнер, если он инициализирован
KoinContainer get koinContainer => _globalContainer ??
    (throw Exception("Koin not started. Call startKoin(...) first."));

/// Функция, запускающая Koin, куда можно передать список модулей и настроек.
KoinContainer startKoin(List<KoinModule> modules) {
  final container = KoinContainer();
  for (final m in modules) {
    container.loadModule(m);
  }
  _globalContainer = container;
  return container;
}

/// Утилита для глобального доступа: get<MyService>()
T get<T>() => koinContainer.get<T>();

/// Создаём Scope в глобальном контейнере
KoinScope createScope(String name) => koinContainer.createScope(name);
