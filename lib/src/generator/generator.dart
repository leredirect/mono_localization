import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:mono_localization/src/config/localization_details.dart';
import 'package:mono_localization/src/constants/constants.dart';
import 'package:mono_localization/src/generator/generator_exception.dart';
import 'package:mono_localization/src/generator/intl_translation_helper.dart';
import 'package:mono_localization/src/generator/label.dart';
import 'package:mono_localization/src/generator/templates.dart';
import 'package:mono_localization/src/utils/file_utils.dart';
import 'package:mono_localization/src/utils/labels_preserver.dart';
import 'package:mono_localization/src/utils/utils.dart';
import 'package:path/path.dart';

/// The generator of localization files.
class Generator {
  /// Creates a new generator with configuration from the 'pubspec.yaml' file.
  Generator({
    required LocalizationDetails details,
    required String baseClassName,
    required String baseClassPath,
    String? mainLocale,
    bool? useDeferredLoading,
    bool? otaEnabled,
  }) {
    _details = details;

    if (isValidClassName(baseClassName)) {
      _baseClassName = baseClassName;
    } else {
      warning(
        "Config parameter 'base_class_name' requires valid 'UpperCamelCase' "
        'value.',
      );
    }

    _baseClassPath = baseClassPath;

    _mainLocale = defaultMainLocale;
    if (mainLocale != null) {
      if (isValidLocale(mainLocale)) {
        _mainLocale = mainLocale;
      } else {
        warning(
          "Config parameter 'main_locale' requires value consisted of language "
          'code and optional script and country codes separated with '
          "underscore (e.g. 'en', 'en_GB', 'zh_Hans', 'zh_Hans_CN').",
        );
      }
    }

    _useDeferredLoading = useDeferredLoading ?? defaultUseDeferredLoading;

    _otaEnabled = otaEnabled ?? defaultOtaEnabled;
  }

  late LocalizationDetails _details;
  late String _baseClassName;
  late String _baseClassPath;
  late String _mainLocale;
  late bool _useDeferredLoading;
  late bool _otaEnabled;

  /// Generates localization files.
  Future<void> generateAsync() async {
    await _updateL10nDir();
    await _updateGeneratedDir();
    await _generateDartFiles();
    await _removeL10nFiles();
    if (_details.base) {
      await generateWidget(
        labels: LabelsPreserver().labels,
        widgetPath: _details.widgetPath,
        widgetName: _details.widgetName,
        baseClassName: _baseClassName,
        baseClassPath: _baseClassPath,
      );
    }
    LabelsPreserver().labels.clear();
  }

  Future<void> _updateL10nDir() async {
    final mainArbFile = getArbFileForLocale(_mainLocale, _details.arbDir);
    if (mainArbFile == null) {
      await createArbFileForLocale(_mainLocale, _details.arbDir);
    }
  }

  Future<void> _updateGeneratedDir() async {
    final labels = _getLabelsFromMainArbFile();
    final locales = _orderLocales(getLocales(_details.arbDir));
    final content = generateL10nDartFileContent(
        _details.libraryName, labels, locales, _otaEnabled);
    final formattedContent = formatDartContent(content, 'l10n.dart');

    await updateL10nDartFile(formattedContent, _details.outputDir);

    final intlDir = getIntlDirectory(_details.outputDir);
    if (intlDir == null) {
      await createIntlDirectory(_details.outputDir);
    }

    await removeUnusedGeneratedDartFiles(locales, _details.outputDir);
  }

  List<Label> _getLabelsFromMainArbFile() {
    final mainArbFile = getArbFileForLocale(_mainLocale, _details.arbDir);
    if (mainArbFile == null) {
      throw GeneratorException(
        "Can't find ARB file for the '$_mainLocale' locale.",
      );
    }

    final content = mainArbFile.readAsStringSync();
    final decodedContent = json.decode(content) as Map<String, dynamic>;

    final labels =
        decodedContent.keys.where((key) => !key.startsWith('@')).map((key) {
      final name = key;
      final content = decodedContent[key];

      final meta = decodedContent['@$key'] ?? <String, dynamic>{};
      final type = meta['type'];
      final description = meta['description'];
      final placeholders = meta['placeholders'] != null
          ? (meta['placeholders'] as Map<String, dynamic>)
              .keys
              .map(
                (placeholder) => Placeholder(
                  key,
                  placeholder,
                  meta['placeholders'][placeholder],
                ),
              )
              .toList()
          : null;

      return Label(
        name,
        content,
        type: type,
        description: description,
        placeholders: placeholders,
      );
    }).toList();
    if (_details.base) {
      LabelsPreserver().labels.addAll(labels);
    }
    return labels;
  }

  List<String> _orderLocales(List<String> locales) {
    final index = locales.indexOf(_mainLocale);
    return index != -1
        ? [
            locales.elementAt(index),
            ...locales.sublist(0, index),
            ...locales.sublist(index + 1),
          ]
        : locales;
  }

  Future<void> _generateDartFiles() async {
    final outputDir = getIntlDirectoryPath(_details.outputDir);
    final dartFiles = [getL10nDartFilePath(_details.outputDir)];
    final arbFiles =
        getArbFiles(_details.arbDir).map((file) => file.path).toList();

    IntlTranslationHelper(_useDeferredLoading).generateFromArb(
      outputDir,
      dartFiles,
      arbFiles,
      _details.libraryName,
      _baseClassName,
      _baseClassPath,
    );
  }

  Future<void> _removeL10nFiles() async {
    final file = File(getL10nDartFilePath(_details.outputDir));
    await file.delete();
  }

  static Future<void> generateBaseClass({
    required String baseClassPath,
    required String baseClassName,
  }) async {
    final file = File(baseClassPath);
    await file.create(recursive: true);
    await file.writeAsString(generateBaseClassContent(baseClassName));
  }

  Future<void> generateWidget({
    required List<Label> labels,
    required String widgetPath,
    required String widgetName,
    required String baseClassName,
    required String baseClassPath,
  }) async {
    final rawContent = generateInheritedWidgetContent(
      labels: labels,
      baseClassPath: relative(
        baseClassPath,
        from: widgetPath.replaceAll(basename(widgetPath), ''),
      ),
      baseClassName: baseClassName,
      name: widgetName,
    );

    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );
    final formattedContent = formatter.format(rawContent);
    final widgetFile = File(widgetPath);
    await widgetFile.writeAsString(formattedContent);
  }
}
