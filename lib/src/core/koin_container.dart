import 'koin_module.dart';
import 'koin_scope.dart';
import 'lifecycle/koin_disposable.dart';
import 'lifecycle/scope_observer.dart';
import 'lifecycle/scope_registry.dart';

class KoinContainer implements KoinDisposable {
  final Map<Type, dynamic Function()> _factoryDependencies = {};
  final Map<Type, _KoinRegistration<dynamic>> _rootScopedFactories = {};
  final Map<Type, _ScopedRegistration<dynamic>> _scopedFactories = {};

  late final KoinScopeRegistry _scopeRegistry = KoinScopeRegistry(this);

  KoinScope get rootScope => _scopeRegistry.rootScope;

  List<String> get activeScopeNames => _scopeRegistry.activeScopeNames;

  Iterable<KoinScope> get activeScopes => _scopeRegistry.activeScopes;

  void registerFactory<T>(T Function() creator) {
    _factoryDependencies[T] = creator;
  }

  void registerRootScoped<T>(
    T Function() creator, {
    KoinDisposeCallback<T>? disposer,
  }) {
    _rootScopedFactories[T] = _KoinRegistration<T>(
      creator: creator,
      disposer: disposer,
    );
  }

  /// Старый scoped API — без доступа к текущему scope
  void registerScoped<T>(
    T Function() creator, {
    KoinDisposeCallback<T>? disposer,
  }) {
    _scopedFactories[T] = _ScopedRegistration<T>(
      creator: creator,
      disposer: disposer,
    );
  }

  /// Новый scoped API — с доступом к текущему scope
  void registerScopedWithScope<T>(
    T Function(KoinScope scope) creator, {
    KoinDisposeCallback<T>? disposer,
  }) {
    _scopedFactories[T] = _ScopedRegistration<T>.withScope(
      creator: creator,
      disposer: disposer,
    );
  }

  bool hasFactory<T>() => _factoryDependencies.containsKey(T);

  bool hasRootScoped<T>() => _rootScopedFactories.containsKey(T);

  bool hasScoped<T>() => _scopedFactories.containsKey(T);

  T createRootScopedValue<T>() {
    final registration = _rootScopedFactories[T];
    if (registration == null) {
      throw Exception("No root scoped factory found for type $T");
    }

    final typedRegistration = registration as _KoinRegistration<T>;
    return typedRegistration.creator();
  }

  KoinDisposeCallback<T>? getRootScopedDisposer<T>() {
    final registration = _rootScopedFactories[T];
    if (registration == null) {
      return null;
    }

    final typedRegistration = registration as _KoinRegistration<T>;
    return typedRegistration.disposer;
  }

  T createScopedValue<T>(KoinScope scope) {
    final registration = _scopedFactories[T];
    if (registration == null) {
      throw Exception("No scoped factory found for type $T");
    }

    final typedRegistration = registration as _ScopedRegistration<T>;
    return typedRegistration.create(scope);
  }

  KoinDisposeCallback<T>? getScopedDisposer<T>() {
    final registration = _scopedFactories[T];
    if (registration == null) {
      return null;
    }

    final typedRegistration = registration as _ScopedRegistration<T>;
    return typedRegistration.disposer;
  }

  KoinScope createScope(String name) => _scopeRegistry.createScope(name);

  KoinScope getScope(String name) => _scopeRegistry.getScope(name);

  Future<void> deleteScope(String name) => _scopeRegistry.deleteScope(name);

  void addScopeObserver(
    KoinScopeObserver observer, {
    bool replayCurrentScopes = true,
  }) {
    _scopeRegistry.addObserver(
      observer,
      replayCurrentScopes: replayCurrentScopes,
    );
  }

  void removeScopeObserver(KoinScopeObserver observer) {
    _scopeRegistry.removeObserver(observer);
  }

  T get<T>() => _scopeRegistry.rootScope.get<T>();

  T getFactory<T>() {
    if (_factoryDependencies.containsKey(T)) {
      return _factoryDependencies[T]!() as T;
    }

    throw Exception("$T not found in factory dependencies");
  }

  void loadModule(KoinModule module) {
    for (final cb in module.registrations) {
      cb(this);
    }
  }

  @override
  Future<void> dispose() async {
    await _scopeRegistry.dispose();

    _factoryDependencies.clear();
    _rootScopedFactories.clear();
    _scopedFactories.clear();
  }
}

class _KoinRegistration<T> {
  final T Function() creator;
  final KoinDisposeCallback<T>? disposer;

  const _KoinRegistration({required this.creator, this.disposer});
}

class _ScopedRegistration<T> {
  final T Function()? _creator;
  final T Function(KoinScope scope)? _scopeCreator;
  final KoinDisposeCallback<T>? disposer;

  const _ScopedRegistration({required T Function() creator, this.disposer})
    : _creator = creator,
      _scopeCreator = null;

  const _ScopedRegistration.withScope({
    required T Function(KoinScope scope) creator,
    this.disposer,
  }) : _creator = null,
       _scopeCreator = creator;

  T create(KoinScope scope) {
    if (_scopeCreator != null) {
      return _scopeCreator(scope);
    }

    final creator = _creator;
    if (creator != null) {
      return creator();
    }

    throw StateError('Scoped registration has no creator');
  }
}
