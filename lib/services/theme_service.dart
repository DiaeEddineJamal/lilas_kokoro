import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Color Palette Definitions
class ColorPalette {
  final String name;
  final String icon;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color deep;
  final List<Color> lightGradient;
  final List<Color> darkGradient;

  const ColorPalette({
    required this.name,
    required this.icon,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.deep,
    required this.lightGradient,
    required this.darkGradient,
  });
}

class ThemeService extends ChangeNotifier {
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  late bool _isDarkMode;
  late ColorPalette _selectedPalette;
  
  // Available color palettes
  static const List<ColorPalette> availablePalettes = [
    ColorPalette(
      name: 'Rose Garden',
      icon: '🌹',
      primary: Color(0xFFFF69B4),
      secondary: Color(0xFFFF1493),
      accent: Color(0xFF87CEEB),
      deep: Color(0xFFDC143C),
      lightGradient: [Color(0xFFFF69B4), Color(0xFF87CEEB)], // Hot pink to sky blue
      darkGradient: [Color(0xFFFF1493), Color(0xFF4682B4)], // Deep pink to steel blue
    ),
    ColorPalette(
      name: 'Ocean Breeze',
      icon: '🌊',
      primary: Color(0xFF4A9EFF),
      secondary: Color(0xFF2E86FF),
      accent: Color(0xFF00CED1),
      deep: Color(0xFF1B5AA0),
      lightGradient: [Color(0xFF4A9EFF), Color(0xFF00CED1)], // Blue to dark turquoise
      darkGradient: [Color(0xFF2E86FF), Color(0xFF008B8B)], // Darker blue to dark cyan
    ),
    ColorPalette(
      name: 'Forest Trail',
      icon: '🌲',
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFF45A049),
      accent: Color(0xFF90EE90),
      deep: Color(0xFF2E7D32),
      lightGradient: [Color(0xFF4CAF50), Color(0xFF90EE90)], // Green to light green
      darkGradient: [Color(0xFF45A049), Color(0xFF228B22)], // Forest green to dark green
    ),
    ColorPalette(
      name: 'Aurora Dream',
      icon: '🌌',
      primary: Color(0xFF7B68EE), // Medium slate blue - softer and more comfortable
      secondary: Color(0xFF9370DB), // Medium purple
      accent: Color(0xFFDDA0DD), // Plum - gentle and pleasing
      deep: Color(0xFF6A5ACD), // Slate blue
      lightGradient: [Color(0xFF7B68EE), Color(0xFFDDA0DD)], // Medium slate blue to plum
      darkGradient: [Color(0xFF6A5ACD), Color(0xFF9370DB)], // Slate blue to medium purple
    ),
    ColorPalette(
      name: 'Royal Purple',
      icon: '👑',
      primary: Color(0xFF9C27B0),
      secondary: Color(0xFF8E24AA),
      accent: Color(0xFFDDA0DD),
      deep: Color(0xFF6A1B9A),
      lightGradient: [Color(0xFF9C27B0), Color(0xFFDDA0DD)], // Purple to plum
      darkGradient: [Color(0xFF8E24AA), Color(0xFF8B008B)], // Dark magenta to dark magenta
    ),
    ColorPalette(
      name: 'Midnight Sky',
      icon: '🌌',
      primary: Color(0xFF3F51B5),
      secondary: Color(0xFF3949AB),
      accent: Color(0xFF9370DB),
      deep: Color(0xFF283593),
      lightGradient: [Color(0xFF3F51B5), Color(0xFF9370DB)], // Indigo to medium purple
      darkGradient: [Color(0xFF3949AB), Color(0xFF4B0082)], // Dark slate blue to indigo
    ),
    ColorPalette(
      name: 'Golden Hour',
      icon: '✨',
      primary: Color(0xFFFFC107),
      secondary: Color(0xFFFFB300),
      accent: Color(0xFFFF8C00), // Changed to dark orange for better text contrast
      deep: Color(0xFFFF8F00),
      lightGradient: [Color(0xFFFFC107), Color(0xFFFF8C00)], // Amber to dark orange
      darkGradient: [Color(0xFFFFB300), Color(0xFFDAA520)], // Dark amber to goldenrod
    ),
    ColorPalette(
      name: 'Cherry Blossom',
      icon: '🌸',
      primary: Color(0xFFE91E63),
      secondary: Color(0xFFD81B60),
      accent: Color(0xFFFFB6C1),
      deep: Color(0xFFC2185B),
      lightGradient: [Color(0xFFE91E63), Color(0xFFFFB6C1)], // Pink to light pink
      darkGradient: [Color(0xFFD81B60), Color(0xFFDB7093)], // Deep pink to pale violet red
    ),
  ];

  // App color palette
  static const Color warningColor = Color(0xFFFF9500);
  static const Color errorColor = Color(0xFFFF3B30);
  
  // Static method to get current theme colors synchronously for splash screen
  static Future<Map<String, Color>> getCurrentThemeColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPaletteIndex = prefs.getInt('color_palette') ?? 0;
      final selectedPalette = availablePalettes[savedPaletteIndex.clamp(0, availablePalettes.length - 1)];
      
      return {
        'primary': selectedPalette.primary,
        'secondary': selectedPalette.secondary,
        'accent': selectedPalette.accent,
      };
    } catch (e) {
      debugPrint('Error loading theme colors: $e');
      // Return Rose Garden as fallback
      return {
        'primary': availablePalettes[0].primary,
        'secondary': availablePalettes[0].secondary,
        'accent': availablePalettes[0].accent,
      };
    }
  }
  
  // Getters
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;
  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;
  bool get isDarkMode => _isDarkMode;
  ColorPalette get selectedPalette => _selectedPalette;
  Color get primary => _isDarkMode ? _selectedPalette.secondary : _selectedPalette.primary;
  List<Color> get lightGradient => _selectedPalette.lightGradient;
  List<Color> get darkGradient => _selectedPalette.darkGradient;
  
  // Initialize method
  Future<void> initialize() async {
    // Load preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      
      // Load selected palette
      final savedPaletteIndex = prefs.getInt('color_palette') ?? 0;
      _selectedPalette = availablePalettes[savedPaletteIndex.clamp(0, availablePalettes.length - 1)];
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
      _isDarkMode = false;
      _selectedPalette = availablePalettes[0]; // Default to Rose Garden
    }
    
    // Initialize themes
    _lightTheme = _createLightTheme();
    _darkTheme = _createDarkTheme();
    
    notifyListeners();
  }
  
  // Pre-warm colors for splash screen to prevent gradient flashing
  Future<void> preWarmColors() async {
    // This method ensures the selected palette is ready before splash screen renders
    // The colors are already loaded in initialize(), this is just for confirmation
    debugPrint('🎨 Pre-warmed colors: Primary=${_selectedPalette.primary}, Accent=${_selectedPalette.accent}');
  }
  
  // Toggle dark mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    // Save the new theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    
    // Notify listeners about the change
    notifyListeners();
  }
  
  // Change color palette
  Future<void> changeColorPalette(int paletteIndex) async {
    if (paletteIndex >= 0 && paletteIndex < availablePalettes.length) {
      _selectedPalette = availablePalettes[paletteIndex];
      
      // Recreate themes with new palette
      _lightTheme = _createLightTheme();
      _darkTheme = _createDarkTheme();
      
      // Save the new palette preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('color_palette', paletteIndex);
      
      // Notify listeners about the change
      notifyListeners();
    }
  }
  
  ThemeData _createLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: _selectedPalette.secondary,
      tertiary: _selectedPalette.accent,
      error: errorColor,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      
      // Card theme
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
      
      // Button themes
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
      
      // Switch theme
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
      
      // Text theme
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
      
      // Bottom navigation bar theme
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
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
  
  ThemeData _createDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: _selectedPalette.secondary,
      secondary: primary,
      tertiary: _selectedPalette.accent,
      error: errorColor,
    );
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 3.0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      ),
      
      // Button themes
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
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _selectedPalette.deep;
          }
          return colorScheme.outline;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return _selectedPalette.deep.withOpacity(0.3);
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
      
      // Text theme
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
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: _selectedPalette.deep,
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
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}