/// Exception, which throws in case parsing errors.
class ConfigException implements Exception {

  ConfigException(this.message);

  /// Returns exception message;
  final String message;

  @override
  String toString() => 'ConfigException: $message';
}
