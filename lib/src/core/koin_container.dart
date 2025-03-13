import 'koin_module.dart';
import 'koin_scope.dart';

class KoinContainer {
  final Map<Type, dynamic Function()> _factoryDependencies = {};
  final Map<Type, dynamic Function()> _scopedFactories = {};
  final Map<String, KoinScope> _scopes = {};

  /// Регистрирует фабрику (новый объект при каждом get<T>())
  void registerFactory<T>(T Function() creator) {
    _factoryDependencies[T] = creator;
  }

  /// Регистрирует scoped (один объект на каждый Scope)
  void registerScoped<T>(T Function() creator) {
    _scopedFactories[T] = creator;
  }

  bool hasScoped<T>() => _scopedFactories.containsKey(T);

  T createScopedInstance<T>() {
    final creator = _scopedFactories[T];
    if (creator == null) {
      throw Exception("No scoped factory found for type $T");
    }
    return creator() as T;
  }

  /// Создать Scope
  KoinScope createScope(String name) {
    final scope = KoinScope(name, this);
    _scopes[name] = scope;
    return scope;
  }

  /// Удалить Scope
  void deleteScope(String name) {
    _scopes.remove(name);
  }

  /// Получить Scope
  KoinScope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw Exception("Scope '$name' not found");
    }
    return scope;
  }

  /// Получить фабричную зависимость (если зарегистрирована)
  T get<T>() {
    if (_factoryDependencies.containsKey(T)) {
      return _factoryDependencies[T]!() as T;
    }
    throw Exception("$T not found in factory dependencies");
  }

  /// Загрузка зависимостей из модуля
  void loadModule(KoinModule module) {
    for (final cb in module.registrations) {
      cb(this);
    }
  }
}
