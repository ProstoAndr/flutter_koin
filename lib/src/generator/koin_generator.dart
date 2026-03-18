import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations/factory.dart';
import '../annotations/root_scoped.dart';
import '../annotations/scoped.dart';

class KoinGenerator extends Generator {
  static final TypeChecker _factoryChecker = TypeChecker.typeNamed(
    Factory,
    inPackage: 'flutter_koin',
  );

  static final TypeChecker _scopedChecker = TypeChecker.typeNamed(
    Scoped,
    inPackage: 'flutter_koin',
  );

  static final TypeChecker _rootScopedChecker = TypeChecker.typeNamed(
    RootScoped,
    inPackage: 'flutter_koin',
  );

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final registrations = <String>[];

    _collectFactoryRegistrations(
      registrations: registrations,
      library: library,
    );

    _collectScopedRegistrations(
      registrations: registrations,
      library: library,
    );

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

  void _collectFactoryRegistrations({
    required List<String> registrations,
    required LibraryReader library,
  }) {
    for (final annotated in library.annotatedWith(_factoryChecker)) {
      final element = annotated.element;
      if (element is! InterfaceElement) {
        continue;
      }

      final constructor = element.unnamedConstructor;
      if (constructor == null || !_canGenerateForConstructor(constructor)) {
        continue;
      }

      final className = element.name;
      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation);
      final bindAsArgument = _buildBindAsArgument(bindAsTypes);

      final invocation = _buildConstructorInvocation(
        className,
        constructor,
        resolverName: 'c',
      );

      registrations.add(
        'c.registerFactory<$className>(() => $invocation$bindAsArgument)',
      );
    }
  }

  void _collectScopedRegistrations({
    required List<String> registrations,
    required LibraryReader library,
  }) {
    for (final annotated in library.annotatedWith(_scopedChecker)) {
      final element = annotated.element;
      if (element is! InterfaceElement) {
        continue;
      }

      final constructor = element.unnamedConstructor;
      if (constructor == null || !_canGenerateForConstructor(constructor)) {
        continue;
      }

      final className = element.name;
      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation);
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
      if (element is! InterfaceElement) {
        continue;
      }

      final constructor = element.unnamedConstructor;
      if (constructor == null || !_canGenerateForConstructor(constructor)) {
        continue;
      }

      final className = element.name;
      if (className == null || className.isEmpty) {
        continue;
      }

      final bindAsTypes = _readBindAsTypes(annotated.annotation);
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

  List<String> _readBindAsTypes(ConstantReader annotationReader) {
    final bindAsReader = annotationReader.peek('bindAs');
    if (bindAsReader == null || bindAsReader.isNull) {
      return const [];
    }

    final result = <String>[];

    for (final constantValue in bindAsReader.listValue) {
      final dartType = constantValue.toTypeValue();
      if (dartType == null) {
        continue;
      }

      final typeName = dartType.getDisplayString();
      if (typeName.isEmpty) {
        continue;
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

  bool _canGenerateForConstructor(ConstructorElement constructor) {
    for (final parameter in constructor.formalParameters) {
      final isInjectable =
          parameter.isRequiredPositional || parameter.isRequiredNamed;

      if (!isInjectable) {
        continue;
      }

      if (!_isResolvableParameter(parameter)) {
        return false;
      }
    }

    return true;
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

    final arguments = <String>[
      ...positionalArguments,
      ...namedArguments,
    ];

    final joinedArguments = arguments
        .map((argument) => '      $argument')
        .join(',\n');

    return '$className(\n$joinedArguments,\n    )';
  }

  String _buildGetCall(
      FormalParameterElement parameter,
      String resolverName,
      ) {
    final typeName = parameter.type.getDisplayString();
    return '$resolverName.get<$typeName>()';
  }
}

Builder koinGeneratorFactory(BuilderOptions options) {
  return PartBuilder([KoinGenerator()], '.koin.dart');
}