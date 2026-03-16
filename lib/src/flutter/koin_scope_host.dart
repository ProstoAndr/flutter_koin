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

    if (oldWidget.scopeName == widget.scopeName) {
      return;
    }

    final oldScopeName = _activeScopeName;
    _activeScopeName = widget.scopeName;
    _scope = createScope(_activeScopeName);

    unawaited(deleteScope(oldScopeName));
  }

  @override
  void dispose() {
    unawaited(deleteScope(_activeScopeName));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KoinScopeProvider(scope: _scope, child: widget.child);
  }
}
