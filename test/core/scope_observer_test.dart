import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

void main() {
  group('KoinScopeObserver', () {
    test('observer receives scope create and dispose events', () async {
      final container = KoinContainer();
      final observer = TestScopeObserver();

      container.addScopeObserver(observer);

      final scope = container.createScope('table:1');

      expect(observer.createdNames, contains('__root__'));
      expect(observer.createdNames, contains('table:1'));

      await container.deleteScope('table:1');

      expect(observer.disposedNames, contains('table:1'));

      await container.dispose();

      expect(observer.disposedNames, contains('__root__'));

      // Чтобы analyzer не ругался на неиспользуемую переменную
      expect(scope.name, 'table:1');
    });

    test('observer can be removed', () async {
      final container = KoinContainer();
      final observer = TestScopeObserver();

      container.addScopeObserver(observer);
      container.removeScopeObserver(observer);

      container.createScope('table:1');

      expect(observer.createdNames, contains('__root__'));
      expect(observer.createdNames, isNot(contains('table:1')));

      await container.dispose();
    });
  });
}

class TestScopeObserver extends KoinScopeObserver {
  final List<String> createdNames = [];
  final List<String> disposedNames = [];

  @override
  void onScopeCreated(KoinScope scope) {
    createdNames.add(scope.name);
  }

  @override
  void onScopeDisposed(KoinScope scope) {
    disposedNames.add(scope.name);
  }
}
