class KoinDependencyNotFoundException implements Exception {
  final String message;

  const KoinDependencyNotFoundException(this.message);

  @override
  String toString() => 'KoinDependencyNotFoundException: $message';
}

class KoinAliasConflictException implements Exception {
  final String message;

  const KoinAliasConflictException(this.message);

  @override
  String toString() => 'KoinAliasConflictException: $message';
}
