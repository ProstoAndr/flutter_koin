import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

import 'package:flutter_koin/src/annotations/factory.dart';
import 'package:flutter_koin/src/annotations/scoped.dart';

class KoinGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    // -- Пролог: какие-то комментарии (они не мешают, так как это не директивы).
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// *************************************************');
    buffer.writeln('// Flutter Koin Dependency Injection Codegen');
    buffer.writeln('// *************************************************');

    // ВАЖНО: не пишем здесь "import ..."!
    // Потому что код будет включен в part-файл ('.koin.dart'),
    // а в part-файлах нельзя добавлять никакие import/part/library директивы.

    // Вместо этого сразу объявляем переменные, функции, классы:
    buffer.writeln('\nfinal koinModule = KoinModule()');

    // Генерация для аннотаций @Factory
    for (var annotatedElement in library.annotatedWith(TypeChecker.fromRuntime(Factory))) {
      final classElement = annotatedElement.element;
      if (classElement is ClassElement) {
        final className = classElement.name;
        // Добавляем строку каскадного вызова без точки с запятой
        buffer.writeln("  ..register((c) => c.registerFactory<$className>(() => $className()))");
      }
    }

    // Генерация для аннотаций @Scoped
    for (var annotatedElement in library.annotatedWith(TypeChecker.fromRuntime(Scoped))) {
      final classElement = annotatedElement.element;
      if (classElement is ClassElement) {
        final className = classElement.name;
        buffer.writeln("  ..register((c) => c.registerScoped<$className>(() => $className()))");
      }
    }

    // В конце каскадной цепочки ставим одну точку с запятой:
    buffer.writeln(";");

    return buffer.toString();
  }
}

/// Собственно, наш билдер:
Builder koinGeneratorFactory(BuilderOptions options) =>
    // PartBuilder говорит, что для каждого .dart файла создаём имя_файла.koin.dart.
PartBuilder(
  [KoinGenerator()],
  '.koin.dart',
);
