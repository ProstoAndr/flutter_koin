import 'dart:async';

import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('KoinScope lifecycle', () {
    test('clear disposes cached objects and permits fresh resolution', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(),
      );
      final scope = container.createScope('feature');
      final first = scope.get<DisposableScopedResource>();

      await scope.clear();
      final second = scope.get<DisposableScopedResource>();

      expect(first.disposeCount, 1);
      expect(identical(first, second), isFalse);
      expect(second.disposeCount, 0);
    });

    test('clear disposes dependencies in reverse creation order', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final order = <String>[];
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(onDispose: () async { order.add('first'); }),
      );
      container.registerScoped<DisposableSecondResource>(
        () => DisposableSecondResource(onDispose: () async { order.add('second'); }),
      );
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();
      scope.get<DisposableSecondResource>();

      await scope.clear();

      expect(order, ['second', 'first']);
    });

    test('clear continues cleanup after a disposer throws', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final first = DisposableScopedResource();
      final failing = DisposableSecondResource(
        onDispose: () async => throw StateError('dispose failed'),
      );
      container.registerScoped<DisposableScopedResource>(() => first);
      container.registerScoped<DisposableSecondResource>(() => failing);
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();
      scope.get<DisposableSecondResource>();

      await expectLater(scope.clear(), throwsStateError);

      expect(first.disposeCount, 1);
      expect(failing.disposeCount, 1);
    });

    test('Concurrent clear calls share the same operation', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final gate = Completer<void>();
      final resource = DisposableScopedResource(onDispose: () => gate.future);
      container.registerScoped<DisposableScopedResource>(() => resource);
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();

      final first = scope.clear();
      final second = scope.clear();
      expect(identical(first, second), isTrue);

      gate.complete();
      await Future.wait([first, second]);
      expect(resource.disposeCount, 1);
    });

    test('Resolution is rejected while clear is in progress', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final gate = Completer<void>();
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(onDispose: () => gate.future),
      );
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();

      final clearing = scope.clear();
      expect(() => scope.get<DisposableScopedResource>(), throwsStateError);
      gate.complete();
      await clearing;
      expect(scope.get<DisposableScopedResource>(), isA<DisposableScopedResource>());
    });

    test('Scope dispose is idempotent and rejects further resolution', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final resource = DisposableScopedResource();
      container.registerScoped<DisposableScopedResource>(() => resource);
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();

      final first = scope.dispose();
      final second = scope.dispose();
      expect(identical(first, second), isTrue);
      await first;

      expect(resource.disposeCount, 1);
      expect(() => scope.get<DisposableScopedResource>(), throwsStateError);
    });

    test('Starting container disposal immediately blocks scope resolution', () async {
      final container = KoinContainer();
      container.registerScoped<TableSession>(() => TableSession(1));
      final scope = container.createScope('feature');

      final disposal = container.dispose();
      expect(() => scope.get<TableSession>(), throwsStateError);
      await disposal;
    });
  });
}
