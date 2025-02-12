class KoinScope {
  final String name;
  final Map<Type, dynamic> _dependencies = {};

  KoinScope(this.name);

  /// Регистрация зависимости внутри scope
  void register<T>(T Function() creator) {
    _dependencies[T] = creator();
  }

  /// Получение зависимости
  T get<T>() {
    if (!_dependencies.containsKey(T)) {
      throw Exception("Dependency of type $T not found in scope '$name'.");
    }
    return _dependencies[T] as T;
  }

  /// Очистка всех зависимостей внутри scope
  void clear() {
    _dependencies.clear();
  }
}
