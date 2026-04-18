import 'package:flutter/material.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(true);

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.card,
    required this.accent,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.shadow,
    required this.overlay,
  });

  final Color background;
  final Color card;
  final Color accent;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color shadow;
  final Color overlay;

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? card,
    Color? accent,
    Color? primaryText,
    Color? secondaryText,
    Color? border,
    Color? shadow,
    Color? overlay,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      card: card ?? this.card,
      accent: accent ?? this.accent,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      background: Color.lerp(background, other.background, t) ?? background,
      card: Color.lerp(card, other.card, t) ?? card,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText:
          Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      border: Color.lerp(border, other.border, t) ?? border,
      shadow: Color.lerp(shadow, other.shadow, t) ?? shadow,
      overlay: Color.lerp(overlay, other.overlay, t) ?? overlay,
    );
  }
}

ThemeData buildAppTheme({required bool isDark}) {
  const accent = Color(0xFF0A84FF);
  final colors = isDark
      ? const AppThemeColors(
          background: Color(0xFF000000),
          card: Color(0xFF1A1A1A),
          accent: accent,
          primaryText: Colors.white,
          secondaryText: Color(0xFFB3B3B3),
          border: Color(0xFF2A2A2A),
          shadow: Color(0x4D000000),
          overlay: Color(0x1A0A84FF),
        )
      : const AppThemeColors(
          background: Color(0xFFFFFFFF),
          card: Color(0xFFF5F5F5),
          accent: accent,
          primaryText: Color(0xFF000000),
          secondaryText: Color(0xFF5F6368),
          border: Color(0xFFE2E2E2),
          shadow: Color(0x14000000),
          overlay: Color(0x140A84FF),
        );

  final scheme = ColorScheme(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primary: colors.accent,
    onPrimary: isDark ? Colors.black : Colors.white,
    secondary: colors.accent,
    onSecondary: isDark ? Colors.black : Colors.white,
    error: Colors.redAccent,
    onError: Colors.white,
    surface: colors.card,
    onSurface: colors.primaryText,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: colors.background,
    colorScheme: scheme,
    cardColor: colors.card,
    dividerColor: colors.border,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.primaryText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colors.primaryText,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: colors.primaryText),
    ),
    textTheme: ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).textTheme.apply(
          bodyColor: colors.primaryText,
          displayColor: colors.primaryText,
        ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.card,
      selectedItemColor: colors.accent,
      unselectedItemColor: colors.secondaryText,
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.card,
      labelStyle: TextStyle(color: colors.secondaryText),
      hintStyle: TextStyle(color: colors.secondaryText),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor:
            isDark ? const Color(0xFF2F2F2F) : const Color(0xFFD6D6D6),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    extensions: [colors],
  );
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  AppThemeColors get appColors =>
      theme.extension<AppThemeColors>() ?? buildAppTheme(isDark: true).extension<AppThemeColors>()!;
}
