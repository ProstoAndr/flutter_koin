import 'koin_container.dart';
import 'lifecycle/koin_disposable.dart';

enum KoinScopeKind { root, feature }

class KoinScope implements KoinDisposable {
  final String name;
  final KoinContainer _container;
  final KoinScopeKind _kind;
  final KoinScope? _parent;

  final Map<Type, dynamic> _cachedObjects = {};
  final Map<Type, KoinDisposeCallback<dynamic>> _disposers = {};

  KoinScope._(this.name, this._container, this._kind, [this._parent]);

  factory KoinScope.root(KoinContainer container) {
    return KoinScope._('__root__', container, KoinScopeKind.root);
  }

  factory KoinScope.feature(
    String name,
    KoinContainer container,
    KoinScope rootScope,
  ) {
    return KoinScope._(name, container, KoinScopeKind.feature, rootScope);
  }

  bool get isRoot => _kind == KoinScopeKind.root;

  bool get isFeature => _kind == KoinScopeKind.feature;

  T get<T>() {
    if (_cachedObjects.containsKey(T)) {
      return _cachedObjects[T] as T;
    }

    if (isFeature && _container.hasScoped<T>()) {
      final value = _container.createScopedValue<T>(this);
      final disposer = _container.getScopedDisposer<T>();
      _cacheValue<T>(value, disposer);
      return value;
    }

    if (isRoot && _container.hasRootScoped<T>()) {
      final value = _container.createRootScopedValue<T>();
      final disposer = _container.getRootScopedDisposer<T>();
      _cacheValue<T>(value, disposer);
      return value;
    }

    if (isFeature) {
      final parent = _parent;
      if (parent != null) {
        return parent.get<T>();
      }
    }

    return _container.getFactory<T>();
  }

  void _cacheValue<T>(T value, KoinDisposeCallback<T>? disposer) {
    _cachedObjects[T] = value;

    if (disposer != null) {
      _disposers[T] = (instance) => disposer(instance as T);
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
