import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Primary Palette ────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C63FF); // Indigo-Violet
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color accentColor = Color(0xFF00D4AA); // Mint accent
  static const Color accentWarm = Color(0xFFFF6B6B); // Coral accent

  // ─── Light Mode ─────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFAFBFF);
  static const Color cardLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF0F2FF);

  // ─── Dark Mode ──────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0F1E);
  static const Color cardDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16162A);

  // ─── Animation Durations ────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 400);

  // ─── Theme-aware color helpers ──────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? cardDark : cardLight;

  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? surfaceDark : surfaceLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF0F0F6) : const Color(0xFF1A1A2E);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF9898B0) : const Color(0xFF6B7280);

  static Color textHint(BuildContext context) =>
      isDark(context) ? const Color(0xFF6B6B80) : const Color(0xFFA0A0B0);

  static Color borderColor(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.08)
      : const Color(0xFFE8E8F0);

  static Color dividerColor(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.06)
      : const Color(0xFFEEEEF5);

  static Color iconColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF8888A0) : const Color(0xFF9090A0);

  static Color inputFill(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.05)
      : const Color(0xFFF5F5FF);

  static Color inputBorder(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.1)
      : const Color(0xFFE0E0EF);

  static Color glassColor(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.white.withValues(alpha: 0.65);

  static Color shadowColor(BuildContext context) => isDark(context)
      ? Colors.black.withValues(alpha: 0.3)
      : primaryColor.withValues(alpha: 0.06);

  // ─── Gradient helpers ───────────────────────────────────────
  static LinearGradient primaryGradient({bool reversed = false}) =>
      LinearGradient(
        colors: reversed
            ? [primaryLight, primaryColor]
            : [primaryColor, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient cardGradient(BuildContext context) => LinearGradient(
        colors: isDark(context)
            ? [cardDark, surfaceDark]
            : [Colors.white, const Color(0xFFF8F9FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient backgroundGradient(BuildContext context) =>
      LinearGradient(
        colors: isDark(context)
            ? [backgroundDark, const Color(0xFF12122A)]
            : [backgroundLight, const Color(0xFFF0F2FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  // ─── Page transition builder ────────────────────────────────
  static Route<T> slideRoute<T>(Widget page, {Offset? beginOffset}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: animPageTransition,
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset ?? const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ─── Stagger animation helper ──────────────────────────────
  static Animation<double> staggerAnimation(
    AnimationController controller,
    int index, {
    int totalItems = 8,
    double itemDuration = 0.4,
  }) {
    final start = (index / totalItems).clamp(0.0, 1.0 - itemDuration);
    final end = (start + itemDuration).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  // ─── ThemeData ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: backgroundLight,
        primary: primaryColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A2E),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: backgroundDark,
        primary: primaryLight,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F0F6),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF0F0F6)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Global theme notifier for manual toggle
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
    }
  }

  String get themeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
    }
  }
}
