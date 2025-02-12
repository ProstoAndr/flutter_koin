import 'koin_container.dart';

class KoinModule {
  final List<void Function(KoinContainer)> _bindings = [];

  /// Добавление зависимости в модуль
  void register(void Function(KoinContainer) binding) {
    _bindings.add(binding);
  }

  /// Регистрация всех зависимостей в переданный KoinContainer
  void load(KoinContainer container) {
    for (var binding in _bindings) {
      binding(container);
    }
  }
}
