import 'dart:async';

abstract class KoinDisposable {
  FutureOr<void> dispose();
}

typedef KoinDisposeCallback<T> = FutureOr<void> Function(T value);
