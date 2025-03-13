import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

// Подключаем аннотации:
import '../annotations/factory.dart';
import '../annotations/scoped.dart';
// Подключаем KoinModule (чтобы упомянуть в коде, если нужно)

/// Класс-генератор, который ищет @Factory() и @Scoped() в коде,
/// и генерирует .koin.dart со строками registerFactory / registerScoped.
class KoinGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    // Шапка с комментариями
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// *************************************************');
    buffer.writeln('// Flutter Koin Dependency Injection Codegen');
    buffer.writeln('// *************************************************');
    buffer.writeln();

    // Объявляем единый koinModule
    buffer.writeln('final koinModule = KoinModule()');

    // Ищем аннотации @Factory
    for (final annotated in library.annotatedWith(TypeChecker.fromRuntime(Factory))) {
      final element = annotated.element;
      if (element is ClassElement) {
        final className = element.name;
        buffer.writeln("  ..register((c) => c.registerFactory<$className>(() => $className()))");
      }
    }

    // Ищем аннотации @Scoped
    for (final annotated in library.annotatedWith(TypeChecker.fromRuntime(Scoped))) {
      final element = annotated.element;
      if (element is ClassElement) {
        final className = element.name;
        buffer.writeln("  ..register((c) => c.registerScoped<$className>(() => $className()))");
      }
    }

    // Завершаем каскадную цепочку
    buffer.writeln(';');

    return buffer.toString();
  }
}

/// Метод, который нужно указать в build.yaml, чтобы source_gen знал о KoinGenerator.
Builder koinGeneratorFactory(BuilderOptions options) =>
    PartBuilder([KoinGenerator()], '.koin.dart');
