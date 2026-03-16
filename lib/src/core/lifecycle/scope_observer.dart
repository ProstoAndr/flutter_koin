import '../koin_scope.dart';

abstract class KoinScopeObserver {
  void onScopeCreated(KoinScope scope) {}

  void onScopeDisposed(KoinScope scope) {}
}
