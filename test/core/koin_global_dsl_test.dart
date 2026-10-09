import 'package:flutter_koin/flutter_koin.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/koin_fixtures.dart';

void main() {
  group('Global Koin DSL', () {
    test('startKoin loads modules and global get resolves dependencies', () async {
      final module = KoinModule()
        ..register((c) => c.registerRootScoped<AppLogger>(() => AppLogger()));
      startKoin([module]);
      try {
        expect(get<AppLogger>(), isA<AppLogger>());
        expect(identical(get<AppLogger>(), get<AppLogger>()), isTrue);
      } finally {
        await stopKoin();
      }
    });

    test('Starting an already started container is rejected', () async {
      startKoin([]);
      try {
        expect(() => startKoin([]), throwsA(anything));
      } finally {
        await stopKoin();
      }
    });
  });
}
