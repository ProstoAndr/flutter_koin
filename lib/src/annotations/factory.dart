/// Annotation for factory dependencies.
/// A new object is created on every request.
class Factory {
  final List<Type> bindAs;

  const Factory({this.bindAs = const []});
}
