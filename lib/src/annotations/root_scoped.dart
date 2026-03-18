/// Annotation for root-scoped dependencies.
/// One object lives for the whole container lifecycle.
class RootScoped {
  final List<Type> bindAs;

  const RootScoped({this.bindAs = const []});
}
