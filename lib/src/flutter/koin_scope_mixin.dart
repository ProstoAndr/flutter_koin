import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/koin_scope.dart';
import '../dsl/koin_dsl.dart';
import 'koin_scope_provider.dart';

mixin KoinScopeMixin<T extends StatefulWidget> on State<T> {
  late KoinScope _koinScope;
  late String _activeScopeName;

  /// Уникальное имя scope для этого экрана / поддерева.
  String get scopeName;

  /// Нужно ли пересоздавать scope, если scopeName изменился.
  @protected
  bool get recreateScopeOnNameChange => true;

  /// Текущий scope.
  @protected
  KoinScope get koinScope => _koinScope;

  @protected
  TDep scopeGet<TDep>() => _koinScope.get<TDep>();

  @protected
  Widget withKoinScope(Widget child) {
    return KoinScopeProvider(scope: _koinScope, child: child);
  }

  @override
  void initState() {
    super.initState();
    _activeScopeName = scopeName;
    _koinScope = createScope(_activeScopeName);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!recreateScopeOnNameChange) {
      return;
    }

    final nextScopeName = scopeName;

    if (nextScopeName == _activeScopeName) {
      return;
    }

    final newScope = createScope(nextScopeName);

    final oldScopeName = _activeScopeName;

    _koinScope = newScope;
    _activeScopeName = nextScopeName;

    unawaited(_deleteScopeSafely(oldScopeName));
  }

  Future<void> _deleteScopeSafely(String name) async {
    try {
      await deleteScope(name);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'flutter_koin',
          context: ErrorDescription(
            'while disposing Koin scope "$name"',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_deleteScopeSafely(_activeScopeName));
    super.dispose();
  }
}
