import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  late bool _isDarkMode;
  
  // Only keeping a single pink color for consistency
  static const Color primaryPink = Color(0xFFFF85A2);
  static const Color darkPink = Color(0xFF9E1A5A);
  
  // Animation duration for theme transitions
  static const Duration animationDuration = Duration(milliseconds: 500);
  
  // Getters
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;
  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _isDarkMode ? darkPink : primaryPink;
  
  // Add an initialize method
  Future<void> initialize() async {
    // Load preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      _isDarkMode = false;
    }
    
    // Initialize themes
    _lightTheme = _createLightTheme();
    _darkTheme = _createDarkTheme();
    
    notifyListeners();
  }
  
  // Toggle dark mode without triggering navigation
  Future<void> toggleTheme() async {
    // Store the current theme state
    final previousIsDarkMode = _isDarkMode;
    
    // Toggle the theme state
    _isDarkMode = !_isDarkMode;
    
    // Save the new theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    
    // Do not reset or modify any other navigation flags
    // This ensures we stay on the current screen when toggling theme
    
    // Notify listeners about the change
    notifyListeners();
  }
  
  ThemeData _createLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryPink,
      brightness: Brightness.light,
      primaryContainer: primaryPink.withOpacity(0.15),
      secondaryContainer: primaryPink.withOpacity(0.1),
      surfaceTint: primaryPink.withOpacity(0.05),
      surface: Colors.white,
      background: const Color(0xFFFAF8FC), // Subtle background with a hint of pink
      onBackground: const Color(0xFF202025),
      onSurface: const Color(0xFF303035),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colorScheme.background,
      
      // Card theme with 3D shadow effect instead of glossy look
      cardTheme: CardTheme(
        elevation: 3.0,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      
      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: colorScheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Switch theme with improved visuals
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.3);
          }
          return colorScheme.surfaceVariant;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline.withOpacity(0.5);
        }),
      ),
      
      // Text theme with cleaner typography
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colorScheme.onBackground,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onBackground,
          height: 1.5,
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      
      // Enhanced bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withOpacity(0.1),
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
      ),
    );
  }
  
  ThemeData _createDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: darkPink,
      brightness: Brightness.dark,
      primaryContainer: darkPink.withOpacity(0.2),
      secondaryContainer: darkPink.withOpacity(0.15),
      surfaceTint: darkPink.withOpacity(0.1),
      surface: const Color(0xFF2A2A38),
      background: const Color(0xFF1E1E2A), // Deeper, richer dark background
      onBackground: Colors.white.withOpacity(0.95),
      onSurface: Colors.white.withOpacity(0.95),
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorScheme.background,
      
      // Card theme with 3D shadow effect
      cardTheme: CardTheme(
        elevation: 4.0,
        shadowColor: darkPink.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      
      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 3,
          shadowColor: darkPink.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      
      // Switch theme with improved visuals for dark mode
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary;
          }
          return Colors.white70;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primary.withOpacity(0.4);
          }
          return colorScheme.surfaceVariant;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.outline.withOpacity(0.3);
        }),
      ),
      
      // Text theme with lighter weights for better legibility in dark mode
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colorScheme.onBackground.withOpacity(0.9),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onBackground.withOpacity(0.9),
          height: 1.5,
        ),
      ),
      
      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 5,
        shadowColor: darkPink.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      
      // Enhanced bottom navigation bar theme for dark mode
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: Colors.white,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      
      // List tile theme for dark mode
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primary.withOpacity(0.15),
        iconColor: Colors.white,
        textColor: colorScheme.onSurface,
      ),
    );
  }
}