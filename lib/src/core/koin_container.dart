import 'errors/koin_exceptions.dart';
import 'koin_module.dart';
import 'koin_scope.dart';
import 'lifecycle/koin_disposable.dart';
import 'lifecycle/scope_observer.dart';
import 'lifecycle/scope_registry.dart';

class KoinContainer implements KoinDisposable {
  final Map<Type, dynamic Function()> _factoryDependencies = {};
  final Map<Type, _KoinRegistration<dynamic>> _rootScopedFactories = {};
  final Map<Type, _ScopedRegistration<dynamic>> _scopedFactories = {};

  final Map<Type, Type> _factoryAliases = {};
  final Map<Type, Type> _rootScopedAliases = {};
  final Map<Type, Type> _scopedAliases = {};

  late final KoinScopeRegistry _scopeRegistry = KoinScopeRegistry(this);

  KoinScope get rootScope => _scopeRegistry.rootScope;

  List<String> get activeScopeNames => _scopeRegistry.activeScopeNames;

  Iterable<KoinScope> get activeScopes => _scopeRegistry.activeScopes;

  void registerFactory<T>(
      T Function() creator, {
        List<Type> bindAs = const [],
      }) {
    _factoryDependencies[T] = creator;

    _registerAliases(
      concreteType: T,
      aliases: bindAs,
      aliasMap: _factoryAliases,
      registrationKind: 'factory',
    );
  }

  void registerRootScoped<T>(
      T Function() creator, {
        KoinDisposeCallback<T>? disposer,
        List<Type> bindAs = const [],
      }) {
    _rootScopedFactories[T] = _KoinRegistration<T>(
      creator: creator,
      disposer: disposer,
    );

    _registerAliases(
      concreteType: T,
      aliases: bindAs,
      aliasMap: _rootScopedAliases,
      registrationKind: 'root scoped',
    );
  }

  void registerScoped<T>(
      T Function() creator, {
        KoinDisposeCallback<T>? disposer,
        List<Type> bindAs = const [],
      }) {
    _scopedFactories[T] = _ScopedRegistration<T>(
      creator: creator,
      disposer: disposer,
    );

    _registerAliases(
      concreteType: T,
      aliases: bindAs,
      aliasMap: _scopedAliases,
      registrationKind: 'scoped',
    );
  }

  void registerScopedWithScope<T>(
      T Function(KoinScope scope) creator, {
        KoinDisposeCallback<T>? disposer,
        List<Type> bindAs = const [],
      }) {
    _scopedFactories[T] = _ScopedRegistration<T>.withScope(
      creator: creator,
      disposer: disposer,
    );

    _registerAliases(
      concreteType: T,
      aliases: bindAs,
      aliasMap: _scopedAliases,
      registrationKind: 'scoped',
    );
  }

  void _registerAliases({
    required Type concreteType,
    required List<Type> aliases,
    required Map<Type, Type> aliasMap,
    required String registrationKind,
  }) {
    for (final aliasType in aliases) {
      if (aliasType == concreteType) {
        continue;
      }

      final existingType = aliasMap[aliasType];
      if (existingType != null && existingType != concreteType) {
        throw KoinAliasConflictException(
          'Cannot bind alias "$aliasType" to "$concreteType". '
              'It is already bound to "$existingType" in $registrationKind registrations.',
        );
      }

      aliasMap[aliasType] = concreteType;
    }
  }

  Type resolveFactoryType(Type requestedType) {
    return _factoryAliases[requestedType] ?? requestedType;
  }

  Type resolveRootScopedType(Type requestedType) {
    return _rootScopedAliases[requestedType] ?? requestedType;
  }

  Type resolveScopedType(Type requestedType) {
    return _scopedAliases[requestedType] ?? requestedType;
  }

  bool hasFactory<T>() => hasFactoryType(T);

  bool hasRootScoped<T>() => hasRootScopedType(T);

  bool hasScoped<T>() => hasScopedType(T);

  bool hasFactoryType(Type requestedType) {
    final resolvedType = resolveFactoryType(requestedType);
    return _factoryDependencies.containsKey(resolvedType);
  }

  bool hasRootScopedType(Type requestedType) {
    final resolvedType = resolveRootScopedType(requestedType);
    return _rootScopedFactories.containsKey(resolvedType);
  }

  bool hasScopedType(Type requestedType) {
    final resolvedType = resolveScopedType(requestedType);
    return _scopedFactories.containsKey(resolvedType);
  }

  T createRootScopedValue<T>() {
    return createRootScopedValueByType(T) as T;
  }

  Object createRootScopedValueByType(Type requestedType) {
    final resolvedType = resolveRootScopedType(requestedType);
    final registration = _rootScopedFactories[resolvedType];

    if (registration == null) {
      throw KoinDependencyNotFoundException(
        'Root-scoped dependency "$requestedType" was not found. '
            'Resolved type: "$resolvedType".',
      );
    }

    return registration.creator();
  }

  KoinDisposeCallback<T>? getRootScopedDisposer<T>() {
    return getRootScopedDisposerByType(T) as KoinDisposeCallback<T>?;
  }

  KoinDisposeCallback<dynamic>? getRootScopedDisposerByType(Type requestedType) {
    final resolvedType = resolveRootScopedType(requestedType);
    final registration = _rootScopedFactories[resolvedType];

    if (registration == null) {
      return null;
    }

    return registration.disposer;
  }

  T createScopedValue<T>(KoinScope scope) {
    return createScopedValueByType(T, scope) as T;
  }

  Object createScopedValueByType(Type requestedType, KoinScope scope) {
    final resolvedType = resolveScopedType(requestedType);
    final registration = _scopedFactories[resolvedType];

    if (registration == null) {
      throw KoinDependencyNotFoundException(
        'Scoped dependency "$requestedType" was not found. '
            'Resolved type: "$resolvedType". '
            'Scope: "${scope.name}".',
      );
    }

    return registration.create(scope);
  }

  KoinDisposeCallback<T>? getScopedDisposer<T>() {
    return getScopedDisposerByType(T) as KoinDisposeCallback<T>?;
  }

  KoinDisposeCallback<dynamic>? getScopedDisposerByType(Type requestedType) {
    final resolvedType = resolveScopedType(requestedType);
    final registration = _scopedFactories[resolvedType];

    if (registration == null) {
      return null;
    }

    return registration.disposer;
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

  T getFactory<T>() => getFactoryByType(T) as T;

  Object getFactoryByType(Type requestedType) {
    final resolvedType = resolveFactoryType(requestedType);
    final creator = _factoryDependencies[resolvedType];

    if (creator == null) {
      throw KoinDependencyNotFoundException(
        'Factory dependency "$requestedType" was not found. '
            'Resolved type: "$resolvedType".',
      );
    }

    return creator();
  }

  void loadModule(KoinModule module) {
    for (final callback in module.registrations) {
      callback(this);
    }
  }

  @override
  Future<void> dispose() async {
    await _scopeRegistry.dispose();

    _factoryDependencies.clear();
    _rootScopedFactories.clear();
    _scopedFactories.clear();

    _factoryAliases.clear();
    _rootScopedAliases.clear();
    _scopedAliases.clear();
  }
}

class _KoinRegistration<T> {
  final T Function() creator;
  final KoinDisposeCallback<T>? disposer;

  const _KoinRegistration({
    required this.creator,
    this.disposer,
  });
}

class _ScopedRegistration<T> {
  final T Function()? _creator;
  final T Function(KoinScope scope)? _scopeCreator;
  final KoinDisposeCallback<T>? disposer;

  const _ScopedRegistration({
    required T Function() creator,
    this.disposer,
  })  : _creator = creator,
        _scopeCreator = null;

  const _ScopedRegistration.withScope({
    required T Function(KoinScope scope) creator,
    this.disposer,
  })  : _creator = null,
        _scopeCreator = creator;

  T create(KoinScope scope) {
    if (_scopeCreator != null) {
      return _scopeCreator(scope);
    }

    if (_creator != null) {
      return _creator();
    }

    throw StateError('Scoped registration has no creator.');
  }
}