import 'package:flutter/material.dart';
import 'package:hear_well/core/localization/app_localizations.dart';

/// Translation helper to make it easier to use translations across the app.
///
/// Usage:
/// String text = tr(context, 'key');
///
/// This is a simplified alternative to:
/// String text = AppLocalizations.of(context).translate('key');
String tr(BuildContext context, String key) {
  return AppLocalizations.of(context).translate(key);
}

/// Extension on BuildContext to allow for more concise translation syntax
extension TranslationExtension on BuildContext {
  /// Translates a key into the current locale
  ///
  /// Usage:
  /// String text = context.tr('key');
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}
