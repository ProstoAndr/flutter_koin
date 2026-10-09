import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:flutter_koin/src/generator/koin_generator.dart';
import 'package:test/test.dart';
import 'package:source_gen/source_gen.dart';

const _assetId = 'flutter_koin|lib/_generator_test_input.dart';

class _NoopBuildStep implements BuildStep {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<String?> _generate(String declaration) {
  return resolveSources(
    {
      _assetId: '''
import 'package:flutter_koin/flutter_koin.dart';

$declaration
''',
    },
    (resolver) async {
      final library = await resolver.libraryFor(
        AssetId('flutter_koin', 'lib/_generator_test_input.dart'),
      );

      return KoinGenerator().generate(LibraryReader(library), _NoopBuildStep());
    },
    rootPackage: 'flutter_koin',
    readAllSourcesFromFilesystem: true,
  );
}

Future<void> _expectInvalid(String source, String message) async {
  await expectLater(
    _generate(source),
    throwsA(
      isA<InvalidGenerationSourceError>().having(
        (error) => error.toString(),
        'error',
        contains(message),
      ),
    ),
  );
}

void main() {
  group('KoinGenerator: validation', () {
    test('rejects multiple lifecycle annotations', () async {
      await _expectInvalid('''
@Factory()
@Scoped()
class Service {
  Service();
}
''', 'cannot have multiple Koin lifecycle annotations');
    });

    test('rejects annotations on non-class elements', () async {
      await _expectInvalid('''
@Factory()
int createService() => 1;
''', 'can only be applied to classes');
    });

    test('rejects a generic class', () async {
      await _expectInvalid('''
@Scoped()
class Cache<T> {
  Cache();
}
''', 'Generic classes are not supported');
    });

    test('rejects a class without an unnamed constructor', () async {
      await _expectInvalid('''
@Factory()
class Service {
  Service.named();
}
''', 'must have an unnamed constructor');
    });

    test('rejects an abstract class', () async {
      await _expectInvalid('''
@RootScoped()
abstract class Service {
  Service();
}
''', 'Cannot instantiate abstract class');
    });

    test('rejects required dynamic injection', () async {
      await _expectInvalid('''
@Factory()
class Service {
  Service(dynamic value);
}
''', 'Cannot inject parameter');
    });

    test('rejects duplicate bindAs entries', () async {
      await _expectInvalid('''
abstract class Repository {}

@Factory(bindAs: [Repository, Repository])
class RepositoryImpl implements Repository {
  RepositoryImpl();
}
''', 'Duplicate bindAs type');
    });

    for (final lifecycle in ['Factory', 'Scoped', 'RootScoped']) {
      test('rejects unrelated bindAs for $lifecycle', () async {
        await _expectInvalid('''
abstract class Repository {}

@$lifecycle(bindAs: [Repository])
class WrongService {
  WrongService();
}
''', 'is not a subtype of');
      });
    }
  });

  group('KoinGenerator: output', () {
    test('returns null if nothing is annotated', () async {
      final output = await _generate('''
class Service {}
''');

      expect(output, isNull);
    });

    test('registers a no-argument Factory', () async {
      final output = await _generate('''
@Factory()
class Service {
  Service();
}
''');

      expect(output, contains('registerFactory<Service>'));

      expect(output, contains('() => Service()'));
    });

    test('injects positional dependencies into Factory', () async {
      final output = await _generate('''
class Repository {}

@Factory()
class Controller {
  Controller(Repository repository);
}
''');

      expect(output, contains('registerFactoryWithScope<Controller>'));

      expect(output, contains('scope.get<Repository>()'));
    });

    test('injects named dependencies into Scoped', () async {
      final output = await _generate('''
class Repository {}

@Scoped()
class Controller {
  Controller({required Repository repository});
}
''');

      expect(output, contains('registerScopedWithScope<Controller>'));

      expect(output, contains('repository: scope.get<Repository>()'));
    });

    test('RootScoped injection uses the root container', () async {
      final output = await _generate('''
class AppConfig {}

@RootScoped()
class Service {
  Service(AppConfig config);
}
''');

      expect(output, contains('registerRootScoped<Service>'));

      expect(output, contains('c.get<AppConfig>()'));
    });

    test('optional parameters are not injected', () async {
      final output = await _generate('''
@Factory()
class Service {
  Service({String name = 'default'});
}
''');

      expect(output, contains('registerFactory<Service>'));

      expect(output, contains('() => Service()'));

      expect(output, isNot(contains('get<String>()')));
    });

    for (final lifecycle in ['Factory', 'Scoped', 'RootScoped']) {
      test('generates valid bindAs for $lifecycle', () async {
        final output = await _generate('''
abstract class Repository {}

@$lifecycle(bindAs: [Repository])
class RepositoryImpl implements Repository {
  RepositoryImpl();
}
''');

        expect(output, contains('bindAs: [Repository]'));
      });
    }

    test('generates mixed lifecycle registrations', () async {
      final output = await _generate('''
@Factory()
class A {
  A();
}

@Scoped()
class B {
  B();
}

@RootScoped()
class C {
  C();
}
''');

      expect(output, contains('registerFactory<A>'));

      expect(output, contains('registerScoped<B>'));

      expect(output, contains('registerRootScoped<C>'));
    });
  });
}
