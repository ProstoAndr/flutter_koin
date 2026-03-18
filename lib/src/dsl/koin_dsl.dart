import '../core/koin_container.dart';
import '../core/koin_module.dart';
import '../core/koin_scope.dart';
import '../core/lifecycle/scope_observer.dart';

/// Глобальная ссылка на контейнер (аналог getKoin() в Koin)
KoinContainer? _globalContainer;

KoinContainer get koinContainer =>
    _globalContainer ??
    (throw Exception("Koin not started. Call startKoin(...) first."));

KoinContainer startKoin(List<KoinModule> modules) {
  final container = KoinContainer();

  for (final module in modules) {
    container.loadModule(module);
  }

  _globalContainer = container;
  return container;
}

T get<T>() => koinContainer.get<T>();

T? tryGet<T>() => koinContainer.tryGet<T>();

bool has<T>() => koinContainer.has<T>();

KoinScope get rootScope => koinContainer.rootScope;

KoinScope createScope(String name) => koinContainer.createScope(name);

KoinScope getScope(String name) => koinContainer.getScope(name);

Future<void> deleteScope(String name) => koinContainer.deleteScope(name);

void addScopeObserver(
  KoinScopeObserver observer, {
  bool replayCurrentScopes = true,
}) {
  koinContainer.addScopeObserver(
    observer,
    replayCurrentScopes: replayCurrentScopes,
  );
}

void removeScopeObserver(KoinScopeObserver observer) {
  koinContainer.removeScopeObserver(observer);
}

Future<void> stopKoin() async {
  final container = _globalContainer;
  if (container == null) {
    return;
  }

  await container.dispose();
  _globalContainer = null;
}
