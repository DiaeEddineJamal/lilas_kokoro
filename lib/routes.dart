import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/ai_companion_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/love_counter_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/main_layout.dart';

// Define route paths as constants
class Routes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String permissions = '/permissions';
  static const String dashboard = '/dashboard';
  static const String aiCompanion = '/ai-companion';
  static const String reminders = '/reminders';
  static const String loveCounter = '/love-counter';
  static const String settings = '/settings';
  static const String profileEdit = '/profile-edit';
}

/// Custom page route with beautiful transitions
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final TransitionType transitionType;
  
  SmoothPageRoute({
    required this.page,
    this.transitionType = TransitionType.rightToLeft,
    RouteSettings? settings,
  }) : super(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Define different transition types
      switch (transitionType) {
        case TransitionType.fade:
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
          
        case TransitionType.scale:
          return ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
          
        case TransitionType.rightToLeft:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        
        case TransitionType.bottomToTop:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
      }
    },
  );
}

// Transition types for different screens
enum TransitionType {
  fade,
  scale,
  rightToLeft,
  bottomToTop,
}

/// Route generator for the app
class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return SmoothPageRoute(
          page: const SplashScreen(),
          transitionType: TransitionType.fade,
          settings: settings,
        );
        
      case Routes.onboarding:
        return SmoothPageRoute(
          page: const OnboardingScreen(),
          transitionType: TransitionType.fade,
          settings: settings,
        );
        
      case Routes.permissions:
        return SmoothPageRoute(
          page: const PermissionsScreen(),
          transitionType: TransitionType.fade,
          settings: settings,
        );

      case Routes.dashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] as int?;
        return SmoothPageRoute(
          page: MainLayout(initialTab: initialTab),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );

      case Routes.aiCompanion:
        final conversationId = settings.arguments as String?;
        return SmoothPageRoute(
          page: AICompanionScreen(conversationId: conversationId),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );
        
      case Routes.reminders:
        return SmoothPageRoute(
          page: const RemindersScreen(),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );

      case Routes.loveCounter:
        return SmoothPageRoute(
          page: const LoveCounterScreen(),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );

      case Routes.settings:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] as int?;
        return SmoothPageRoute(
          page: MainLayout(initialTab: initialTab),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );

      case Routes.profileEdit:
        return SmoothPageRoute(
          page: const ProfileEditScreen(),
          transitionType: TransitionType.rightToLeft,
          settings: settings,
        );
        
      case Routes.home:
      default:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] as int?;
        return SmoothPageRoute(
          page: MainLayout(initialTab: initialTab),
          transitionType: TransitionType.fade,
          settings: settings,
        );
    }
  }
} 