import 'errors/koin_exceptions.dart';
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

      final parentScope = _parent;
      if (parentScope != null) {
        try {
          return parentScope.get<T>();
        } on KoinDependencyNotFoundException {
          throw KoinDependencyNotFoundException(
            _buildDependencyNotFoundMessage(requestedType),
          );
        }
      }

      throw KoinDependencyNotFoundException(
        _buildDependencyNotFoundMessage(requestedType),
      );
    }

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

    if (_container.hasFactoryType(requestedType)) {
      return _container.getFactoryByType(requestedType) as T;
    }

    throw KoinDependencyNotFoundException(
      _buildDependencyNotFoundMessage(requestedType),
    );
  }

  T? tryGet<T>() {
    if (!has<T>()) {
      return null;
    }

    return get<T>();
  }

  bool has<T>() => hasByType(T);

  bool hasByType(Type requestedType) {
    if (isFeature) {
      if (_container.hasScopedType(requestedType)) {
        return true;
      }

      final parentScope = _parent;
      if (parentScope != null) {
        return parentScope.hasByType(requestedType);
      }

      return false;
    }

    return _container.hasRootScopedType(requestedType) ||
        _container.hasFactoryType(requestedType);
  }

  String _buildDependencyNotFoundMessage(Type requestedType) {
    final resolvedScopedType = _container.resolveScopedType(requestedType);
    final resolvedRootScopedType = _container.resolveRootScopedType(
      requestedType,
    );
    final resolvedFactoryType = _container.resolveFactoryType(requestedType);

    final hasScopedRegistration = _container.hasScopedType(requestedType);
    final hasRootScopedRegistration = _container.hasRootScopedType(
      requestedType,
    );
    final hasFactoryRegistration = _container.hasFactoryType(requestedType);

    final buffer = StringBuffer()
      ..writeln('Dependency "$requestedType" was not found.')
      ..writeln(
        'Current scope: "$name" (${isRoot ? 'root' : 'feature'}).',
      );

    if (isFeature) {
      buffer
        ..writeln('Lookup order:')
        ..writeln(
          '1. feature scope -> ${_formatResolvedType(requestedType, resolvedScopedType)} '
              '(registered: $hasScopedRegistration)',
        )
        ..writeln(
          '2. root scope -> ${_formatResolvedType(requestedType, resolvedRootScopedType)} '
              '(registered: $hasRootScopedRegistration)',
        )
        ..writeln(
          '3. factory -> ${_formatResolvedType(requestedType, resolvedFactoryType)} '
              '(registered: $hasFactoryRegistration)',
        );
    } else {
      buffer
        ..writeln('Lookup order:')
        ..writeln(
          '1. root scope -> ${_formatResolvedType(requestedType, resolvedRootScopedType)} '
              '(registered: $hasRootScopedRegistration)',
        )
        ..writeln(
          '2. factory -> ${_formatResolvedType(requestedType, resolvedFactoryType)} '
              '(registered: $hasFactoryRegistration)',
        );
    }

    return buffer.toString().trimRight();
  }

  String _formatResolvedType(Type requestedType, Type resolvedType) {
    if (requestedType == resolvedType) {
      return '$resolvedType';
    }

    return '$requestedType -> $resolvedType';
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