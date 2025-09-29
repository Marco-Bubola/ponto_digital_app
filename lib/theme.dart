import 'package:flutter/material.dart';

// Paleta de cores moderna com tonalidade verde
class ModernGreenPalette {
  // Tons principais de verde
  static const int primaryGreen = 0xFF10B981; // Emerald 500
  static const int primaryGreenLight = 0xFF34D399; // Emerald 400  
  static const int primaryGreenDark = 0xFF059669; // Emerald 600
  
  // Tons secundários (verde azulado)
  static const int secondaryTeal = 0xFF14B8A6; // Teal 500
  static const int secondaryTealLight = 0xFF5EEAD4; // Teal 300
  static const int secondaryTealDark = 0xFF0F766E; // Teal 700
  
  // Tons de acento (verde lima)
  static const int accentLime = 0xFF84CC16; // Lime 500
  static const int accentLimeLight = 0xFFA3E635; // Lime 400
  
  // Tons neutros modernos
  static const int neutralGray50 = 0xFFF9FAFB;
  static const int neutralGray100 = 0xFFF3F4F6;
  static const int neutralGray200 = 0xFFE5E7EB;
  static const int neutralGray300 = 0xFFD1D5DB;
  static const int neutralGray600 = 0xFF4B5563;
  static const int neutralGray800 = 0xFF1F2937;
  static const int neutralGray900 = 0xFF111827;
  
  // Status colors
  static const int successGreen = 0xFF22C55E; // Green 500
  static const int warningAmber = 0xFFF59E0B; // Amber 500
  static const int errorRed = 0xFFEF4444; // Red 500
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: const Color(ModernGreenPalette.primaryGreen),
      primaryContainer: const Color(ModernGreenPalette.primaryGreenLight),
      secondary: const Color(ModernGreenPalette.secondaryTeal),
      secondaryContainer: const Color(ModernGreenPalette.secondaryTealLight),
      tertiary: const Color(ModernGreenPalette.accentLime),
      surface: const Color(ModernGreenPalette.neutralGray50),
      surfaceContainerHighest: const Color(ModernGreenPalette.neutralGray100),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: const Color(ModernGreenPalette.neutralGray900),
      outline: const Color(ModernGreenPalette.neutralGray300),
      error: const Color(ModernGreenPalette.errorRed),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // Cores customizadas
      primaryColor: const Color(ModernGreenPalette.primaryGreen),
      scaffoldBackgroundColor: const Color(ModernGreenPalette.neutralGray50),
      
      // Tipografia - Fonte Inter
      fontFamily: 'Inter',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colorScheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      
      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: colorScheme.surfaceContainerHighest,
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: const Color(ModernGreenPalette.primaryGreenLight),
      primaryContainer: const Color(ModernGreenPalette.primaryGreenDark),
      secondary: const Color(ModernGreenPalette.secondaryTealLight),
      secondaryContainer: const Color(ModernGreenPalette.secondaryTealDark),
      tertiary: const Color(ModernGreenPalette.accentLimeLight),
      surface: const Color(ModernGreenPalette.neutralGray900),
      surfaceContainerHighest: const Color(ModernGreenPalette.neutralGray800),
      onPrimary: const Color(ModernGreenPalette.neutralGray900),
      onSecondary: const Color(ModernGreenPalette.neutralGray900),
      onTertiary: const Color(ModernGreenPalette.neutralGray900),
      onSurface: const Color(ModernGreenPalette.neutralGray100),
      outline: const Color(ModernGreenPalette.neutralGray600),
      error: const Color(ModernGreenPalette.errorRed),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: const Color(0xFF0A0E13), // Mais escuro que surface para contraste
      fontFamily: 'Inter',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.25,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: colorScheme.onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colorScheme.surfaceContainerHighest,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Cores de status para estados do app (atualizadas para verde moderno)
class StatusColors {
  static const Color success = Color(ModernGreenPalette.successGreen);
  static const Color warning = Color(ModernGreenPalette.warningAmber);
  static const Color error = Color(ModernGreenPalette.errorRed);
  static const Color info = Color(ModernGreenPalette.primaryGreen);
}

// Espaçamentos padronizados
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Raios de borda padronizados
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// Helper extension to expose theme-aware status colors
extension AppThemeHelpers on ThemeData {
  /// Warning color adapted for current brightness
  Color get warningColor {
    const base = Color(ModernGreenPalette.warningAmber);
    if (brightness == Brightness.dark) {
      return Color.alphaBlend(base.withValues(alpha: 0.85), colorScheme.surface);
    }
    return base;
  }

  /// Success color (green)
  Color get successColor {
    const base = Color(ModernGreenPalette.successGreen);
    if (brightness == Brightness.dark) return Color.alphaBlend(base.withValues(alpha: 0.95), colorScheme.surface);
    return base;
  }

  /// Error color (red)
  Color get errorColor {
    const base = Color(ModernGreenPalette.errorRed);
    if (brightness == Brightness.dark) return Color.alphaBlend(base.withValues(alpha: 0.95), colorScheme.surface);
    return base;
  }
}
