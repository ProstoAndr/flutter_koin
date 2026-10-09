import 'dart:async';

import '../koin_container.dart';
import '../koin_scope.dart';
import 'koin_disposable.dart';
import 'scope_observer.dart';

class KoinScopeRegistry implements KoinDisposable {
  final KoinContainer _container;
  final Map<String, KoinScope> _scopes = {};
  final List<KoinScopeObserver> _observers = [];

  late final KoinScope _rootScope;

  final Map<String, Future<void>> _pendingScopeDisposals = {};

  Future<void>? _disposeFuture;

  KoinScopeRegistry(this._container) {
    _rootScope = KoinScope.root(_container);
  }

  KoinScope get rootScope => _rootScope;

  List<String> get activeScopeNames => List.unmodifiable(_scopes.keys);

  Iterable<KoinScope> get activeScopes => List.unmodifiable(_scopes.values);

  bool containsScope(String name) => _scopes.containsKey(name);

  Future<void> _trackScopeDisposal(String name, Future<void> operation) {
    late final Future<void> tracked;

    tracked = operation.whenComplete(() {
      if (identical(_pendingScopeDisposals[name], tracked)) {
        _pendingScopeDisposals.remove(name);
      }
    });

    _pendingScopeDisposals[name] = tracked;

    return tracked;
  }

  void addObserver(
    KoinScopeObserver observer, {
    bool replayCurrentScopes = true,
  }) {
    if (_disposeFuture != null || _container.isDisposingOrDisposed) {
      throw StateError(
        'Cannot add scope observer. '
        'KoinScopeRegistry is disposing or already disposed.',
      );
    }

    if (_observers.contains(observer)) {
      return;
    }

    _observers.add(observer);

    if (!replayCurrentScopes) {
      return;
    }

    try {
      observer.onScopeCreated(_rootScope);

      final scopes = _scopes.values.toList();

      for (final scope in scopes) {
        observer.onScopeCreated(scope);
      }
    } catch (_) {
      _observers.remove(observer);
      rethrow;
    }
  }

  void removeObserver(KoinScopeObserver observer) {
    _observers.remove(observer);
  }

  KoinScope createScope(String name) {
    if (_disposeFuture != null || _container.isDisposingOrDisposed) {
      throw StateError(
        'Cannot create scope "$name". '
        'KoinScopeRegistry is disposing or already disposed.',
      );
    }

    if (name.trim().isEmpty || name == '__root__') {
      throw ArgumentError.value(
        name,
        'name',
        'Scope name must not be empty or reserved.',
      );
    }

    if (_scopes.containsKey(name) || _pendingScopeDisposals.containsKey(name)) {
      throw StateError('Scope "$name" already exists or is being disposed.');
    }

    final scope = KoinScope.feature(name, _container, _rootScope);

    _scopes[name] = scope;

    try {
      _notifyScopeCreated(scope);
    } catch (error, stackTrace) {
      if (identical(_scopes[name], scope)) {
        _scopes.remove(name);

        unawaited(_trackScopeDisposal(name, _rollbackFailedScope(scope)));
      }

      Error.throwWithStackTrace(error, stackTrace);
    }

    if (!identical(_scopes[name], scope)) {
      throw StateError('Scope "$name" was removed during creation.');
    }

    return scope;
  }

  Future<void> _rollbackFailedScope(KoinScope scope) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    try {
      await scope.dispose();
    } catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }

    try {
      _notifyScopeDisposed(scope);
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError != null) {
      Zone.current.handleUncaughtError(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  KoinScope getScope(String name) {
    final scope = _scopes[name];
    if (scope == null) {
      throw Exception("Scope '$name' not found");
    }
    return scope;
  }

  Future<void> deleteScope(String name) {
    final pending = _pendingScopeDisposals[name];

    if (pending != null) {
      return pending;
    }

    final scope = _scopes.remove(name);

    if (scope == null) {
      return Future<void>.value();
    }

    return _trackScopeDisposal(name, _disposeScope(scope));
  }

  Future<void> _disposeScope(KoinScope scope) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    try {
      await scope.dispose();
    } catch (error, stackTrace) {
      firstError = error;
      firstStackTrace = stackTrace;
    }

    try {
      _notifyScopeDisposed(scope);
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  void _notifyScopeCreated(KoinScope scope) {
    final observers = List<KoinScopeObserver>.from(_observers);

    Object? firstError;
    StackTrace? firstStackTrace;

    for (final observer in observers) {
      try {
        observer.onScopeCreated(scope);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  void _notifyScopeDisposed(KoinScope scope) {
    final observers = List<KoinScopeObserver>.from(_observers);

    Object? firstError;
    StackTrace? firstStackTrace;

    for (final observer in observers) {
      try {
        observer.onScopeDisposed(scope);
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  @override
  Future<void> dispose() {
    if (_disposeFuture != null) {
      return _disposeFuture!;
    }

    final pendingAtStart = _pendingScopeDisposals.values.toList();

    return _disposeFuture = Future<void>.microtask(
      () => _disposeInternal(pendingAtStart),
    );
  }

  Future<void> _disposeInternal(List<Future<void>> pendingAtStart) async {
    Object? firstError;
    StackTrace? firstStackTrace;

    try {
      final scopeNames = _scopes.keys.toList();

      for (final scopeName in scopeNames) {
        try {
          await deleteScope(scopeName);
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }
      }

      for (final pending in pendingAtStart) {
        try {
          await pending;
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }
      }

      while (_pendingScopeDisposals.isNotEmpty) {
        final pending = _pendingScopeDisposals.values.toList();

        for (final future in pending) {
          try {
            await future;
          } catch (error, stackTrace) {
            firstError ??= error;
            firstStackTrace ??= stackTrace;
          }
        }
      }

      try {
        await _rootScope.dispose();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      } finally {
        try {
          _notifyScopeDisposed(_rootScope);
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }
      }
    } finally {
      _observers.clear();
    }

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }
}
