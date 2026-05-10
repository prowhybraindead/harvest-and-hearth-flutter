import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const lightGreenBorder = Color(0xFF2E7D32);
  static const lightOrangeBorder = Color(0xFFE47C21);
  static const darkGreenBorder = Color(0xFF66BB6A);
  static const darkOrangeBorder = Color(0xFFFFB347);

  // Hearthie brand accents
  static const hearthieGold = Color(0xFFFFC94D);
  static const hearthieSky = Color(0xFF4AB3FF);
  static const hearthieNight = Color(0xFF0F1C3F);
}

class AppRadii {
  AppRadii._();

  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 28.0;
}

class AppSpacing {
  AppSpacing._();

  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

ThemeData buildAppTheme({required bool isDark}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: isDark ? AppColors.darkGreenBorder : AppColors.lightGreenBorder,
    brightness: isDark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: isDark ? AppColors.darkGreenBorder : AppColors.lightGreenBorder,
    onPrimary: isDark ? const Color(0xFF09120A) : Colors.white,
    secondary:
        isDark ? AppColors.darkOrangeBorder : AppColors.lightOrangeBorder,
    onSecondary: isDark ? const Color(0xFF241507) : Colors.white,
    surface: isDark ? const Color(0xFF070707) : Colors.white,
    onSurface: isDark ? const Color(0xFFF4F4F4) : const Color(0xFF121312),
    surfaceContainerHighest:
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FCFA),
    onSurfaceVariant:
        isDark ? const Color(0xFFC9CCC9) : const Color(0xFF4C5850),
    outline: isDark
        ? AppColors.darkOrangeBorder.withAlpha(180)
        : AppColors.lightGreenBorder.withAlpha(170),
    outlineVariant: isDark
        ? AppColors.darkGreenBorder.withAlpha(155)
        : AppColors.lightOrangeBorder.withAlpha(125),
    inverseSurface: isDark ? const Color(0xFFEFEFEF) : const Color(0xFF101111),
    onInverseSurface: isDark ? const Color(0xFF111111) : Colors.white,
    inversePrimary:
        isDark ? AppColors.lightGreenBorder : AppColors.darkGreenBorder,
  );

  OutlineInputBorder border(Color color, {double width = 1.6}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: isDark
              ? AppColors.darkOrangeBorder.withAlpha(110)
              : AppColors.lightGreenBorder.withAlpha(95),
          width: 1.25,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
      indicatorColor: isDark
          ? AppColors.darkGreenBorder.withAlpha(55)
          : AppColors.lightOrangeBorder.withAlpha(48),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 22,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFCFEFC),
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withAlpha(190)),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      border: border(colorScheme.outline.withAlpha(155), width: 1.35),
      enabledBorder:
          border(colorScheme.outlineVariant.withAlpha(170), width: 1.35),
      focusedBorder: border(colorScheme.primary, width: 1.9),
      errorBorder: border(colorScheme.error, width: 1.5),
      focusedErrorBorder: border(colorScheme.error, width: 1.9),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      side: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary.withAlpha(30),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(color: colorScheme.primary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withAlpha(100),
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: isDark
              ? AppColors.darkOrangeBorder.withAlpha(150)
              : AppColors.lightOrangeBorder.withAlpha(110),
          width: 1.2,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      showDragHandle: true,
      dragHandleColor: colorScheme.outlineVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1.4),
        foregroundColor: colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor:
          isDark ? const Color(0xFF1B1B1B) : const Color(0xFF1E3423),
      contentTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
