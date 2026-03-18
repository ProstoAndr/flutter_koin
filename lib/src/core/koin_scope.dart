import 'koin_container.dart';
import 'lifecycle/koin_disposable.dart';

enum KoinScopeKind {
  root,
  feature,
}

class KoinScope implements KoinDisposable {
  final String name;
  final KoinContainer _container;
  final KoinScopeKind _kind;
  final KoinScope? _parent;

  final Map<Type, dynamic> _cachedObjects = {};
  final Map<Type, KoinDisposeCallback<dynamic>> _disposers = {};

  KoinScope._(
      this.name,
      this._container,
      this._kind, [
        this._parent,
      ]);

  factory KoinScope.root(KoinContainer container) {
    return KoinScope._(
      '__root__',
      container,
      KoinScopeKind.root,
    );
  }

  factory KoinScope.feature(
      String name,
      KoinContainer container,
      KoinScope rootScope,
      ) {
    return KoinScope._(
      name,
      container,
      KoinScopeKind.feature,
      rootScope,
    );
  }

  bool get isRoot => _kind == KoinScopeKind.root;

  bool get isFeature => _kind == KoinScopeKind.feature;

  T get<T>() {
    final requestedType = T;

    if (isFeature) {
      final resolvedScopedType = _container.resolveScopedType(requestedType);

      if (_cachedObjects.containsKey(resolvedScopedType)) {
        return _cachedObjects[resolvedScopedType] as T;
      }

      if (_container.hasScopedType(requestedType)) {
        final scopedValue = _container.createScopedValueByType(
          requestedType,
          this,
        );
        final disposer = _container.getScopedDisposerByType(requestedType);

        _cacheValue(
          cacheKey: resolvedScopedType,
          value: scopedValue,
          disposer: disposer,
        );

        return scopedValue as T;
      }
    }

    if (isRoot) {
      final resolvedRootScopedType = _container.resolveRootScopedType(
        requestedType,
      );

      if (_cachedObjects.containsKey(resolvedRootScopedType)) {
        return _cachedObjects[resolvedRootScopedType] as T;
      }

      if (_container.hasRootScopedType(requestedType)) {
        final rootScopedValue = _container.createRootScopedValueByType(
          requestedType,
        );
        final disposer = _container.getRootScopedDisposerByType(requestedType);

        _cacheValue(
          cacheKey: resolvedRootScopedType,
          value: rootScopedValue,
          disposer: disposer,
        );

        return rootScopedValue as T;
      }
    }

    if (isFeature) {
      final parentScope = _parent;
      if (parentScope != null) {
        return parentScope.get<T>();
      }
    }

    return _container.getFactoryByType(requestedType) as T;
  }

  void _cacheValue({
    required Type cacheKey,
    required Object value,
    required KoinDisposeCallback<dynamic>? disposer,
  }) {
    _cachedObjects[cacheKey] = value;

    if (disposer != null) {
      _disposers[cacheKey] = disposer;
    }
  }

  Future<void> clear() async {
    final entries = _cachedObjects.entries.toList().reversed;

    for (final entry in entries) {
      final type = entry.key;
      final value = entry.value;

      final disposer = _disposers[type];
      if (disposer != null) {
        await disposer(value);
        continue;
      }

      if (value is KoinDisposable) {
        await value.dispose();
      }
    }

    _disposers.clear();
    _cachedObjects.clear();
  }

  @override
  Future<void> dispose() => clear();
}