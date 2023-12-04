import 'package:mono_localization/src/generator/label.dart';

/// This class preserves labels for base library.
class LabelsPreserver {
  /// Singleton factory constructor.
  factory LabelsPreserver() {
    return _labelsPreserver;
  }

  LabelsPreserver._internal();

  static final LabelsPreserver _labelsPreserver = LabelsPreserver._internal();

  /// Contains labels for library.
  final List<Label> labels = [];
}
