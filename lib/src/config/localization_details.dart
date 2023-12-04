import 'package:mono_localization/src/constants/constants.dart';
import 'package:mono_localization/src/utils/yaml_parser_utils.dart';
import 'package:yaml/yaml.dart';

/// Represents the details required for localization.
class LocalizationDetails {
  const LocalizationDetails({
    required this.base,
    required this.arbDir,
    required this.outputDir,
    required this.libraryName,
    required this.widgetName,
    required this.widgetPath,
  });

  /// Factory method to create a [LocalizationDetails] object from a YAML map.
  ///
  /// [yamlMap] represents the YAML map containing localization details. Returns
  /// a [LocalizationDetails] object constructed from the provided [yamlMap].
  factory LocalizationDetails.fromMap(YamlMap yamlMap) {
    final base = typify<bool>(
      yamlMap['base'],
      defaultBasePackage,
    );
    final arbDir = typify<String>(
      yamlMap['arb_dir'],
      defaultArbDir,
    );
    final outputDir = typify<String>(
      yamlMap['output_dir'],
      defaultOutputDir,
    );
    final libraryName = typify<String>(
      yamlMap['library_name'],
      defaultClassName,
    );
    final widgetName = typify<String>(
      yamlMap['widget_name'],
      defaultWidgetName(libraryName),
    );
    final widgetPath = typify<String>(
      yamlMap['widget_path'],
      defaultWidgetPath,
    );

    return LocalizationDetails(
      base: base,
      arbDir: arbDir,
      outputDir: outputDir,
      libraryName: libraryName,
      widgetName: widgetName,
      widgetPath: widgetPath,
    );
  }

  /// Either library could be overridden by other libraries.
  ///
  /// If the library is marked as [base], a widget with all strings for this
  /// library will be generated for it.
  final bool base;

  ///Path to directory with arb files.
  final String arbDir;

  ///Path to directory with generated files.
  final String outputDir;

  ///Name of library.
  final String libraryName;

  /// Returns name for library provider widget.
  final String widgetName;

  /// Returns path for library provider widget.
  final String widgetPath;
}
