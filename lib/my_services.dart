import 'package:flutter_koin/flutter_koin.dart'; // (там KoinContainer, KoinScope и т.д.)
import 'package:flutter_koin/src/annotations/factory.dart';
import 'package:flutter_koin/src/annotations/scoped.dart';

part 'my_services.koin.dart';

@Factory()
class MyService {
  void doSomething() => print("Doing something...");
}

@Scoped()
class MyScopedService {
  void doScopedWork() => print("Working in scope...");
}