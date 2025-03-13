library flutter_koin;

// Экспортируем аннотации и основной DI-код:
export 'src/annotations/factory.dart';
export 'src/annotations/scoped.dart';

export 'src/core/koin_container.dart';
export 'src/core/koin_module.dart';
export 'src/core/koin_scope.dart';

// Экспортируем "DSL" для инициализации
export 'src/dsl/koin_dsl.dart';