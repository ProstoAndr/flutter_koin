import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('registerFactoryWithScope', () {
    test('Factory receives the feature scope for constructor injection', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      var nextId = 0;
      container.registerScoped<TableSession>(() => TableSession(++nextId));
      container.registerFactoryWithScope<ScopedAwareFactory>(
        (scope) => ScopedAwareFactory(scope.get<TableSession>()),
      );
      final scope = container.createScope('feature');

      final first = scope.get<ScopedAwareFactory>();
      final second = scope.get<ScopedAwareFactory>();

      expect(identical(first, second), isFalse);
      expect(identical(first.session, second.session), isTrue);
      expect(identical(first.session, scope.get<TableSession>()), isTrue);
    });

    test('Root cannot create a factory requiring a feature-only dependency', () async {
      final container = KoinContainer();
      addTearDown(container.dispose);
      container.registerScoped<TableSession>(() => TableSession(1));
      container.registerFactoryWithScope<ScopedAwareFactory>(
        (scope) => ScopedAwareFactory(scope.get<TableSession>()),
      );

      expect(
        () => container.get<ScopedAwareFactory>(),
        throwsA(isA<KoinDependencyNotFoundException>()),
      );
    });
  });
}
