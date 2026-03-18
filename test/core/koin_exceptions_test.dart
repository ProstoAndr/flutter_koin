import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_koin/flutter_koin.dart';

void main() {
  group('Koin exceptions', () {
    test('throws detailed error for missing dependency in root scope', () {
      final container = KoinContainer();

      expect(
            () => container.get<UnknownRootService>(),
        throwsA(
          isA<KoinDependencyNotFoundException>()
              .having(
                (exception) => exception.message,
            'message',
            contains('UnknownRootService'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Current scope: "__root__" (root).'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Lookup order:'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('1. root scope'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('2. factory'),
          ),
        ),
      );
    });

    test('throws detailed error for missing dependency in feature scope', () {
      final container = KoinContainer();
      final featureScope = container.createScope('dialog:42');

      expect(
            () => featureScope.get<UnknownFeatureService>(),
        throwsA(
          isA<KoinDependencyNotFoundException>()
              .having(
                (exception) => exception.message,
            'message',
            contains('UnknownFeatureService'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Current scope: "dialog:42" (feature).'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Lookup order:'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('1. feature scope'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('2. root scope'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('3. factory'),
          ),
        ),
      );
    });

    test('throws alias conflict error for root scoped aliases', () {
      final container = KoinContainer();

      container.registerRootScoped<FirstRepositoryImplementation>(
            () => FirstRepositoryImplementation(),
        bindAs: [RepositoryContract],
      );

      expect(
            () => container.registerRootScoped<SecondRepositoryImplementation>(
              () => SecondRepositoryImplementation(),
          bindAs: [RepositoryContract],
        ),
        throwsA(
          isA<KoinAliasConflictException>()
              .having(
                (exception) => exception.message,
            'message',
            contains('RepositoryContract'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('FirstRepositoryImplementation'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('SecondRepositoryImplementation'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('root scoped'),
          ),
        ),
      );
    });

    test('shows alias resolution in error message when alias is requested', () {
      final container = KoinContainer();
      final featureScope = container.createScope('chat:7');

      expect(
            () => featureScope.get<MissingSessionContract>(),
        throwsA(
          isA<KoinDependencyNotFoundException>()
              .having(
                (exception) => exception.message,
            'message',
            contains('MissingSessionContract'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Current scope: "chat:7" (feature).'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Lookup order:'),
          ),
        ),
      );
    });

    test('shows alias mapping in error message when alias points to missing concrete type', () {
      final container = KoinContainer();
      final featureScope = container.createScope('chat:99');

      container.registerScoped<PresentScopedService>(
            () => PresentScopedService(),
        bindAs: [PresentScopedContract],
      );

      expect(
            () => featureScope.get<AbsentScopedContract>(),
        throwsA(
          isA<KoinDependencyNotFoundException>()
              .having(
                (exception) => exception.message,
            'message',
            contains('AbsentScopedContract'),
          )
              .having(
                (exception) => exception.message,
            'message',
            contains('Current scope: "chat:99" (feature).'),
          ),
        ),
      );
    });
  });
}

abstract class RepositoryContract {}

class FirstRepositoryImplementation implements RepositoryContract {}

class SecondRepositoryImplementation implements RepositoryContract {}

class UnknownRootService {}

class UnknownFeatureService {}

abstract class MissingSessionContract {}

abstract class PresentScopedContract {}

class PresentScopedService implements PresentScopedContract {}

abstract class AbsentScopedContract {}