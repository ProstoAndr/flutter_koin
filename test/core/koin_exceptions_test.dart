import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('Koin errors', () {
    test('Missing dependency throws KoinDependencyNotFoundException', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);

      expect(
        () => container.get<MissingDependency>(),
        throwsA(isA<KoinDependencyNotFoundException>()),
      );
    });

    test('Missing dependency in feature scope throws', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final scope = container.createScope('feature');

      expect(
        () => scope.get<MissingDependency>(),
        throwsA(isA<KoinDependencyNotFoundException>()),
      );
    });

    test(
      'Root cannot resolve a dependency registered only as Scoped',
      () async {
        final container = KoinContainer();
        addTearDown(container.dispose);
        container.registerScoped<TableSession>(() => TableSession(1));

        expect(
          () => container.get<TableSession>(),
          throwsA(isA<KoinDependencyNotFoundException>()),
        );
      },
    );

    test('getScope throws for a nonexistent name', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);

      expect(() => container.getScope('unknown'), throwsException);
    });

    test('Duplicate scope name is rejected', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.createScope('feature');

      expect(() => container.createScope('feature'), throwsStateError);
    });

    test('Empty and reserved scope names are rejected', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);

      expect(() => container.createScope(''), throwsArgumentError);
      expect(() => container.createScope('   '), throwsArgumentError);
      expect(() => container.createScope('__root__'), throwsArgumentError);
    });

    test('Disposed scope rejects get, has and tryGet', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<TableSession>(() => TableSession(1));
      final scope = container.createScope('feature');
      await container.deleteScope('feature');

      expect(() => scope.get<TableSession>(), throwsStateError);
      expect(() => scope.has<TableSession>(), throwsStateError);
      expect(() => scope.tryGet<TableSession>(), throwsStateError);
    });

    test('Disposed container rejects new work', () async {
      final container = KoinContainer();
      await container.dispose();

      expect(() => container.get<AppLogger>(), throwsStateError);
      expect(() => container.tryGet<AppLogger>(), throwsStateError);
      expect(() => container.createScope('feature'), throwsStateError);
      expect(() => container.getScope('feature'), throwsStateError);
      expect(
        () => container.registerFactory<AppLogger>(() => AppLogger()),
        throwsStateError,
      );
      expect(() => container.loadModule(KoinModule()), throwsStateError);
    });
  });
}
