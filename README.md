# flutter_koin

![Flutter](https://img.shields.io/badge/Flutter-Dependency%20Injection-blue)

A lightweight, Koin-inspired dependency injection library for Flutter with **code generation**, **constructor injection
**, and **scope-aware lifecycles**.

`flutter_koin` generates dependency registrations from annotations, without runtime reflection. Use root-scoped services
for your app, feature scopes for screens and flows, and factories for short-lived objects.

## Features

- `@RootScoped()`, `@Scoped()`, and `@Factory()` lifetimes
- Registration code generation with `build_runner`
- Constructor injection for required positional and named parameters
- Interface bindings using `bindAs`
- Root and feature scopes with lifecycle-aware disposal
- Flutter integration through `KoinScopeHost`, `KoinScopeProvider`, and `KoinScopeMixin`

## Installation

Add the package and the build tool to your Flutter app:

```bash
flutter pub add flutter_koin
flutter pub add --dev build_runner
```

The generator is included in `flutter_koin`; no separate generator package is required.

## Quick start

### 1. Define dependencies

Create `lib/di/app_di.dart`:

```dart
import 'package:flutter_koin/flutter_koin.dart';

part 'app_di.koin.dart';

@RootScoped()
class ApiClient {
  String get status => 'Connected';
}

@Factory()
class UserRepository {
  UserRepository(this.client);

  final ApiClient client;
}
```

### 2. Generate registrations

From your project's root directory, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This creates `lib/di/app_di.koin.dart`, which defines `koinModule`. Keep the `part` directive in the source file and do
not edit generated code manually.

### 3. Start Koin

In `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_koin/flutter_koin.dart';
import 'di/app_di.dart' as app_di;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  startKoin([app_di.koinModule]);

  final repository = get<app_di.UserRepository>();
  debugPrint(repository.client.status);

  runApp(const MaterialApp(
    home: Scaffold(body: Center(child: Text('Hello, Koin!'))),
  ));
}
```

## Dependency lifetimes

| Annotation      | Lifetime                               | Resolution                                             |
|-----------------|----------------------------------------|--------------------------------------------------------|
| `@RootScoped()` | One shared instance per root container | Root or feature scope                                  |
| `@Scoped()`     | One shared instance per feature scope  | Feature scope only                                     |
| `@Factory()`    | A new instance on every request        | Root or feature scope, when dependencies are available |

### Feature scopes and constructor injection

Create `lib/di/checkout_di.dart`:

```dart
import 'package:flutter_koin/flutter_koin.dart';

part 'checkout_di.koin.dart';

@Scoped()
class CheckoutSession {}

@Factory()
class CheckoutController {
  CheckoutController(this.session);

  final CheckoutSession session;
}
```

Regenerate the code, import `di/checkout_di.dart` as `checkout_di` in `main.dart`, and include both modules in the
`startKoin` call: `startKoin([app_di.koinModule, checkout_di.koinModule]);`.

You can also create and dispose of a feature scope manually. For example, in an asynchronous function:

```dart
import 'package:flutter_koin/flutter_koin.dart';
import 'di/checkout_di.dart' as checkout_di;

Future<void> checkoutExample() async {
  final scope = createScope('checkout:42');
  try {
    final first = scope.get<checkout_di.CheckoutController>();
    final second = scope.get<checkout_di.CheckoutController>();

    assert(!identical(first, second));
    assert(identical(first.session, second.session));
  } finally {
    await deleteScope('checkout:42');
  }
}
```

The controllers are different factory instances, while their `CheckoutSession` is shared within the scope. A root-level
resolution cannot inject a feature-scoped dependency.

The generator also supports **required named constructor parameters**. Optional parameters retain their default values.

## Interface bindings

Use `bindAs` to expose a concrete implementation through an interface (for example, in `lib/di/analytics.dart`):

```dart
import 'package:flutter_koin/flutter_koin.dart';

part 'analytics.koin.dart';

abstract class AnalyticsService {
  void track(String event);
}

@RootScoped(bindAs: [AnalyticsService])
class ConsoleAnalytics implements AnalyticsService {
  @override
  void track(String event) => print(event);
}
```

After code generation, `get<AnalyticsService>()` and `get<ConsoleAnalytics>()` resolve to the same root-scoped instance.

## Flutter integration

`KoinScopeHost` creates a feature scope when mounted and disposes it when removed from the widget tree:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_koin/flutter_koin.dart';
import 'di/checkout_di.dart' as checkout_di;

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return KoinScopeHost(
      scopeName: 'checkout:42',
      child: Builder(
        builder: (context) {
          final controller =
          context.scopeGet<checkout_di.CheckoutController>();
          return Text('Session: ${controller.session.runtimeType}');
        },
      ),
    );
  }
}
```

Use a unique `scopeName` for each simultaneously active feature scope. For more control, use `KoinScopeProvider` or
`KoinScopeMixin`.

## Disposal and lifecycle

- Cached `@Scoped()` instances are disposed when their feature scope ends.
- Cached `@RootScoped()` instances are disposed when the root container stops.
- Dependencies can implement `KoinDisposable` or use an explicit disposer in manual registrations.
- `@Factory()` instances are not automatically tracked for disposal.
- Call `await stopKoin()` before restarting the global container.

## Limitations

- Generated factories and dependency resolution are synchronous. Initialize asynchronous resources before registration.
- The generator supports concrete, non-generic classes with unnamed constructors.
- Required positional and named parameters are injected; optional parameters are not.
- A root-scoped dependency cannot depend on a feature-scoped dependency.

If a `.koin.dart` file is missing, verify the `part` directive and rerun
`dart run build_runner build --delete-conflicting-outputs`.

## Example

See the [Flutter example application](example/lib/main.dart) for a complete example of using `flutter_koin`.

## License

See [LICENSE](LICENSE) for license information.
