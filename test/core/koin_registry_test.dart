import 'dart:async';

import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('Scope registry and pending disposals', () {
    test('Cannot recreate a scope while its old instance is disposing', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final gate = Completer<void>();
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(onDispose: () => gate.future),
      );
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();

      final pending = container.deleteScope('feature');
      expect(() => container.createScope('feature'), throwsStateError);
      gate.complete();
      await pending;

      expect(container.createScope('feature').name, 'feature');
    });

    test('Repeated deleteScope returns the same pending operation', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final gate = Completer<void>();
      container.registerScoped<DisposableScopedResource>(
        () => DisposableScopedResource(onDispose: () => gate.future),
      );
      container.createScope('feature').get<DisposableScopedResource>();

      final first = container.deleteScope('feature');
      final second = container.deleteScope('feature');
      expect(identical(first, second), isTrue);
      gate.complete();
      await Future.wait([first, second]);
    });

    test('Deleting an unknown scope is harmless', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);

      await container.deleteScope('missing');
      await container.deleteScope('missing');
    });

    test('Container disposal waits for a pending scope disposal', () async {
      final container = KoinContainer();
      final gate = Completer<void>();
      final resource = DisposableScopedResource(onDispose: () => gate.future);
      container.registerScoped<DisposableScopedResource>(() => resource);
      container.createScope('feature').get<DisposableScopedResource>();

      final scopeDisposal = container.deleteScope('feature');
      final containerDisposal = container.dispose();
      gate.complete();
      await Future.wait([scopeDisposal, containerDisposal]);

      expect(resource.disposeCount, 1);
    });

    test('Container disposal continues after a feature disposer fails', () async {
      final container = KoinContainer();
      final good = DisposableScopedResource();
      final bad = DisposableSecondResource(
        onDispose: () async => throw StateError('feature disposal failed'),
      );
      final root = DisposableRootResource();
      container.registerScoped<DisposableScopedResource>(() => good);
      container.registerScoped<DisposableSecondResource>(() => bad);
      container.registerRootScoped<DisposableRootResource>(() => root);
      final scope = container.createScope('feature');
      scope.get<DisposableScopedResource>();
      scope.get<DisposableSecondResource>();
      container.get<DisposableRootResource>();

      await expectLater(container.dispose(), throwsStateError);

      expect(good.disposeCount, 1);
      expect(bad.disposeCount, 1);
      expect(root.disposeCount, 1);
    });

    test('Container dispose is idempotent', () async {
      final container = KoinContainer();
      final first = container.dispose();
      final second = container.dispose();

      expect(identical(first, second), isTrue);
      await Future.wait([first, second]);
    });
  });
}
