
import 'package:mono_localization/mono_localization.dart';
import 'package:mono_localization/src/config/pubspec_config.dart';
import 'package:mono_localization/src/constants/constants.dart';
import 'package:mono_localization/src/generator/generator_exception.dart';
import 'package:mono_localization/src/utils/labels_preserver.dart';
import 'package:mono_localization/src/utils/utils.dart';

Future<void> main(List<String> args) async {
  try {
    final config = PubspecConfig();
    final details = config.localizationDetails;
    if (details == null) {
      throw Exception('no structure initialized');
    }
    final baseClassName = config.baseClassName ?? defaultBaseClassName;
    final baseClassPath = config.baseClassPath ?? defaultBaseClassPath;
    await Generator.generateBaseClass(
        baseClassPath: baseClassPath, baseClassName: baseClassName,);
    for (final detailItem in details) {
      final generator = Generator(
        details: detailItem,
        baseClassName: baseClassName,
        baseClassPath: baseClassPath,
        mainLocale: config.mainLocale,
        useDeferredLoading: config.useDeferredLoading,
      );
      await generator.generateAsync();
    }
    await Generator.generateWidget(
      labels: LabelsPreserver().labels,
      widgetPath: config.widgetPath ?? defaultWidgetPath,
      baseClassName: baseClassName,
      baseClassPath: baseClassPath,
    );
  } on GeneratorException catch (e) {
    exitWithError(e.message);
  } catch (e) {
    exitWithError('Failed to generate localization files.\n$e');
  }
}
