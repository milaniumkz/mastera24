import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0B1F4D);
  static const Color primaryDeep = Color(0xFF06132F);
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentSoft = Color(0xFFDCEBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF5FF);
  static const Color background = Color(0xFF06132F);
  static const Color ink = Color(0xFF10264D);
  static const Color inkSoft = Color(0xFF5E7396);
  static const Color line = Color(0xFFC8D8F0);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);

  static const List<Color> backdropGradient = [
    background,
    background,
  ];

  static const String displayFontFamily = 'Trebuchet MS';
  static const List<String> displayFontFallback = [
    'Avenir Next',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: primaryDeep,
      onSurface: ink,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: _displayStyle(base, 48),
      displayMedium: _displayStyle(base, 36),
      headlineMedium: _displayStyle(base, 30),
      headlineSmall: _displayStyle(base, 24),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        height: 1.45,
        color: ink,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.42,
        color: inkSoft,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        color: inkSoft,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.08,
        color: ink,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      iconTheme: const IconThemeData(color: primary),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceMuted,
        selectedColor: accent,
        secondarySelectedColor: accent,
        labelStyle: textTheme.bodySmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: inkSoft),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: inkSoft.withValues(alpha: 0.72),
        ),
        border: _fieldBorder(line),
        enabledBorder: _fieldBorder(line),
        focusedBorder: _fieldBorder(accent, width: 1.4),
        errorBorder: _fieldBorder(danger),
        focusedErrorBorder: _fieldBorder(danger, width: 1.4),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x140F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: line),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: accent,
        unselectedItemColor: inkSoft,
        selectedLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.bodySmall,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  static BoxDecoration pageBackdrop({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return const BoxDecoration(color: background);
  }

  static BoxDecoration premiumPanelDecoration({
    bool accented = false,
    bool darker = false,
  }) {
    final color = darker
        ? primaryDeep
        : accented
        ? surfaceMuted
        : surface;

    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: darker ? Colors.white.withValues(alpha: 0.12) : line,
      ),
      boxShadow: [
        BoxShadow(
          color: darker ? const Color(0x21000000) : const Color(0x0D0F172A),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  static TextStyle? _displayStyle(ThemeData base, double size) {
    return base.textTheme.headlineMedium?.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      height: 1.08,
      color: ink,
      fontFamily: displayFontFamily,
      fontFamilyFallback: displayFontFallback,
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
