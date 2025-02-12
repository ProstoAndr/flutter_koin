import 'koin_container.dart';

class KoinScope {
  final String name;
  final KoinContainer _container;
  final Map<Type, dynamic> _cachedObjects = {};

  KoinScope(this.name, this._container);

  T get<T>() {
    // Если уже есть кэш
    if (_cachedObjects.containsKey(T)) {
      return _cachedObjects[T] as T;
    }
    // Иначе создаём
    if (_container.hasScoped<T>()) {
      final instance = _container.createScopedInstance<T>();
      _cachedObjects[T] = instance;
      return instance;
    }
    // Если нет
    throw Exception("Dependency of type $T not found in scope '$name'.");
  }

  void clear() {
    _cachedObjects.clear();
  }
}
