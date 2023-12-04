// This file incorporates work covered by the following copyright and
// permission notice:
//
//     Copyright 2013, the Dart project authors. All rights reserved.
//     Redistribution and use in source and binary forms, with or without
//     modification, are permitted provided that the following conditions are
//     met:
//
//         * Redistributions of source code must retain the above copyright
//           notice, this list of conditions and the following disclaimer.
//         * Redistributions in binary form must reproduce the above
//           copyright notice, this list of conditions and the following
//           disclaimer in the documentation and/or other materials provided
//           with the distribution.
//         * Neither the name of Google Inc. nor the names of its
//           contributors may be used to endorse or promote products derived
//           from this software without specific prior written permission.
//
//     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//     A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//     OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//     SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//     LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//     DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//     THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//     (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//     OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:convert';
import 'dart:io';

// Due to a delay in the maintenance of the 'intl_translation' package,
// we are using a partial copy of it with added support for the null-safety
import 'package:mono_localization/src/intl_translation/extract_messages.dart';
import 'package:mono_localization/src/intl_translation/generate_localized.dart';
import 'package:mono_localization/src/intl_translation/src/icu_parser.dart';
import 'package:mono_localization/src/intl_translation/src/intl_message.dart';
import 'package:mono_localization/src/utils/utils.dart';
import 'package:path/path.dart' as path;

class IntlTranslationHelper { // Track of all processed messages, keyed by message name

  IntlTranslationHelper([bool useDeferredLoading = false]) {
    extraction.suppressWarnings = true;
    generation.useDeferredLoading = useDeferredLoading;
    generation.generatedFilePrefix = '';
  }
  final pluralAndGenderParser = IcuParser().message;
  final plainParser = IcuParser().nonIcuMessage;
  final JsonCodec jsonDecoder = const JsonCodec();

  final MessageExtraction extraction = MessageExtraction();
  final MessageGeneration generation = MessageGeneration();
  final Map<String, List<MainMessage>> messages =
      {};

  void generateFromArb(
    String outputDir,
    List<String> dartFiles,
    List<String> arbFiles,
    String className,
    String baseClassName,
    String baseClassPath,
  ) {
    final allMessages = dartFiles.map((file) => extraction.parseFile(File(file)));
    for (final messageMap in allMessages) {
      messageMap.forEach(
          (key, value) => messages.putIfAbsent(key, () => []).add(value),);
    }

    final messagesByLocale = <String, List<Map>>{};
    // Note: To group messages by locale, we eagerly read all data, which might cause a memory issue for large projects
    for (final arbFile in arbFiles) {
      _loadData(arbFile, messagesByLocale);
    }
    messagesByLocale.forEach((locale, data) {
      _generateLocaleFile(locale, data, outputDir);
    });

    final fileName = '${generation.generatedFilePrefix}messages_all.dart';
    final mainImportFile = File(path.join(outputDir, fileName));

    final content = generation.generateMainImportFile(
      className: className,
      baseClassName: baseClassName,
      baseClassPath: path.absolute(baseClassPath),
      currentFilePath: mainImportFile.path
          .replaceAll(path.basename(mainImportFile.path), ''),
    );
    final formattedContent = formatDartContent(content, fileName);

    mainImportFile.writeAsStringSync(formattedContent);
  }

  void _loadData(String filename, Map<String, List<Map>> messagesByLocale) {
    final file = File(filename);
    final src = file.readAsStringSync();
    final data = jsonDecoder.decode(src);
    var locale = data['@@locale'] ?? data['_locale'];
    if (locale == null) {
      // Get the locale from the end of the file name. This assumes that the file
      // name doesn't contain any underscores except to begin the language tag
      // and to separate language from country. Otherwise we can't tell if
      // my_file_fr.arb is locale "fr" or "file_fr".
      final name = path.basenameWithoutExtension(file.path);
      locale = name.split('_').skip(1).join('_');
      info(
          "No @@locale or _locale field found in $name, assuming '$locale' based on the file name.",);
    }
    messagesByLocale.putIfAbsent(locale, () => []).add(data);
    generation.allLocales.add(locale);
  }

  void _generateLocaleFile(
      String locale, List<Map> localeData, String targetDir,) {
    final translations = <TranslatedMessage>[];
    for (final jsonTranslations in localeData) {
      jsonTranslations.forEach((id, messageData) {
        final TranslatedMessage? message = _recreateIntlObjects(id, messageData);
        if (message != null) {
          translations.add(message);
        }
      });
    }
    generation.generateIndividualMessageFile(locale, translations, targetDir);
  }

  /// Regenerate the original IntlMessage objects from the given [data]. For
  /// things that are messages, we expect [id] not to start with "@" and
  /// [data] to be a String. For metadata we expect [id] to start with "@"
  /// and [data] to be a Map or null. For metadata we return null.
  BasicTranslatedMessage? _recreateIntlObjects(String id, data) {
    if (id.startsWith('@')) return null;
    if (data == null) return null;
    var parsed = pluralAndGenderParser.parse(data).value;
    if (parsed is LiteralString && parsed.string.isEmpty) {
      parsed = plainParser.parse(data).value;
    }
    return BasicTranslatedMessage(id, parsed, messages);
  }
}

/// A TranslatedMessage that just uses the name as the id and knows how to look up its original messages in our [messages].
class BasicTranslatedMessage extends TranslatedMessage {

  BasicTranslatedMessage(String name, translated, this.messages)
      : super(name, translated);
  Map<String, List<MainMessage>> messages;

  @override
  List<MainMessage>? get originalMessages => (super.originalMessages == null)
      ? _findOriginals()
      : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the key in [messages].
  List<MainMessage>? _findOriginals() => originalMessages = messages[id];
}
