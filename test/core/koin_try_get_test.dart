import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('tryGet', () {
    test('Returns null when dependency is not registered', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      final scope = container.createScope('feature');

      expect(container.tryGet<MissingDependency>(), isNull);
      expect(scope.tryGet<MissingDependency>(), isNull);
    });

    test('Root returns null for a Scoped-only registration', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<TableSession>(() => TableSession(1));

      expect(container.tryGet<TableSession>(), isNull);
    });

    test('Returns cached RootScoped instance', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerRootScoped<AppLogger>(() => AppLogger());

      expect(identical(container.tryGet<AppLogger>(), container.get<AppLogger>()), isTrue);
    });

    test('Resolves a Scoped alias from a feature scope', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<TableSession>(
        () => TableSession(1),
        bindAs: [TableSessionContract],
      );
      final scope = container.createScope('feature');

      expect(
        identical(scope.tryGet<TableSessionContract>(), scope.get<TableSession>()),
        isTrue,
      );
    });

    test('Factory is still transient through tryGet', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var nextId = 0;
      container.registerFactory<ReceiptFactory>(() => ReceiptFactory(++nextId));

      final first = container.tryGet<ReceiptFactory>();
      final second = container.tryGet<ReceiptFactory>();

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(identical(first, second), isFalse);
    });

    test('Does not swallow exceptions thrown by a registered factory', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerFactory<AppLogger>(() => throw StateError('factory failed'));

      expect(() => container.tryGet<AppLogger>(), throwsStateError);
    });
  });
}
