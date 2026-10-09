import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/factory.dart';
import '../annotations/root_scoped.dart';
import '../annotations/scoped.dart';

class KoinGenerator extends Generator {
  static const TypeChecker _factoryChecker = TypeChecker.typeNamed(
    Factory,
    inPackage: 'flutter_koin',
  );

  static const TypeChecker _scopedChecker = TypeChecker.typeNamed(
    Scoped,
    inPackage: 'flutter_koin',
  );

  static const TypeChecker _rootScopedChecker = TypeChecker.typeNamed(
    RootScoped,
    inPackage: 'flutter_koin',
  );

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    _validateLifecycleAnnotations(library);

    final registrations = <String>[];

    _collectFactoryRegistrations(
      registrations: registrations,
      library: library,
    );

    _collectScopedRegistrations(registrations: registrations, library: library);

    _collectRootScopedRegistrations(
      registrations: registrations,
      library: library,
    );

    if (registrations.isEmpty) {
      return null;
    }

    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// *************************************************');
    buffer.writeln('// Flutter Koin Dependency Injection Codegen');
    buffer.writeln('// *************************************************');
    buffer.writeln();

    buffer.writeln('final koinModule = KoinModule()');

    for (final registration in registrations) {
      buffer.writeln('  ..register((c) => $registration)');
    }

    buffer.writeln(';');

    return buffer.toString();
  }

  void _validateLifecycleAnnotations(LibraryReader library) {
    for (final element in library.classes) {
      final annotationCount =
          [
            _factoryChecker.hasAnnotationOf(element),
            _scopedChecker.hasAnnotationOf(element),
            _rootScopedChecker.hasAnnotationOf(element),
          ].where((value) => value).length;

      if (annotationCount > 1) {
        throw InvalidGenerationSourceError(
          'Class "${element.name}" cannot have multiple '
          'Koin lifecycle annotations.',
          element: element,
        );
      }
    }
  }

  void _collectFactoryRegistrations({
    required List<String> registrations,
    required LibraryReader library,
  }) {
    for (final annotated in library.annotatedWith(_factoryChecker)) {
      final element = annotated.element;
      final constructor = _requireConstructor(element);

      final className = element.name;

      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation, element);
      final bindAsArgument = _buildBindAsArgument(bindAsTypes);

      final needsScope = _constructorHasInjectableParameters(constructor);

      final invocation = _buildConstructorInvocation(
        className,
        constructor,
        resolverName: needsScope ? 'scope' : 'c',
      );

      if (needsScope) {
        registrations.add(
          'c.registerFactoryWithScope<$className>('
          '(scope) => $invocation$bindAsArgument)',
        );
      } else {
        registrations.add(
          'c.registerFactory<$className>('
          '() => $invocation$bindAsArgument)',
        );
      }
    }
  }

  void _collectScopedRegistrations({
    required List<String> registrations,
    required LibraryReader library,
  }) {
    for (final annotated in library.annotatedWith(_scopedChecker)) {
      final element = annotated.element;
      final constructor = _requireConstructor(element);

      final className = element.name;
      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation, element);
      final bindAsArgument = _buildBindAsArgument(bindAsTypes);

      final needsScope = _constructorHasInjectableParameters(constructor);

      final invocation = _buildConstructorInvocation(
        className,
        constructor,
        resolverName: needsScope ? 'scope' : 'c',
      );

      if (needsScope) {
        registrations.add(
          'c.registerScopedWithScope<$className>((scope) => $invocation$bindAsArgument)',
        );
      } else {
        registrations.add(
          'c.registerScoped<$className>(() => $invocation$bindAsArgument)',
        );
      }
    }
  }

  void _collectRootScopedRegistrations({
    required List<String> registrations,
    required LibraryReader library,
  }) {
    for (final annotated in library.annotatedWith(_rootScopedChecker)) {
      final element = annotated.element;
      final constructor = _requireConstructor(element);

      final className = element.name;
      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation, element);
      final bindAsArgument = _buildBindAsArgument(bindAsTypes);

      final invocation = _buildConstructorInvocation(
        className,
        constructor,
        resolverName: 'c',
      );

      registrations.add(
        'c.registerRootScoped<$className>(() => $invocation$bindAsArgument)',
      );
    }
  }

  List<String> _readBindAsTypes(
    ConstantReader annotationReader,
    Element element,
  ) {
    final bindAsReader = annotationReader.peek('bindAs');

    if (bindAsReader == null || bindAsReader.isNull) {
      return const [];
    }

    final classElement = element as ClassElement;
    final typeSystem = classElement.library.typeSystem;

    final result = <String>[];

    for (final constantValue in bindAsReader.listValue) {
      final dartType = constantValue.toTypeValue();

      if (dartType == null) {
        throw InvalidGenerationSourceError(
          'bindAs must contain only valid Dart types.',
          element: element,
        );
      }

      final typeName = dartType.getDisplayString();

      if (typeName.isEmpty) {
        throw InvalidGenerationSourceError(
          'Cannot resolve a type from bindAs.',
          element: element,
        );
      }

      if (result.contains(typeName)) {
        throw InvalidGenerationSourceError(
          'Duplicate bindAs type "$typeName".',
          element: element,
        );
      }

      if (!typeSystem.isSubtypeOf(classElement.thisType, dartType)) {
        throw InvalidGenerationSourceError(
          'Class "${classElement.name}" is not a subtype of '
          '"$typeName" specified in bindAs.',
          element: element,
        );
      }

      result.add(typeName);
    }

    return result;
  }

  String _buildBindAsArgument(List<String> bindAsTypes) {
    if (bindAsTypes.isEmpty) {
      return '';
    }

    final joinedTypes = bindAsTypes.join(', ');
    return ', bindAs: [$joinedTypes]';
  }

  bool _constructorHasInjectableParameters(ConstructorElement constructor) {
    for (final parameter in constructor.formalParameters) {
      if (parameter.isRequiredPositional || parameter.isRequiredNamed) {
        return true;
      }
    }

    return false;
  }

  bool _isResolvableParameter(FormalParameterElement parameter) {
    final typeName = parameter.type.getDisplayString();

    return typeName != 'dynamic' && typeName != 'void';
  }

  String _buildConstructorInvocation(
    String className,
    ConstructorElement constructor, {
    required String resolverName,
  }) {
    final positionalArguments = <String>[];
    final namedArguments = <String>[];

    for (final parameter in constructor.formalParameters) {
      if (parameter.isRequiredPositional) {
        positionalArguments.add(_buildGetCall(parameter, resolverName));
      } else if (parameter.isRequiredNamed) {
        namedArguments.add(
          '${parameter.name}: ${_buildGetCall(parameter, resolverName)}',
        );
      }
    }

    if (positionalArguments.isEmpty && namedArguments.isEmpty) {
      return '$className()';
    }

    final arguments = <String>[...positionalArguments, ...namedArguments];

    final joinedArguments = arguments
        .map((argument) => '      $argument')
        .join(',\n');

    return '$className(\n$joinedArguments,\n    )';
  }

  String _buildGetCall(FormalParameterElement parameter, String resolverName) {
    final typeName = parameter.type.getDisplayString();
    return '$resolverName.get<$typeName>()';
  }

  ConstructorElement _requireConstructor(Element element) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Koin annotations can only be applied to classes.',
        element: element,
      );
    }

    if (element.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Generic classes are not supported by KoinGenerator.',
        element: element,
      );
    }

    final constructor = element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSourceError(
        'Class "${element.name}" must have an unnamed constructor.',
        element: element,
      );
    }

    if (element.isAbstract && !constructor.isFactory) {
      throw InvalidGenerationSourceError(
        'Cannot instantiate abstract class "${element.name}".',
        element: element,
      );
    }

    for (final parameter in constructor.formalParameters) {
      final isRequired =
          parameter.isRequiredPositional || parameter.isRequiredNamed;

      if (isRequired && !_isResolvableParameter(parameter)) {
        throw InvalidGenerationSourceError(
          'Cannot inject parameter "${parameter.name}" '
          'of type "${parameter.type.getDisplayString()}".',
          element: constructor,
        );
      }
    }

    return constructor;
  }
}

Builder koinGeneratorFactory(BuilderOptions options) {
  return PartBuilder([KoinGenerator()], '.koin.dart');
}
