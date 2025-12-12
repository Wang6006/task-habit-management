import 'package:flutter/material.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, double multiplier) {
    const double kDisplayLargeSize = 57.0;
    const double kDisplayMediumSize = 45.0;
    const double kDisplaySmallSize = 36.0;
    const double kHeadlineLargeSize = 32.0;
    const double kHeadlineMediumSize = 28.0;
    const double kHeadlineSmallSize = 24.0;
    const double kTitleLargeSize = 22.0;
    const double kTitleMediumSize = 16.0;
    const double kTitleSmallSize = 14.0;
    const double kBodyLargeSize = 16.0;
    const double kBodyMediumSize = 14.0;
    const double kBodySmallSize = 12.0;
    const double kLabelLargeSize = 14.0;
    const double kLabelMediumSize = 12.0;
    const double kLabelSmallSize = 11.0;

    return base.copyWith(
      displayLarge: (base.displayLarge ?? const TextStyle()).copyWith(
        fontSize:
            (base.displayLarge?.fontSize ?? kDisplayLargeSize) * multiplier,
      ),
      displayMedium: (base.displayMedium ?? const TextStyle()).copyWith(
        fontSize:
            (base.displayMedium?.fontSize ?? kDisplayMediumSize) * multiplier,
      ),
      displaySmall: (base.displaySmall ?? const TextStyle()).copyWith(
        fontSize:
            (base.displaySmall?.fontSize ?? kDisplaySmallSize) * multiplier,
      ),
      headlineLarge: (base.headlineLarge ?? const TextStyle()).copyWith(
        fontSize:
            (base.headlineLarge?.fontSize ?? kHeadlineLargeSize) * multiplier,
      ),
      headlineMedium: (base.headlineMedium ?? const TextStyle()).copyWith(
        fontSize:
            (base.headlineMedium?.fontSize ?? kHeadlineMediumSize) * multiplier,
      ),
      headlineSmall: (base.headlineSmall ?? const TextStyle()).copyWith(
        fontSize:
            (base.headlineSmall?.fontSize ?? kHeadlineSmallSize) * multiplier,
      ),
      titleLarge: (base.titleLarge ?? const TextStyle()).copyWith(
        fontSize: (base.titleLarge?.fontSize ?? kTitleLargeSize) * multiplier,
      ),
      titleMedium: (base.titleMedium ?? const TextStyle()).copyWith(
        fontSize: (base.titleMedium?.fontSize ?? kTitleMediumSize) * multiplier,
      ),
      titleSmall: (base.titleSmall ?? const TextStyle()).copyWith(
        fontSize: (base.titleSmall?.fontSize ?? kTitleSmallSize) * multiplier,
      ),
      bodyLarge: (base.bodyLarge ?? const TextStyle()).copyWith(
        fontSize: (base.bodyLarge?.fontSize ?? kBodyLargeSize) * multiplier,
      ),
      bodyMedium: (base.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: (base.bodyMedium?.fontSize ?? kBodyMediumSize) * multiplier,
      ),
      bodySmall: (base.bodySmall ?? const TextStyle()).copyWith(
        fontSize: (base.bodySmall?.fontSize ?? kBodySmallSize) * multiplier,
      ),
      labelLarge: (base.labelLarge ?? const TextStyle()).copyWith(
        fontSize: (base.labelLarge?.fontSize ?? kLabelLargeSize) * multiplier,
      ),
      labelMedium: (base.labelMedium ?? const TextStyle()).copyWith(
        fontSize: (base.labelMedium?.fontSize ?? kLabelMediumSize) * multiplier,
      ),
      labelSmall: (base.labelSmall ?? const TextStyle()).copyWith(
        fontSize: (base.labelSmall?.fontSize ?? kLabelSmallSize) * multiplier,
      ),
    );
  }

  static ThemeData getLightTheme(double fontSizeMultiplier, Color seedColor) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );

    return baseTheme.copyWith(
      textTheme: _buildTextTheme(baseTheme.textTheme, fontSizeMultiplier),
    );
  }

  static ThemeData getDarkTheme(double fontSizeMultiplier, Color seedColor) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );

    return baseTheme.copyWith(
      textTheme: _buildTextTheme(baseTheme.textTheme, fontSizeMultiplier),
    );
  }
}
