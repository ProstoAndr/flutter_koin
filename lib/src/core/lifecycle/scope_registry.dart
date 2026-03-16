import '../koin_container.dart';
import '../koin_scope.dart';
import 'koin_disposable.dart';
import 'scope_observer.dart';

class KoinScopeRegistry implements KoinDisposable {
  final KoinContainer _container;
  final Map<String, KoinScope> _scopes = {};
  final List<KoinScopeObserver> _observers = [];

  late final KoinScope _rootScope;

  KoinScopeRegistry(this._container) {
    _rootScope = KoinScope.root(_container);
  }

  KoinScope get rootScope => _rootScope;

  List<String> get activeScopeNames => List.unmodifiable(_scopes.keys);

  Iterable<KoinScope> get activeScopes => List.unmodifiable(_scopes.values);

  bool containsScope(String name) => _scopes.containsKey(name);

  void addObserver(
    KoinScopeObserver observer, {
    bool replayCurrentScopes = true,
  }) {
    if (_observers.contains(observer)) {
      return;
    }

    _observers.add(observer);

    if (replayCurrentScopes) {
      observer.onScopeCreated(_rootScope);

      for (final scope in _scopes.values) {
        observer.onScopeCreated(scope);
      }
    }
  }

  void removeObserver(KoinScopeObserver observer) {
    _observers.remove(observer);
  }

  KoinScope createScope(String name) {
    if (_scopes.containsKey(name)) {
      throw Exception("Scope '$name' already exists");
    }

    final scope = KoinScope.feature(name, _container, _rootScope);
    _scopes[name] = scope;
    _notifyScopeCreated(scope);
    return scope;
  }

  KoinScope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw Exception("Scope '$name' not found");
    }
    return scope;
  }

  Future<void> deleteScope(String name) async {
    final scope = _scopes.remove(name);
    if (scope == null) {
      return;
    }

    await scope.dispose();
    _notifyScopeDisposed(scope);
  }

  void _notifyScopeCreated(KoinScope scope) {
    final observers = List<KoinScopeObserver>.from(_observers);

    for (final observer in observers) {
      observer.onScopeCreated(scope);
    }
  }

  void _notifyScopeDisposed(KoinScope scope) {
    final observers = List<KoinScopeObserver>.from(_observers);

    for (final observer in observers) {
      observer.onScopeDisposed(scope);
    }
  }

  @override
  Future<void> dispose() async {
    final scopeNames = _scopes.keys.toList();

    for (final scopeName in scopeNames) {
      await deleteScope(scopeName);
    }

    await _rootScope.dispose();
    _notifyScopeDisposed(_rootScope);

    _observers.clear();
  }
}
