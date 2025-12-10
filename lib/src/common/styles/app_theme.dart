import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const seedColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFF14B8A6); // Teal

  static ThemeData get lightTheme {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        secondary: secondaryColor,
        brightness: Brightness.light,
        surface: const Color(0xFFF8FAFC), // Slate 50
        surfaceContainer: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
    );

    return _buildTheme(base);
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        secondary: secondaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B), // Slate 800
        surfaceContainer: const Color(0xFF0F172A), // Slate 900
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
    );

    return _buildTheme(base);
  }

  static ThemeData _buildTheme(ThemeData base) {
    return base.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme),
      
      // Component Themes
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: base.brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
        margin: EdgeInsets.zero,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.brightness == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24, 
          fontWeight: FontWeight.bold, 
          color: base.colorScheme.onSurface
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: base.brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
        indicatorColor: seedColor.withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: seedColor);
          }
          return IconThemeData(color: base.colorScheme.onSurfaceVariant);
        }),
      ),
    );
  }
}
