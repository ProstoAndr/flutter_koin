import 'dart:async';

import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('KoinScopeObserver', () {
    test('Replays root and existing feature scopes when added', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.createScope('first');
      container.createScope('second');
      final observer = TestScopeObserver();

      container.addScopeObserver(observer);

      expect(observer.events, [
        'created:__root__',
        'created:first',
        'created:second',
      ]);
    });

    test('Can disable replay of existing scopes', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.createScope('existing');
      final observer = TestScopeObserver();
      container.addScopeObserver(observer, replayCurrentScopes: false);

      expect(observer.events, isEmpty);
      container.createScope('new');
      expect(observer.events, ['created:new']);
    });

    test('Notifies creation and disposal', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final observer = TestScopeObserver();
      container.addScopeObserver(observer, replayCurrentScopes: false);

      container.createScope('feature');
      await container.deleteScope('feature');

      expect(observer.events, ['created:feature', 'disposed:feature']);
    });

    test('Does not add the same observer twice', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final observer = TestScopeObserver();
      container.addScopeObserver(observer, replayCurrentScopes: false);
      container.addScopeObserver(observer, replayCurrentScopes: false);

      container.createScope('feature');

      expect(observer.events, ['created:feature']);
    });

    test('Removing an observer stops notifications', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final observer = TestScopeObserver();
      container.addScopeObserver(observer, replayCurrentScopes: false);
      container.removeScopeObserver(observer);

      container.createScope('feature');

      expect(observer.events, isEmpty);
    });

    test('An observer that fails during replay is removed', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final observer = TestScopeObserver(
        onCreated: (_) => throw StateError('replay failed'),
      );

      expect(() => container.addScopeObserver(observer), throwsStateError);
      container.createScope('feature');

      expect(observer.events, ['created:__root__']);
    });

    test('Creation failure rolls back the scope and notifies disposal', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final rollbackNotified = Completer<void>();
      final observer = TestScopeObserver(
        onCreated: (_) => throw StateError('create failed'),
        onDisposed: (scope) {
          if (scope.name == 'broken' && !rollbackNotified.isCompleted) {
            rollbackNotified.complete();
          }
        },
      );
      container.addScopeObserver(observer, replayCurrentScopes: false);

      expect(() => container.createScope('broken'), throwsStateError);
      expect(container.activeScopeNames, isNot(contains('broken')));
      await rollbackNotified.future;
      await Future<void>.delayed(Duration.zero);
      container.removeScopeObserver(observer);

      expect(container.createScope('broken').name, 'broken');
      expect(observer.events, ['created:broken', 'disposed:broken']);
    });

    test('A throwing observer does not prevent other disposal observers', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final failing = TestScopeObserver(
        onDisposed: (_) => throw StateError('observer failed'),
      );
      final healthy = TestScopeObserver();
      container.addScopeObserver(failing, replayCurrentScopes: false);
      container.addScopeObserver(healthy, replayCurrentScopes: false);
      container.createScope('feature');

      await expectLater(container.deleteScope('feature'), throwsStateError);
      expect(healthy.events, ['created:feature', 'disposed:feature']);
      expect(container.activeScopeNames, isNot(contains('feature')));

      // Remove the throwing observer so tearDown can dispose the root normally.
      container.removeScopeObserver(failing);
    });

    test('Container disposal notifies feature before root', () async {
      final container = KoinContainer();
      final observer = TestScopeObserver();
      container.addScopeObserver(observer, replayCurrentScopes: false);
      container.createScope('feature');

      await container.dispose();

      expect(observer.events, [
        'created:feature',
        'disposed:feature',
        'disposed:__root__',
      ]);
    });
  });
}
