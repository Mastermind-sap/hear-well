import 'package:flutter/material.dart';
import 'package:echo_aid/core/localization/translation_helper.dart';

/// A widget that handles translation in places where you don't have direct access to a BuildContext
class TranslatedText extends StatelessWidget {
  final String translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TranslatedText(
    this.translationKey, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      context.tr(translationKey),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Dialog builders with translation support
class TranslationDialogs {
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String titleKey,
    required String contentKey,
    required String confirmKey,
    required String cancelKey,
    bool isDanger = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: TranslatedText(
            titleKey,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TranslatedText(contentKey),
          actions: <Widget>[
            TextButton(
              child: TranslatedText(cancelKey),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDanger
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: TranslatedText(confirmKey),
            ),
          ],
        );
      },
    );
  }
}
