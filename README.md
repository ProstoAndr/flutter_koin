# flutter_koin
A lightweight Koin-inspired dependency injection library for Flutter with code generation and scope-based lifecycle management.
![Flutter](https://img.shields.io/badge/Flutter-Dependency%20Injection-blue)

## Overview

`flutter_koin` helps you organize dependencies by lifetime, generate registration code from annotations, and bind feature-scoped objects to the Flutter widget tree.

## Features

- `@RootScoped`, `@Scoped`, `@Factory`
- Code generation with `build_runner`
- Root scope and feature scopes
- Constructor injection in generated registrations
- Flutter integration via `KoinScopeHost`, `KoinScopeProvider`, and `KoinScopeMixin`
- Automatic disposal of scoped and root-scoped dependencies
- Scope lifecycle observation

## Why flutter_koin

`flutter_koin` is built for Flutter apps that want a simple DI solution without runtime reflection.

It is designed around three dependency lifetimes:

- **RootScoped** — shared across the whole app
- **Scoped** — shared only while a feature scope is alive
- **Factory** — created on every request

This makes it easy to model application-wide services, screen-level state, and temporary helpers in a consistent way.

## Quick start

Add the package:

```yaml
dependencies:
  flutter_koin: ^1.0.0

dev_dependencies:
  build_runner: ^2.4.15
```
