import 'koin_container.dart';

class KoinModule {
  final List<void Function(KoinContainer)> _registrations = [];
  void register(void Function(KoinContainer) callback) {
    _registrations.add(callback);
  }
  List<void Function(KoinContainer)> get registrations => _registrations;
}
