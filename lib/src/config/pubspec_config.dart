import 'package:mono_localization/src/config/config_exception.dart';
import 'package:mono_localization/src/config/localization_details.dart';
import 'package:mono_localization/src/constants/constants.dart';
import 'package:mono_localization/src/utils/file_utils.dart';
import 'package:mono_localization/src/utils/yaml_parser_utils.dart';
import 'package:yaml/yaml.dart';

///This class represents a model for Yaml configuration.
class PubspecConfig {
  ///This constructor receives a yaml file and converts it into a model
  PubspecConfig() {
    final pubspecFile = getPubspecFile();
    if (pubspecFile == null) {
      throw ConfigException("Can't find 'pubspec.yaml' file.");
    }

    final pubspecFileContent = pubspecFile.readAsStringSync();
    final pubspecYaml = loadYaml(pubspecFileContent);

    if (pubspecYaml is! YamlMap) {
      throw ConfigException(
        "Failed to extract config from the 'pubspec.yaml' file.\nExpected YAML "
        'map but got ${pubspecYaml.runtimeType}.',
      );
    }

    final flutterIntlConfig = pubspecYaml['flutter_intl'] as YamlMap?;

    if (flutterIntlConfig == null) {
      //TODO(kalinovsky): handle as exception.
      return;
    }

    final structureConfig = flutterIntlConfig['structure'];
    _enabled =
        typify<bool>(flutterIntlConfig['enabled'], defaultGenerationEnabled);

    _localizationDetails = [];
    if (structureConfig is YamlList) {
      for (final d in structureConfig) {
        _localizationDetails!.add(
          LocalizationDetails.fromMap(
            (d as YamlMap).map(MapEntry.new).values.first as YamlMap,
          ),
        );
      }
    }

    _mainLocale =
        typify<String>(flutterIntlConfig['main_locale'], defaultMainLocale);
    _baseClassName = typify<String>(
        flutterIntlConfig['base_class_name'], defaultBaseClassName);
    _widgetPath =
        typify<String>(flutterIntlConfig['widget_path'], defaultWidgetPath);
    _baseClassPath = typify<String>(
        flutterIntlConfig['base_class_path'], defaultBaseClassPath);
    _useDeferredLoading = typify<bool>(
        flutterIntlConfig['use_deferred_loading'], defaultUseDeferredLoading);
  }

  List<LocalizationDetails>? _localizationDetails;
  bool? _enabled;
  String? _mainLocale;
  String? _baseClassName;
  String? _baseClassPath;
  String? _widgetPath;
  bool? _useDeferredLoading;

  ///Enables pubspec parsing.
  bool? get enabled => _enabled;

  ///Provides name for base class from which localization
  ///libraries will be inherited.
  String? get baseClassName => _baseClassName;

  ///Provides path to base class from which localization
  ///libraries will be inherited.
  String? get baseClassPath => _baseClassPath;

  ///Provides path to widget, which injects localization in context.
  String? get widgetPath => _widgetPath;

  ///Provides details for each localization library.
  List<LocalizationDetails>? get localizationDetails => _localizationDetails;

  ///Provides main locale for all libraries.
  String? get mainLocale => _mainLocale;

  /// Returns a value, indicating whether deferred loading is used
  ///for localization libraries.
  ///TODO(kalinovsky): remove this getter.
  bool? get useDeferredLoading => _useDeferredLoading;
}
