import 'package:flutter/material.dart';

/// Consistent app gradients to be used throughout the application
class AppGradients {
  /// Primary gradient for main backgrounds (top to bottom)
  static LinearGradient get primaryBackground => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
  );

  /// Light gradient for main backgrounds (top to bottom)
  static LinearGradient get lightBackground => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FBFF), Color(0xFFF0F4F8)],
  );

  /// Get the appropriate background gradient based on brightness
  static LinearGradient backgroundGradient(Brightness brightness) {
    return brightness == Brightness.dark ? primaryBackground : lightBackground;
  }

  /// Primary gradient for cards and buttons
  static LinearGradient primaryCardGradient(
    BuildContext context, {
    Color? baseColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = baseColor ?? colorScheme.primary;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? [color.withOpacity(0.8), color]
              : [color, Color.alphaBlend(Colors.white.withOpacity(0.3), color)],
    );
  }

  /// Surface gradient for cards
  static LinearGradient surfaceGradient(
    BuildContext context, {
    Color? baseColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = baseColor ?? colorScheme.primary;

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:
          isDark
              ? [
                colorScheme.surface,
                Color.alphaBlend(color.withOpacity(0.05), colorScheme.surface),
              ]
              : [
                Colors.white,
                Color.alphaBlend(color.withOpacity(0.07), Colors.white),
              ],
    );
  }

  /// Utility method to create an AppBar gradient
  static BoxDecoration appBarDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors:
            isDark
                ? [colorScheme.primary.withOpacity(0.8), colorScheme.primary]
                : [
                  colorScheme.primary,
                  colorScheme.primary.withBlue(colorScheme.primary.blue + 30),
                ],
      ),
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
