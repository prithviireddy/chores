import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Modern Light Color Palette - Playful & Smooth
class AppColors {
  // Primary Colors - Soft & Vibrant
  static const primaryPurple = Color(0xFF8B7FF4);
  static const primaryBlue = Color(0xFF5DADE2);
  static const accentPink = Color(0xFFFF8FAB);
  static const accentOrange = Color(0xFFFFB84D);
  
  // Background Colors - Light & Airy
  static const lightBg = Color(0xFFF8F9FE);
  static const cardBg = Color(0xFFFFFFFF);
  static const surfaceBg = Color(0xFFF3F4F9);
  
  // Text Colors
  static const textPrimary = Color(0xFF2D3748);
  static const textSecondary = Color(0xFF718096);
  static const textMuted = Color(0xFFA0AEC0);
  
  // Status Colors - Soft & Friendly
  static const success = Color(0xFF48BB78);
  static const warning = Color(0xFFFBD38D);
  static const error = Color(0xFFFC8181);
  static const info = Color(0xFF63B3ED);
  
  // Gradient Definitions
  static const primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [accentPink, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF48BB78), Color(0xFF38A169)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Soft Shadow
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: primaryPurple.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  
  // Color Scheme
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryPurple,
    secondary: AppColors.accentPink,
    surface: AppColors.cardBg,
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.textPrimary,
  ),
  
  scaffoldBackgroundColor: AppColors.lightBg,
  
  // AppBar Theme
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  
  // Card Theme
  cardTheme: CardThemeData(
    elevation: 0,
    shadowColor: Colors.black.withOpacity(0.05),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: AppColors.cardBg,
  ),
  
  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.textMuted.withOpacity(0.1), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    hintStyle: const TextStyle(color: AppColors.textMuted),
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  ),
  
  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      shadowColor: AppColors.primaryPurple.withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  ),
  
  // Floating Action Button Theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 8,
    backgroundColor: AppColors.primaryPurple,
    foregroundColor: Colors.white,
    extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    extendedTextStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
  ),
  
  // Text Theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
      letterSpacing: 0.5,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: AppColors.textMuted,
    ),
  ),
  
  // Divider Theme
  dividerTheme: DividerThemeData(
    color: AppColors.textMuted.withOpacity(0.1),
    thickness: 1,
    space: 1,
  ),
  
  // Icon Theme
  iconTheme: const IconThemeData(
    color: AppColors.textSecondary,
    size: 24,
  ),
);
