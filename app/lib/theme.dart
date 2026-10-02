import 'package:flutter/material.dart';

/// Wearmony's palette: deep plum, rose and champagne on warm ivory.
class Brand {
  const Brand._();

  static const plum = Color(0xFF6E2A4F);
  static const plumDeep = Color(0xFF3D1530);
  static const berry = Color(0xFFB24C7A);
  static const rose = Color(0xFFE8A0B4);
  static const champagne = Color(0xFFD9B77E);
  static const ivory = Color(0xFFFBF7F4);
  static const night = Color(0xFF150F14);
  static const success = Color(0xFF3F8F6E);
  static const warning = Color(0xFFD9822B);

  /// The signature gradient used for calls to action and highlights.
  static const gradient = LinearGradient(
    colors: [plum, berry, Color(0xFFE38FA8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const displayFont = 'PlayfairDisplay';

  /// Numbers in Manrope with tabular figures, so counting animations do not jitter.
  static TextStyle? numbers(TextStyle? style) => style?.copyWith(
    fontFamily: bodyFont,
    fontWeight: FontWeight.w800,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static const bodyFont = 'Manrope';
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: Brand.plum,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: dark ? const Color(0xFFF0B6D0) : Brand.plum,
    onPrimary: dark ? Brand.plumDeep : Colors.white,
    secondary: dark ? const Color(0xFFE8CFA2) : const Color(0xFF8A6A35),
    tertiary: dark ? Brand.rose : Brand.berry,
    surface: dark ? Brand.night : Brand.ivory,
    surfaceContainerLowest: dark ? const Color(0xFF100B0F) : Colors.white,
    surfaceContainerLow: dark
        ? const Color(0xFF1E161C)
        : const Color(0xFFF7F0EC),
    surfaceContainer: dark ? const Color(0xFF241A21) : const Color(0xFFF3EAE5),
    surfaceContainerHigh: dark
        ? const Color(0xFF2C2028)
        : const Color(0xFFEEE3DE),
    surfaceContainerHighest: dark
        ? const Color(0xFF35272F)
        : const Color(0xFFE8DCD6),
  );

  final textBase =
      (dark ? Typography.material2021().white : Typography.material2021().black)
          .apply(
            fontFamily: Brand.bodyFont,
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          );
  TextStyle? display(
    TextStyle? style, {
    FontWeight weight = FontWeight.w600,
    double? spacing,
  }) => style?.copyWith(
    fontFamily: Brand.displayFont,
    fontWeight: weight,
    letterSpacing: spacing,
  );
  final text = textBase.copyWith(
    displayLarge: display(
      textBase.displayLarge,
      weight: FontWeight.w700,
      spacing: -1,
    ),
    displayMedium: display(
      textBase.displayMedium,
      weight: FontWeight.w700,
      spacing: -0.5,
    ),
    displaySmall: display(textBase.displaySmall, weight: FontWeight.w700),
    headlineLarge: display(textBase.headlineLarge),
    headlineMedium: display(textBase.headlineMedium),
    headlineSmall: display(textBase.headlineSmall),
    titleLarge: display(textBase.titleLarge),
    titleMedium: textBase.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall: textBase.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: textBase.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  const pill = StadiumBorder();
  const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: Brand.bodyFont,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 22),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: pill,
        padding: padding,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        padding: padding,
        textStyle: text.labelLarge,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: pill, textStyle: text.labelLarge),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      showCheckmark: false,
      selectedColor: scheme.primaryContainer,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      dividerColor: Colors.transparent,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        borderSide: BorderSide(color: scheme.primary, width: 3),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
