import 'package:flutter/widgets.dart';

import '../core/koin_scope.dart';

class KoinScopeProvider extends InheritedWidget {
  final KoinScope scope;

  const KoinScopeProvider({
    super.key,
    required this.scope,
    required super.child,
  });

  static KoinScope of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<KoinScopeProvider>();

    if (provider == null) {
      throw FlutterError(
        'KoinScopeProvider not found in widget tree. '
        'Wrap your subtree with KoinScopeHost or KoinScopeProvider.',
      );
    }

    return provider.scope;
  }

  static KoinScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<KoinScopeProvider>()
        ?.scope;
  }

  @override
  bool updateShouldNotify(KoinScopeProvider oldWidget) {
    return oldWidget.scope != scope;
  }
}

extension KoinScopeBuildContextX on BuildContext {
  KoinScope get koinScope => KoinScopeProvider.of(this);

  KoinScope? get maybeKoinScope => KoinScopeProvider.maybeOf(this);

  T scopeGet<T>() => koinScope.get<T>();
}
