import 'koin_scope.dart';

class KoinContainer {
  final Map<Type, dynamic> _singletonDependencies = {};
  final Map<Type, dynamic Function()> _factoryDependencies = {};
  final Map<String, KoinScope> _scopes = {};

  /// Регистрация глобальной зависимости (всё время одна и та же)
  void registerSingleton<T>(T instance) {
    _singletonDependencies[T] = instance;
  }

  /// Регистрация фабрики (новый объект при каждом запросе)
  void registerFactory<T>(T Function() creator) {
    _factoryDependencies[T] = creator;
  }

  /// Создание нового scope
  KoinScope createScope(String name) {
    final scope = KoinScope(name);
    _scopes[name] = scope;
    return scope;
  }

  /// Получение scope по имени
  KoinScope getScope(String name) {
    if (!_scopes.containsKey(name)) {
      throw Exception("Scope '$name' not found.");
    }
    return _scopes[name]!;
  }

  /// Удаление scope
  void deleteScope(String name) {
    _scopes.remove(name);
  }

  /// Получение зависимости
  T get<T>() {
    if (_singletonDependencies.containsKey(T)) {
      return _singletonDependencies[T] as T;
    }

    if (_factoryDependencies.containsKey(T)) {
      return _factoryDependencies[T]!() as T;
    }

    throw Exception("Dependency of type $T not found.");
  }
}
