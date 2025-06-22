import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationStateService extends ChangeNotifier {
  bool _onboardingCompleted = false;
  bool _permissionsGranted = false;
  bool _initialized = false;

  // Global navigator key for navigation from notification callbacks
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool get onboardingCompleted => _onboardingCompleted;
  bool get permissionsGranted => _permissionsGranted;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if this is a fresh installation
      final bool isFreshInstall = await _detectFreshInstall(prefs);
      
      if (isFreshInstall) {
        debugPrint('🆕 Fresh installation detected - resetting all data');
        await _resetAllData(prefs);
        _onboardingCompleted = false;
        _permissionsGranted = false;
      } else {
        _onboardingCompleted = prefs.getBool('onboarding_complete') ?? false;
        _permissionsGranted = prefs.getBool('permissions_granted') ?? false;
      }
      
      _initialized = true;
      debugPrint('✅ NavigationStateService Initialized: onboarding=$_onboardingCompleted, permissions=$_permissionsGranted');
      debugPrint('📱 NavigationStateService: SharedPreferences keys: ${prefs.getKeys()}');
      notifyListeners(); // Notify listeners that initialization is complete
    } catch (e) {
      debugPrint('❌ Error initializing NavigationStateService: $e');
      // Use defaults in case of error
      _onboardingCompleted = false;
      _permissionsGranted = false;
      _initialized = true; // Mark as initialized even on error to avoid blocking
      notifyListeners();
    }
  }

  /// Detects if this is a fresh installation by checking app version and install markers
  Future<bool> _detectFreshInstall(SharedPreferences prefs) async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String currentBuildNumber = packageInfo.buildNumber;
      
      // Check stored version info
      final String? storedVersion = prefs.getString('app_version');
      final String? storedBuildNumber = prefs.getString('app_build_number');
      final bool hasInstallMarker = prefs.getBool('app_installed') ?? false;
      final int? lastInstallTime = prefs.getInt('last_install_time');
      final int currentTime = DateTime.now().millisecondsSinceEpoch;
      
      debugPrint('🔍 Install Detection: Current v$currentVersion ($currentBuildNumber), Stored v$storedVersion ($storedBuildNumber), HasMarker: $hasInstallMarker');
      
      // Check for development mode indicators
      final bool isDevelopmentMode = kDebugMode;
      final bool isFirstTimeEver = storedVersion == null && storedBuildNumber == null;
      
      // Check if we have valid onboarding completion
      final bool hasOnboarding = prefs.getBool('onboarding_complete') ?? false;
      final bool hasUserData = prefs.getString('user_data') != null;
      
      // Smarter fresh install detection for better hot restart support
      // Consider it a fresh install if:
      // 1. No install marker exists (first time ever), OR
      // 2. Version or build number changed, OR  
      // 3. No user data exists but onboarding claims to be complete, OR
      // 4. In debug mode and it's been more than 10 minutes since last install (allows hot restarts), OR
      // 5. Any critical app data is missing but install marker exists (corrupted state), OR
      // 6. More than 24 hours have passed in debug mode (prevent stale debug state)
      final bool noInstallMarker = !hasInstallMarker || isFirstTimeEver;
      final bool versionChanged = storedVersion != currentVersion || storedBuildNumber != currentBuildNumber;
      final bool hasInconsistentState = _hasInconsistentData(prefs);
      
      // More reasonable debug interval - 10 minutes instead of 30 seconds
      // This allows for hot restarts while still detecting fresh installs
      final bool debugModeReasonableInterval = isDevelopmentMode && 
          (lastInstallTime == null || (currentTime - lastInstallTime) > 600000); // 10 minutes in debug
      
      final bool debugModeStaleState = isDevelopmentMode && 
          lastInstallTime != null && 
          (currentTime - lastInstallTime) > 86400000; // 24 hours in debug
      
      final bool hasCorruptedData = _hasCorruptedData(prefs);
      
      // If we have onboarding complete and user data, don't reset unless there's a real issue
      final bool hasValidSession = hasOnboarding && hasUserData && hasInstallMarker;
      
      // Only consider fresh if there's a real reason, not just debug mode timing
      final bool isFresh = noInstallMarker || 
                          versionChanged || 
                          hasInconsistentState || 
                          hasCorruptedData ||
                          (debugModeReasonableInterval && !hasValidSession) ||
                          debugModeStaleState;
      
      // Update install markers for future checks (but preserve existing session if valid)
      if (!hasValidSession || versionChanged) {
        await prefs.setString('app_version', currentVersion);
        await prefs.setString('app_build_number', currentBuildNumber);
        await prefs.setBool('app_installed', true);
        await prefs.setInt('last_install_time', currentTime);
      }
      
      // Add additional debug info
      debugPrint('🎯 Fresh Install Decision: $isFresh');
      debugPrint('   - NoMarker: $noInstallMarker');
      debugPrint('   - VersionChanged: $versionChanged'); 
      debugPrint('   - InconsistentState: $hasInconsistentState');
      debugPrint('   - DebugReasonableInterval: $debugModeReasonableInterval');
      debugPrint('   - DebugStaleState: $debugModeStaleState');
      debugPrint('   - CorruptedData: $hasCorruptedData');
      debugPrint('   - HasValidSession: $hasValidSession');
      debugPrint('   - IsDebugMode: $isDevelopmentMode');
      debugPrint('   - IsFirstTimeEver: $isFirstTimeEver');
      debugPrint('   - HasOnboarding: $hasOnboarding');
      debugPrint('   - HasUserData: $hasUserData');
      
      return isFresh;
    } catch (e) {
      debugPrint('❌ Error detecting fresh install: $e');
      return true; // Default to fresh install to be safe
    }
  }

  /// Checks for inconsistent data state that suggests a problematic previous installation
  bool _hasInconsistentData(SharedPreferences prefs) {
    final bool onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final bool hasUserData = prefs.getString('user_data') != null;
    final bool hasAnyAppData = prefs.getKeys().any((key) => 
        key.contains('user_') || 
        key.contains('reminder') || 
        key.contains('conversation') ||
        key.contains('love_counter')
    );
    
    // If onboarding is complete but no user data exists, this is inconsistent
    // This can happen with partial data recovery or corrupted state
    return onboardingComplete && (!hasUserData || !hasAnyAppData);
  }

  /// Checks for corrupted data that indicates a problematic installation
  bool _hasCorruptedData(SharedPreferences prefs) {
    try {
      // Check if critical app preferences are corrupted
      final keys = prefs.getKeys();
      
      // If we have install markers but no app-specific data at all
      final hasInstallMarkers = prefs.getBool('app_installed') ?? false;
      final hasAppData = keys.any((key) => 
          key.startsWith('onboarding_') || 
          key.startsWith('user_') ||
          key.startsWith('permissions_')
      );
      
      // If install markers exist but absolutely no app data, likely corrupted
      if (hasInstallMarkers && !hasAppData && keys.length < 5) {
        debugPrint('🚨 Detected corrupted installation state');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking for corrupted data: $e');
      return true; // Assume corrupted if we can't check
    }
  }

  /// Resets all app data for a fresh start
  Future<void> _resetAllData(SharedPreferences prefs) async {
    try {
      // Keep only the install markers and version info
      final String? appVersion = prefs.getString('app_version');
      final String? appBuildNumber = prefs.getString('app_build_number');
      
      // Clear all data
      await prefs.clear();
      
      // Restore install markers
      if (appVersion != null) await prefs.setString('app_version', appVersion);
      if (appBuildNumber != null) await prefs.setString('app_build_number', appBuildNumber);
      await prefs.setBool('app_installed', true);
      
      debugPrint('🧹 All app data reset for fresh installation');
    } catch (e) {
      debugPrint('❌ Error resetting app data: $e');
    }
  }

  Future<void> completeOnboarding() async {
    if (_onboardingCompleted) return;
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    debugPrint('🔄 NavigationStateService: Onboarding completed');
    notifyListeners();
  }

  Future<void> grantPermissions() async {
    if (_permissionsGranted) return;
    _permissionsGranted = true;
    final prefs = await SharedPreferences.getInstance();
    // Ensure permissions_requested is also set, mirroring PermissionsScreen logic
    await prefs.setBool('permissions_requested', true); 
    await prefs.setBool('permissions_granted', true);
    debugPrint('🔄 NavigationStateService: Permissions granted');
    notifyListeners();
  }

  // Reset onboarding state (for testing or user reset)
  Future<void> resetOnboarding() async {
    _onboardingCompleted = false;
    _permissionsGranted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    await prefs.setBool('permissions_granted', false);
    await prefs.remove('permissions_requested');
    
    // Also clear all user data to ensure fresh start
    await prefs.remove('user_data');
    await prefs.remove('reminders_data');
    await prefs.remove('love_counter_data');
    await prefs.remove('sounds_data');
    await prefs.remove('conversations');
    
    debugPrint('🔄 NavigationStateService: All data reset - fresh start');
    notifyListeners();
  }

  /// Force a complete app reset as if it's a fresh installation
  /// This method can be called from the settings screen for testing purposes
  Future<void> forceCompleteReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear everything including install markers
      await prefs.clear();
      
      // Reset internal state
      _onboardingCompleted = false;
      _permissionsGranted = false;
      _initialized = false;
      
      debugPrint('🧹 Complete app reset performed - next launch will be treated as fresh install');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error performing complete reset: $e');
    }
  }

  /// Force fresh install detection on next app launch (for development/testing)
  Future<void> forceFreshInstallOnNextLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove install markers to trigger fresh install detection
      await prefs.remove('app_installed');
      await prefs.remove('app_version');
      await prefs.remove('app_build_number');
      await prefs.remove('last_install_time');
      
      debugPrint('🧹 Fresh install markers removed - next launch will be treated as fresh install');
    } catch (e) {
      debugPrint('❌ Error removing fresh install markers: $e');
    }
  }

  // Global navigation method for notification callbacks
  static Future<void> navigateFromNotification(String route, {Object? arguments}) async {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        debugPrint('📱 Navigating from notification to: $route');
        
        // Use GoRouter for navigation
        if (route == '/reminders') {
          context.go('/dashboard'); // Navigate to main layout which includes reminders
          // You could also use context.go('/reminders') if you have a direct route
        } else {
          context.go(route);
        }
      } else {
        debugPrint('⚠️ Navigation context not available for notification navigation');
      }
    } catch (e) {
      debugPrint('❌ Error navigating from notification: $e');
    }
  }
  
  // Method to handle deep links from notifications
  static Future<void> handleNotificationDeepLink(String payload) async {
    try {
      debugPrint('📱 Handling notification deep link: $payload');
      
      if (payload.startsWith('navigate:')) {
        final route = payload.substring(9); // Remove 'navigate:' prefix
        await navigateFromNotification('/$route');
      } else if (payload.startsWith('reminder:')) {
        // Navigate to reminders screen for reminder notifications
        await navigateFromNotification('/dashboard');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification deep link: $e');
    }
  }
} 