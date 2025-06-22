import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lilas_kokoro/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isFirstLaunch = true;
  bool _hasNavigated = false;
  Map<String, Color> _themeColors = {};

  @override
  void initState() {
    super.initState();
    _loadThemeColorsAsync();
    _checkFirstLaunch();
    _startNavigationTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load theme colors after the widget tree is built and providers are available
    _loadThemeColorsSync();
  }
  
  /// Load theme colors asynchronously in initState to prevent flashing
  Future<void> _loadThemeColorsAsync() async {
    try {
      final colors = await ThemeService.getCurrentThemeColors();
      if (mounted) {
        setState(() {
          _themeColors = colors;
        });
        debugPrint('✅ Theme colors loaded asynchronously: Primary=${_themeColors['primary']}, Accent=${_themeColors['accent']}');
      }
    } catch (e) {
      debugPrint('⚠️ Could not load theme colors asynchronously: $e');
    }
  }

  /// Load theme colors synchronously to prevent flashing
  void _loadThemeColorsSync() {
    try {
      final themeService = Provider.of<ThemeService>(context, listen: false);
      setState(() {
        _themeColors = {
          'primary': themeService.selectedPalette.primary,
          'secondary': themeService.selectedPalette.secondary,
          'accent': themeService.selectedPalette.accent,
        };
      });
      debugPrint('✅ Theme colors loaded synchronously: Primary=${_themeColors['primary']}, Accent=${_themeColors['accent']}');
    } catch (e) {
      debugPrint('⚠️ Could not load theme colors synchronously: $e');
      // Set fallback colors
      setState(() {
        _themeColors = {
          'primary': const Color(0xFFFF69B4),
          'secondary': const Color(0xFFFF1493),
          'accent': const Color(0xFF87CEEB),
        };
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;
      
      if (mounted) {
        setState(() {
          _isFirstLaunch = !hasCompletedOnboarding;
        });
      }
    } catch (e) {
      debugPrint('Error checking first launch: $e');
    }
  }

  void _startNavigationTimer() {
    // Navigate after 3 seconds as requested
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    
    try {
      _hasNavigated = true;
      
      if (_isFirstLaunch) {
        context.go('/onboarding');
        debugPrint('✅ Navigated to onboarding');
      } else {
        context.go('/');
        debugPrint('✅ Navigated to home');
      }
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
      try {
        _hasNavigated = true;
        context.go('/');
        debugPrint('✅ Fallback navigation completed');
      } catch (fallbackError) {
        debugPrint('❌ Fallback navigation also failed: $fallbackError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _buildOptimizedGradient(),
        ),
        child: Stack(
          children: [
            // Centered app icon with shadow effect
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/App-icon.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium, // Balanced quality/performance
                  ),
                ),
              ),
            ),
            
            // Bottom loading section with puppy
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: SizedBox(
                width: 120,
                height: 90,
                child: Lottie.asset(
                  'assets/animations/loading-puppy.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  options: LottieOptions(
                    enableMergePaths: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Optimized gradient with performance considerations
  LinearGradient _buildOptimizedGradient() {
    final List<Color> gradientColors = _getGradientColors();
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
      stops: const [0.0, 1.0], // Simple two-color gradient
    );
  }

  /// Get beautiful two-color gradient colors (consistent with app design)
  List<Color> _getGradientColors() {
    if (_isFirstLaunch) {
      // Clean "Witching Hour" two-color gradient - elegant and fast
      return [
        const Color(0xFFC31432), // Deep crimson red
        const Color(0xFF240B36), // Dark purple/violet
      ];
    }

    // Only use dynamic theme gradient if theme colors are loaded
    if (_themeColors.isNotEmpty) {
      return [
        _getPrimaryColor(),
        _getAccentColor(),
      ];
    }

    // Show a neutral gradient while theme loads to prevent flashing
    return [
      const Color(0xFF6C63FF), // Soft purple
      const Color(0xFF4ECDC4), // Soft teal
    ];
  }

  Color _getPrimaryColor() {
    return _themeColors['primary'] ?? const Color(0xFFFF69B4); // Hot pink fallback
  }

  Color _getSecondaryColor() {
    return _themeColors['secondary'] ?? const Color(0xFFFF1493); // Deep pink fallback
  }

  Color _getAccentColor() {
    return _themeColors['accent'] ?? const Color(0xFF87CEEB); // Sky blue fallback
  }
}

 