/// Throws in case generator errors.
class GeneratorException implements Exception {
  GeneratorException(this.message);

  /// Returns exception message.
  final String message;

  @override
  String toString() => 'GeneratorException: $message';
}
