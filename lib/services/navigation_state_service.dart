import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationStateService extends ChangeNotifier {
  bool _onboardingCompleted = false;
  bool _permissionsGranted = false;
  bool _initialized = false;

  bool get onboardingCompleted => _onboardingCompleted;
  bool get permissionsGranted => _permissionsGranted;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _onboardingCompleted = prefs.getBool('onboarding_complete') ?? false;
      _permissionsGranted = prefs.getBool('permissions_granted') ?? false;
      _initialized = true;
      debugPrint('✅ NavigationStateService Initialized: onboarding=$_onboardingCompleted, permissions=$_permissionsGranted');
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
} 