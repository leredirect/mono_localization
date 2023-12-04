import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

/// Gets the root directory path.
String getRootDirectoryPath() => getRootDirectory().path;

/// Gets the root directory.
///
/// Note: The current working directory is assumed to be the root of a project.
Directory getRootDirectory() => Directory.current;

/// Gets the pubspec file.
File? getPubspecFile() {
  final rootDirPath = getRootDirectoryPath();
  final pubspecFilePath = path.join(rootDirPath, 'pubspec.yaml');
  final pubspecFile = File(pubspecFilePath);

  return pubspecFile.existsSync() ? pubspecFile : null;
}

/// Gets arb file for the given locale.
File? getArbFileForLocale(String locale, String arbDir) {
  final rootDirPath = getRootDirectoryPath();
  final arbFilePath = path.join(rootDirPath, arbDir, 'intl_$locale.arb');
  final arbFile = File(arbFilePath);

  return arbFile.existsSync() ? arbFile : null;
}

/// Creates arb file for the given locale.
Future<File> createArbFileForLocale(String locale, String arbDir) async {
  final rootDirPath = getRootDirectoryPath();
  final arbFilePath = path.join(rootDirPath, arbDir, 'intl_$locale.arb');
  final arbFile = File(arbFilePath);

  await arbFile.create(recursive: true);
  await arbFile.writeAsString('{}');

  return arbFile;
}

/// Gets all arb files in the project.
List<FileSystemEntity> getArbFiles(String arbDir) {
  final l10nDirPath = path.join(getRootDirectoryPath(), arbDir);
  final arbFiles = Directory(l10nDirPath)
      .listSync()
      .where((file) =>
          path.basename(file.path).startsWith('intl_') &&
          path.basename(file.path).endsWith('.arb'),)
      .toList();

  // arb files order is not the same on all operating systems (e.g. win, mac)
  arbFiles.sort((a, b) => a.path.compareTo(b.path));

  return arbFiles;
}

/// Gets all locales in the project.
List<String> getLocales(String arbDir) {
  final locales = getArbFiles(arbDir)
      .map((file) => path.basename(file.path))
      .map((fileName) =>
          fileName.substring('intl_'.length, fileName.length - '.arb'.length),)
      .toList();

  return locales;
}

/// Updates arb file content.
Future<void> updateArbFile(
    String fileName, Uint8List bytes, String arbDir,) async {
  final rootDirPath = getRootDirectoryPath();
  final arbFilePath = path.join(rootDirPath, arbDir, fileName);
  final arbFile = File(arbFilePath);

  if (!arbFile.existsSync()) {
    await arbFile.create();
  }

  await arbFile.writeAsBytes(bytes);
}

/// Gets l10n Dart file path.
String getL10nDartFilePath(String outputDir) =>
    path.join(getRootDirectoryPath(), outputDir, 'l10n.dart');

/// Updates l10n Dart file.
Future<void> updateL10nDartFile(String content, String outputDir) async {
  final l10nDartFilePath = getL10nDartFilePath(outputDir);
  final l10nDartFile = File(l10nDartFilePath);

  if (!l10nDartFile.existsSync()) {
    await l10nDartFile.create(recursive: true);
  }

  await l10nDartFile.writeAsString(content);
}

/// Gets intl directory path.
String getIntlDirectoryPath(String outputDir) =>
    path.join(getRootDirectoryPath(), outputDir, 'intl');

/// Gets intl directory.
Directory? getIntlDirectory(String outputDir) {
  final intlDirPath = getIntlDirectoryPath(outputDir);
  final intlDir = Directory(intlDirPath);

  return intlDir.existsSync() ? intlDir : null;
}

/// Creates intl directory.
Future<Directory> createIntlDirectory(String outputDir) async {
  final intlDirPath = getIntlDirectoryPath(outputDir);
  final intlDir = Directory(intlDirPath);

  if (!intlDir.existsSync()) {
    await intlDir.create(recursive: true);
  }

  return intlDir;
}

/// Removes unused generated Dart files.
Future<void> removeUnusedGeneratedDartFiles(
    List<String> locales, String outputDir,) async {
  final intlDir = getIntlDirectory(outputDir);
  if (intlDir == null) {
    return;
  }

  final files = intlDir.listSync();
  for (final file in files) {
    final basename = path.basename(file.path);
    final substring = basename.substring(
        'messages_'.length, basename.length - '.dart'.length,);

    if (basename.startsWith('messages_') &&
        basename.endsWith('.dart') &&
        !['all', ...locales].contains(substring)) {
      await file.delete(recursive: true);
    }
  }
}

/// Gets Localizely credentials file path.
String? getLocalizelyCredentialsFilePath() {
  final userHome = getUserHome();
  if (userHome == null) {
    return null;
  }

  return path.join(userHome, '.localizely', 'credentials.yaml');
}

/// Gets Localizely credentials file.
File? getLocalizelyCredentialsFile() {
  final credentialsFilePath = getLocalizelyCredentialsFilePath();
  if (credentialsFilePath == null) {
    return null;
  }

  final credentialsFile = File(credentialsFilePath);

  return credentialsFile.existsSync() ? credentialsFile : null;
}

/// Gets the user home directory path.
String? getUserHome() {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['HOME'];
  } else if (Platform.isWindows) {
    return Platform.environment['USERPROFILE'];
  } else {
    return null;
  }
}
