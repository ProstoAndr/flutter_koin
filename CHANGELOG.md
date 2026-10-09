# Changelog

All notable changes to `flutter_koin` will be documented in this file.

This project follows [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-09

### Added

- Dependency injection container with root and feature scopes.
- Three dependency lifetimes: `@RootScoped`, `@Scoped`, and `@Factory`.
- Annotation-based registration generation using `build_runner` and `.koin.dart` files.
- Constructor injection for required positional and named parameters.
- Interface bindings through the `bindAs` annotation parameter.
- Scope-aware dependency resolution and feature scope lifecycle management.
- Flutter integration with `KoinScopeHost`, `KoinScopeProvider`, and `KoinScopeMixin`.
- Automatic disposal of cached root-scoped and scoped instances, with support for `KoinDisposable` and custom disposers.
- Scope lifecycle observers and dependency resolution errors.
- Unit tests for the container and generator, plus integration tests for generated registrations.
