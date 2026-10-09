import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/koin_scope.dart';
import '../dsl/koin_dsl.dart';
import 'koin_scope_provider.dart';

class KoinScopeHost extends StatefulWidget {
  final String scopeName;
  final Widget child;

  /// Если имя scope изменится, старый scope будет удалён,
  /// а новый создан заново.
  final bool recreateOnScopeNameChange;

  const KoinScopeHost({
    super.key,
    required this.scopeName,
    required this.child,
    this.recreateOnScopeNameChange = true,
  });

  @override
  State<KoinScopeHost> createState() => _KoinScopeHostState();
}

class _KoinScopeHostState extends State<KoinScopeHost> {
  late KoinScope _scope;
  late String _activeScopeName;

  @override
  void initState() {
    super.initState();
    _activeScopeName = widget.scopeName;
    _scope = createScope(_activeScopeName);
  }

  @override
  void didUpdateWidget(covariant KoinScopeHost oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.recreateOnScopeNameChange) {
      return;
    }

    final nextScopeName = widget.scopeName;

    if (nextScopeName == _activeScopeName) {
      return;
    }

    final newScope = createScope(nextScopeName);

    final oldScopeName = _activeScopeName;

    _scope = newScope;
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

  @override
  Widget build(BuildContext context) {
    return KoinScopeProvider(scope: _scope, child: widget.child);
  }
}
