import 'package:flutter/material.dart';

class AppTheme {
  // Color Constants
  static const Color _primaryLight = Color(0xFF2196F3); // Blue primary
  static const Color _primaryDark = Color(0xFF1565C0); // Darker blue for dark mode
  static const Color _secondaryLight = Color(0xFF4CAF50); // Green accent
  static const Color _secondaryDark = Color(0xFF2E7D32); // Darker green for dark mode
  static const Color _errorLight = Color(0xFFD32F2F);
  static const Color _errorDark = Color(0xFFEF5350);
  static const Color _backgroundLight = Color(0xFFF5F5F5);
  static const Color _backgroundDark = Color(0xFF121212);
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E1E1E);
  static const Color _textPrimaryLight = Color(0xFF212121);
  static const Color _textPrimaryDark = Color(0xFFE0E0E0);
  static const Color _textSecondaryLight = Color(0xFF757575);
  static const Color _textSecondaryDark = Color(0xFFB0B0B0);

  // Spacing Constants
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radius Constants
  static final BorderRadius radiusSm = BorderRadius.circular(4.0);
  static final BorderRadius radiusMd = BorderRadius.circular(8.0);
  static final BorderRadius radiusLg = BorderRadius.circular(16.0);

  // Elevation Constants
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // Text Theme
  static TextTheme _buildTextTheme(TextTheme base, Color primaryTextColor, Color secondaryTextColor) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontSize: 24.0,
        fontWeight: FontWeight.bold,
        color: primaryTextColor,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontSize: 16.0,
        color: primaryTextColor,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontSize: 14.0,
        color: primaryTextColor,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontSize: 12.0,
        color: secondaryTextColor,
      ),
    );
  }

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: _primaryLight,
      onPrimary: Colors.white,
      secondary: _secondaryLight,
      onSecondary: Colors.white,
      error: _errorLight,
      onError: Colors.white,
      background: _backgroundLight,
      onBackground: _textPrimaryLight,
      surface: _surfaceLight,
      onSurface: _textPrimaryLight,
    ),
    textTheme: _buildTextTheme(
      ThemeData.light().textTheme,
      _textPrimaryLight,
      _textSecondaryLight,
    ),
    appBarTheme: AppBarTheme(
      elevation: elevationSm,
      backgroundColor: _primaryLight,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: elevationSm,
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
      margin: EdgeInsets.all(spacingSm),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: elevationSm,
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.all(spacingMd),
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _primaryLight.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _primaryLight.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _errorLight, width: 1),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryLight,
      foregroundColor: Colors.white,
      elevation: elevationMd,
    ),
    dividerTheme: DividerThemeData(
      space: spacingMd,
      thickness: 1,
      color: Colors.grey.withOpacity(0.2),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceLight,
      selectedItemColor: _primaryLight,
      unselectedItemColor: _textSecondaryLight,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.withOpacity(0.1),
      padding: EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
      labelStyle: TextStyle(color: _textPrimaryLight),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
      elevation: elevationLg,
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryDark,
      onPrimary: Colors.white,
      secondary: _secondaryDark,
      onSecondary: Colors.white,
      error: _errorDark,
      onError: Colors.white,
      background: _backgroundDark,
      onBackground: _textPrimaryDark,
      surface: _surfaceDark,
      onSurface: _textPrimaryDark,
    ),
    textTheme: _buildTextTheme(
      ThemeData.dark().textTheme,
      _textPrimaryDark,
      _textSecondaryDark,
    ),
    appBarTheme: AppBarTheme(
      elevation: elevationSm,
      backgroundColor: _surfaceDark,
      foregroundColor: _textPrimaryDark,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      elevation: elevationSm,
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
      margin: EdgeInsets.all(spacingSm),
      color: Color(0xFF252525),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: elevationSm,
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
        foregroundColor: _primaryDark,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
        foregroundColor: _primaryDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF303030),
      contentPadding: EdgeInsets.all(spacingMd),
      border: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusMd,
        borderSide: BorderSide(color: _errorDark, width: 1),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryDark,
      foregroundColor: Colors.white,
      elevation: elevationMd,
    ),
    dividerTheme: DividerThemeData(
      space: spacingMd,
      thickness: 1,
      color: Colors.grey.withOpacity(0.2),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceDark,
      selectedItemColor: _primaryDark,
      unselectedItemColor: _textSecondaryDark,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Color(0xFF404040),
      padding: EdgeInsets.symmetric(horizontal: spacingSm, vertical: spacingXs),
      labelStyle: TextStyle(color: _textPrimaryDark),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: radiusMd),
      backgroundColor: _surfaceDark,
      elevation: elevationLg,
    ),
  );
}
