import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'services/theme_service.dart';
import 'services/data_service.dart';
import 'services/notification_service.dart';
import 'services/ai_companion_service.dart';
import 'services/audio_service.dart';
import 'services/skeleton_service.dart';
import 'services/navigation_state_service.dart';
import 'widgets/main_layout.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() async {
  // Initialize Flutter binding
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Flutter rendering
  // This helps prevent Impeller rendering issues
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Global UI error handler
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 Runtime error: $error');
    return true;
  };
  
  // Enable status bar transparency for better UI
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Preload the Barriecito font to prevent flickering
  await _preloadFonts();
  
  // Create required directories if they don't exist
  await _createRequiredDirectories();
  
  // Initialize services
  final dataService = DataService();
  await dataService.initialize();
  
  // Initialize notification service with error handling
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    // Reschedule all existing reminders after initialization
    await notificationService.rescheduleAllReminders();
  } catch (e) {
    debugPrint('⚠️ Error initializing notification service: $e');
    // Continue app execution despite notification service error
  }
  
  // Initialize audio service
  final audioService = AudioService.instance;
  await audioService.initialize();
  
  // Initialize AI Companion service
  final aiCompanionService = AICompanionService();
  await aiCompanionService.initialize();
  
  // Initialize ThemeService
  final themeService = ThemeService();
  await themeService.initialize();
  
  // Initialize UserModel
  final userModel = UserModel();
  await userModel.initialize();
  
  // Set up synchronization between DataService and UserModel
  dataService.setUserUpdateCallback((updatedUser) {
    userModel.syncWith(updatedUser);
  });
  
  // Initialize SkeletonService for global skeleton loading
  final skeletonService = SkeletonService();
  
  // Initialize NavigationStateService BEFORE runApp
  final navigationStateService = NavigationStateService();
  await navigationStateService.initialize();
  
  debugPrint('🚀 App initialization completed');
  
  // Setup GoRouter
  final router = createGoRouter(navigationStateService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: dataService),
        ChangeNotifierProvider<AICompanionService>.value(value: aiCompanionService),
        ChangeNotifierProvider<AudioService>.value(value: audioService),
        ChangeNotifierProvider<NotificationService>.value(value: notificationService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<UserModel>.value(value: userModel),
        ChangeNotifierProvider<SkeletonService>.value(value: skeletonService),
        ChangeNotifierProvider<NavigationStateService>.value(value: navigationStateService),
      ],
      child: MyApp(router: router),
    ),
  );
}

// Create required directories for the app
Future<void> _createRequiredDirectories() async {
  try {
    // Get app documents directory for storing data
    final appDir = await getApplicationDocumentsDirectory();
    
    // Create directories for sounds
    final soundsDir = Directory('${appDir.path}/sounds');
    if (!await soundsDir.exists()) {
      await soundsDir.create(recursive: true);
    }
    
    final notificationSoundsDir = Directory('${appDir.path}/notification_sounds');
    if (!await notificationSoundsDir.exists()) {
      await notificationSoundsDir.create(recursive: true);
    }
    
    // Create directory for app data
    final appDataDir = Directory('${appDir.path}/app_data');
    if (!await appDataDir.exists()) {
      await appDataDir.create(recursive: true);
    }
    
    debugPrint('✅ App directories created successfully');
  } catch (e) {
    debugPrint('⚠️ Error creating directories: $e');
  }
}

// Preload fonts to prevent flickering
Future<void> _preloadFonts() async {
  try {
    // Preload the Barriecito font for onboarding screen
    // This ensures the font is loaded before the UI renders
    final fontLoader = FontLoader('Barriecito');
    fontLoader.addFont(rootBundle.load('assets/fonts/Barriecito-Regular.ttf'));
    await fontLoader.load();
    
    debugPrint('✅ Fonts preloaded successfully');
  } catch (e) {
    debugPrint('⚠️ Error preloading fonts: $e');
  }
}

// Function to create GoRouter configuration
GoRouter createGoRouter(NavigationStateService navigationStateService) {
  return GoRouter(
    initialLocation: '/', // Start at the logical root
    debugLogDiagnostics: true, // Enable console logging for router actions
    refreshListenable: navigationStateService, // Re-evaluate redirects when nav state changes
    redirect: (BuildContext context, GoRouterState state) async {
      final String location = state.matchedLocation;
      
      // Wait for initialization if not ready yet
      if (!navigationStateService.isInitialized) {
        debugPrint('Router Redirect: Waiting for NavigationStateService init...');
        return null;
      }

      final bool onboardingCompleted = navigationStateService.onboardingCompleted;
      final bool permissionsGranted = navigationStateService.permissionsGranted;

      debugPrint('Router Redirect: Current=$location, Onboarding=$onboardingCompleted, Permissions=$permissionsGranted');
      
      // Additional debugging for DataService state
      final dataService = Provider.of<DataService>(context, listen: false);
      final hasUser = dataService.hasUser();
      final currentUser = dataService.getCurrentUser();
      debugPrint('Router Redirect: HasUser=$hasUser, UserName=${currentUser?.name}');

      // Redirect logic for first-time users
      if (!onboardingCompleted) {
        // If onboarding isn't done, must go to onboarding screen
        if (location != '/onboarding') {
          debugPrint('Router Redirect: To /onboarding (not completed)');
          return '/onboarding';
        }
      } else if (!permissionsGranted) {
        // If onboarding is done but permissions aren't, must go to permissions screen
        if (location != '/permissions' && location != '/onboarding') {
          debugPrint('Router Redirect: To /permissions (not granted)');
          return '/permissions';
        }
      } else {
        // If both onboarding and permissions are done, prevent access to those screens
        if (location == '/onboarding' || location == '/permissions') {
          debugPrint('Router Redirect: To / (already completed onboarding/permissions)');
          return '/';
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayout(), // Main app layout is the root
        // Add nested routes if MainLayout uses a ShellRoute or similar
        // For simple cases, separate routes might be fine
      ),
      GoRoute(
        path: '/settings', // Example: Assuming settings is pushed on top
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      // Add other top-level routes here if needed
    ],
    errorBuilder: (context, state) {
      // Optional: Add a screen for routing errors
      return Scaffold(
        appBar: AppBar(title: const Text('Routing Error')),
        body: Center(child: Text('Page not found: ${state.error}')),
      );
    },
  );
}

// Modify MyApp to accept the router
class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({Key? key, required this.router}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Now use MaterialApp.router
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return AnimatedThemeBuilder(
          themeService: themeService,
          builder: (context, theme) {
            return MaterialApp.router(
              key: const ValueKey('app-root'),
              title: 'Lilas Kokoro',
              debugShowCheckedModeBanner: false,
              theme: themeService.lightTheme,
              darkTheme: themeService.darkTheme,
              themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              
              // Pass the router configuration
              routerConfig: router, 
              
              builder: (context, child) {
                ErrorWidget.builder = (FlutterErrorDetails details) {
                  debugPrint('🚨 Widget error: ${details.exception}');
                  return Container(
                    color: Colors.transparent,
                    child: const Center(
                      child: Icon(Icons.error_outline, color: Colors.red),
                    ),
                  );
                };
                return child ?? const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }
}

// Custom widget to handle theme animations
/// Custom widget to handle theme animations
class AnimatedThemeBuilder extends StatefulWidget {
  final ThemeService themeService;
  final Widget Function(BuildContext, ThemeData) builder;

  const AnimatedThemeBuilder({
    Key? key,
    required this.themeService,
    required this.builder,
  }) : super(key: key);

  @override
  State<AnimatedThemeBuilder> createState() => _AnimatedThemeBuilderState();
}

class _AnimatedThemeBuilderState extends State<AnimatedThemeBuilder> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late ThemeData _oldTheme;
  late ThemeData _newTheme;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _oldTheme = widget.themeService.currentTheme;
    _newTheme = widget.themeService.currentTheme;
    
    _controller = AnimationController(
      vsync: this,
      // Shorter duration for more responsive transitions
      duration: const Duration(milliseconds: 250),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animating = false;
          _oldTheme = _newTheme;
        });
      }
    });
    
    widget.themeService.addListener(_handleThemeChange);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    widget.themeService.removeListener(_handleThemeChange);
    super.dispose();
  }
  
  void _handleThemeChange() {
    final newTheme = widget.themeService.currentTheme;
    if (_newTheme == newTheme) return;
    
    if (mounted) {
    setState(() {
      _animating = true;
      _oldTheme = _animating ? _oldTheme : widget.themeService.currentTheme;
      _newTheme = newTheme;
      _controller.forward(from: 0.0);
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_animating) {
      return widget.builder(context, _newTheme);
    }
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use a more refined curve for better aesthetic feel
        final curvedAnimation = CurvedAnimation(
          parent: _controller,
          curve: Curves.fastOutSlowIn, // More elegant and dynamic curve
        );
        
        // Use ThemeData.lerp for smooth transition
        final lerpedTheme = ThemeData.lerp(
          _oldTheme, 
          _newTheme, 
          curvedAnimation.value
        );
        
        return widget.builder(context, lerpedTheme);
      },
    );
  }
}

// Custom page transition builder
class CustomTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Combine fade and slide transitions for a smooth experience
    const begin = Offset(0.05, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;
    
    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
    var offsetAnimation = animation.drive(tween);
    
    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: animation.drive(
          Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        ),
        child: child,
      ),
    );
  }
}
