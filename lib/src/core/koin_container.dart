import 'koin_module.dart';
import 'koin_scope.dart';

class KoinContainer {
  final Map<Type, dynamic Function()> _factoryDependencies = {};
  final Map<Type, dynamic Function()> _scopedFactories = {};

  final Map<String, KoinScope> _scopes = {};

  // Factory
  void registerFactory<T>(T Function() creator) {
    _factoryDependencies[T] = creator;
  }

  // Scoped
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

  // Создать scope
  KoinScope createScope(String name) {
    final scope = KoinScope(name, this);
    _scopes[name] = scope;
    return scope;
  }

  // Удалить scope
  void deleteScope(String name) {
    _scopes.remove(name);
  }

  // Доступ к scope по имени
  KoinScope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw Exception("Scope $name not found");
    }
    return scope;
  }

  // get без scope => Factory (или Singleton, если захотите)
  T get<T>() {
    if (_factoryDependencies.containsKey(T)) {
      return _factoryDependencies[T]!() as T;
    }
    throw Exception("$T not found in factory dependencies");
  }

  // Загружаем модуль (по факту список колбэков)
  void loadModule(KoinModule module) {
    for (final cb in module.registrations) {
      cb(this);
    }
  }
}
