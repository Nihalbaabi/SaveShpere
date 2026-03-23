import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const electricGreen = Color(0xFF22C55E);
  static const deepBlue = Color(0xFF0F172A);
  static const neonGreen = Color(0xFF4ADE80);
  static const darkBackground = Color(0xFF020617);
  static const lightBackground = Color(0xFFF8FAFC);
  
  static const primaryGradient = LinearGradient(
    colors: [electricGreen, neonGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    const primary = electricGreen;
    const background = lightBackground;
    const foreground = Color(0xFF0F172A);
    const card = Colors.white;
    const border = Color(0xFFE2E8F0);
    const secondary = Color(0xFFF1F5F9);
    const mutedFore = Color(0xFF64748B);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: card,
        background: background,
        onBackground: foreground,
        onSurface: foreground,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: card,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColors(
          mutedForeground: mutedFore,
          border: border,
          card: card,
          secondary: secondary,
          primaryGradient: primaryGradient,
          glowColor: electricGreen.withOpacity(0.5),
          success: electricGreen,
          warning: Colors.orange,
          error: Colors.red,
          foreground: foreground,
          bedroom: const Color(0xFF3B82F6),
          living: const Color(0xFFF59E0B),
          kitchen: const Color(0xFF10B981),
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    const primary = electricGreen;
    const background = darkBackground;
    const foreground = Colors.white;
    const card = Color(0xFF0B1120);
    const border = Color(0xFF1E293B);
    const secondary = Color(0xFF0F172A);
    const mutedFore = Color(0xFF94A3B8);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: border,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: card,
        background: background,
        onBackground: foreground,
        onSurface: foreground,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: card,
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppColors(
          mutedForeground: mutedFore,
          border: border,
          card: card,
          secondary: secondary,
          primaryGradient: primaryGradient,
          glowColor: electricGreen.withOpacity(0.5),
          success: electricGreen,
          warning: Colors.orange,
          error: Colors.red,
          foreground: foreground,
          bedroom: const Color(0xFF60A5FA),
          living: const Color(0xFFFBBF24),
          kitchen: const Color(0xFF34D399),
        ),
      ],
    );
  }
}

class AppColors extends ThemeExtension<AppColors> {
  final Color mutedForeground;
  final Color border;
  final Color card;
  final Color secondary;
  final Gradient primaryGradient;
  final Color glowColor;
  final Color success;
  final Color warning;
  final Color error;
  final Color foreground;
  final Color bedroom;
  final Color living;
  final Color kitchen;

  const AppColors({
    required this.mutedForeground,
    required this.border,
    required this.card,
    required this.secondary,
    required this.primaryGradient,
    required this.glowColor,
    required this.success,
    required this.warning,
    required this.error,
    required this.foreground,
    required this.bedroom,
    required this.living,
    required this.kitchen,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? mutedForeground,
    Color? border,
    Color? card,
    Color? secondary,
    Gradient? primaryGradient,
    Color? glowColor,
    Color? success,
    Color? warning,
    Color? error,
    Color? foreground,
  }) {
    return AppColors(
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      card: card ?? this.card,
      secondary: secondary ?? this.secondary,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      glowColor: glowColor ?? this.glowColor,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      foreground: foreground ?? this.foreground,
      bedroom: bedroom ?? this.bedroom,
      living: living ?? this.living,
      kitchen: kitchen ?? this.kitchen,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      primaryGradient: Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      bedroom: Color.lerp(bedroom, other.bedroom, t)!,
      living: Color.lerp(living, other.living, t)!,
      kitchen: Color.lerp(kitchen, other.kitchen, t)!,
    );
  }
}

extension AppThemeExtension on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
