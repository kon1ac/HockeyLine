import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Минималистичная тёмная тема: фон #121212, акцент #D32F2F, светлая панель навигации.
abstract final class AppColors {
  static const Color accent = Color(0xFFD32F2F);
  static const Color scaffold = Color(0xFF121212);
  static const Color surface = Color(0xFF1A1A1A);
  /// Нижняя навигация: светлее основного фона, без «затемнения» M3 surface tint.
  static const Color navBar = Color(0xFF2C2C2C);
  static const Color playerCard = Color(0xFFFFFFFF);
  static const Color onPlayerCard = Color(0xFF1C1C1C);
  /// Чуть выше контраста для подписей на тёмном фоне (WCAG-friendly).
  static const Color muted = Color(0xFFB0B0B0);
  static const Color outline = Color(0xFF3D3D3D);
  /// Вторичные карточки (звенья, заметки): холодный серо-синий.
  static const Color surfaceSecondary = Color(0xFF22272E);
  /// Сетки графиков, иконки баннера — нейтральный холодный.
  static const Color chartCool = Color(0xFF78909C);
  static const Color iceLine = Color(0x33FFFFFF);
  static const Color snackSuccessBg = Color(0xFF1B3D2A);
  static const Color snackErrorBg = Color(0xFF3D1B1B);
}

/// Сетка отступов: 4 / 8 / 12 / 16 / 24 / 32.
abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
}

abstract final class AppMotion {
  static const Duration pageSwitch = Duration(milliseconds: 220);
}

/// Ограниченная шкала размеров: 13 / 14 / 15 / 18 / 22. Semibold — только заголовки и имена.
abstract final class AppTextStyles {
  static TextStyle titleScreen(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.3,
      color: Color(0xFFF5F5F5),
    );
  }

  static TextStyle titleSection(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Color(0xFFF0F0F0),
    );
  }

  static TextStyle bodyEmphasis(BuildContext context) {
    return const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
  }

  static TextStyle bodySmallMuted(BuildContext context) {
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13,
      height: 1.4,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.muted
          : const Color(0xFF616161),
    );
  }

  /// Статистика: табличные цифры.
  static TextStyle statsFigures({Color? color}) {
    return TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      height: 1.35,
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      color: color,
    );
  }
}

ThemeData buildHockeyDarkTheme() {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    onSurface: const Color(0xFFE8E8E8),
    surfaceContainerHighest: AppColors.navBar,
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.scaffold,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.scaffold,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F5),
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: AppSpacing.s4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: AppColors.accent.withValues(alpha: 0.22),
      iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.accent, size: 24);
        }
        return const IconThemeData(color: Color(0xFFB8B8B8), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        final TextStyle base = const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        );
        if (states.contains(WidgetState.selected)) {
          return base.copyWith(color: AppColors.accent);
        }
        return base.copyWith(color: const Color(0xFFB8B8B8));
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.navBar,
      selectedIconTheme: const IconThemeData(color: AppColors.accent, size: 24),
      unselectedIconTheme: const IconThemeData(color: Color(0xFFB8B8B8), size: 24),
      selectedLabelTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFB8B8B8),
        fontSize: 13,
      ),
      indicatorColor: AppColors.accent.withValues(alpha: 0.2),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent.withValues(alpha: 0.2),
      disabledColor: AppColors.surface,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: Color(0xFFE0E0E0),
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: const BorderSide(color: AppColors.outline, width: 0.8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.muted,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF323232),
      contentTextStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, height: 1.45),
      bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 13, height: 1.4),
      titleMedium: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        fontSize: 18,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.25,
        letterSpacing: -0.3,
      ),
    ).apply(
      bodyColor: const Color(0xFFE8E8E8),
      displayColor: const Color(0xFFF5F5F5),
    ),
  );
}

/// Белая карточка игрока с лёгкой тенью (на тёмном фоне).
class PlayerCardSurface extends StatelessWidget {
  const PlayerCardSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.playerCard,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.onPlayerCard,
          fontSize: 15,
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.onPlayerCard, size: 22),
          child: child,
        ),
      ),
    );
  }
}
