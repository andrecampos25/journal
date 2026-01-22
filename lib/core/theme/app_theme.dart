import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppTheme {
  // Light Theme
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E293B),
      brightness: Brightness.light,
      surface: Colors.white,
      primary: const Color(0xFF1E293B),
      onPrimary: Colors.white,
      secondary: const Color(0xFF64748B),
    ),
    textTheme: GoogleFonts.interTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF1E293B)),
    ),
  );

  // Dark Theme
  static final dark = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFF8FAFC),
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B), // Slate 800
      onSurface: const Color(0xFFF1F5F9), // Slate 100
      primary: const Color(0xFFF8FAFC),
      onPrimary: const Color(0xFF0F172A),
      secondary: const Color(0xFF94A3B8),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
    ),
    // Customize other widgets for dark mode (e.g. Card, Dialog)
    // Customize other widgets for dark mode (e.g. Card, Dialog)
    // dialogTheme: DialogTheme(
    //   backgroundColor: const Color(0xFF1E293B),
    //   surfaceTintColor: Colors.transparent, 
    // ),
  );
}

// Check for Hive box "settings" and key "isDarkMode"
// Check for Hive box "settings" and key "isDarkMode"
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light; // Default to light until loaded
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox('settings');
    final isDark = box.get('isDarkMode', defaultValue: false);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final box = await Hive.openBox('settings');
    if (state == ThemeMode.light) {
      state = ThemeMode.dark;
      await box.put('isDarkMode', true);
    } else {
      state = ThemeMode.light;
      await box.put('isDarkMode', false);
    }
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
