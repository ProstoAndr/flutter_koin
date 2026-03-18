/// Annotation for scoped dependencies.
/// One object lives inside one scope.
class Scoped {
  final List<Type> bindAs;

  const Scoped({this.bindAs = const []});
}
