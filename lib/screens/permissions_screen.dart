import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../widgets/main_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Import dart:io for Platform check
import 'package:device_info_plus/device_info_plus.dart'; // Import device_info_plus
import '../services/notification_service.dart'; // Import NotificationService
import '../widgets/m3_button.dart';
import '../services/navigation_state_service.dart'; // Import navigation service

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _notificationsGranted = false;
  bool _storageGranted = false;
  bool _batteryOptimizationExempt = false;
  bool _allPermissionsProcessed = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _needsStoragePermissionResult = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Add a timeout to prevent infinite loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check notification permission
      final notificationStatus = await Permission.notification.status;
      _notificationsGranted = notificationStatus.isGranted;

      // Check storage permission
      final storageStatus = await Permission.storage.status;
      _storageGranted = storageStatus.isGranted;

      // Check battery optimization exemption
      _batteryOptimizationExempt = await Permission.ignoreBatteryOptimizations.isGranted;

      // Determine if storage permission is needed based on SDK
      _needsStoragePermissionResult = await _needsStoragePermission();
      debugPrint('Initial Check - Needs Storage Permission: $_needsStoragePermissionResult');

      // Now update storage status based on need
      if (!_needsStoragePermissionResult) {
        _storageGranted = true;
        debugPrint('Initial Check - Storage Not Needed, setting _storageGranted = true');
      }
      debugPrint('Initial Check - Storage Status: $_storageGranted');

      _updateAllPermissionsProcessed();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to check permissions: $e';
          print('Permission check error: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateAllPermissionsProcessed() {
    // Check if all *required* permissions are granted
    final bool allRequiredGranted = _notificationsGranted &&
                                    (_storageGranted || !_needsStoragePermissionResult) &&
                                    _batteryOptimizationExempt;
                                    
    // This flag now reflects if all necessary permissions are granted
    _allPermissionsProcessed = allRequiredGranted;
    
    debugPrint('Update Permissions Status: All Required Granted: $_allPermissionsProcessed (Notif: $_notificationsGranted, Storage: $_storageGranted, NeedsStorage: $_needsStoragePermissionResult, Battery: $_batteryOptimizationExempt)');
    
    // Update UI if needed
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestPermission(Permission permission, String type) async {
    final status = await permission.request();
    
    if (mounted) { 
      setState(() {
        switch (type) {
          case 'notification':
            _notificationsGranted = status.isGranted;
            break;
          case 'storage':
            _storageGranted = status.isGranted;
            break;
          case 'battery':
            _batteryOptimizationExempt = status.isGranted;
            break;
        }
        
        _updateAllPermissionsProcessed();
      });
    }
  }

  Future<void> _testNotifications() async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Run comprehensive notification diagnostic
      await notificationService.runNotificationDiagnostic();
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text("Test Sent!"),
              ],
            ),
            content: Text(
              "Test notifications have been sent:\n"
              "• Immediate notification (should appear now)\n"
              "• Scheduled notification (in 10 seconds)\n\n"
              "If you don't see them, check your notification settings or try closing the app completely and wait for the scheduled one.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text("Test Failed"),
              ],
            ),
            content: Text("Failed to send test notifications: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _continueToHome() async {
    // Still perform the local check before proceeding
    if (!_allPermissionsProcessed) {
      // Show dialog explaining why permissions are needed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Permissions Required"),
          content: Text("Please grant all required permissions to continue."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
          ],
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Update navigation state service and complete onboarding
      final navigationStateService = Provider.of<NavigationStateService>(context, listen: false);
      await navigationStateService.grantPermissions();
      await navigationStateService.completeOnboarding();
      
      // Use go_router to navigate (it will automatically redirect based on state)
      // context.go('/') will trigger the redirect logic which should now allow access to '/'
      if (mounted) {
         context.go('/'); 
      }
      
    } catch (e) {
      if (mounted) { 
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to save permission state: $e';
        });
      }
    } finally {
      // Ensure loading indicator stops if navigation doesn't happen due to unmount
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final size = MediaQuery.of(context).size;
    
    // Define colors based on theme
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFFFF5F8);
    final primaryColor = themeService.primary;
    final cardColor = isDarkMode ? const Color(0xFF272741) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  "Setting up your experience...",
                ),
              ],
            ),
          )
        : _hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: primaryColor,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Oops! Something went wrong.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty 
                        ? _errorMessage 
                        : "There was an issue setting up permissions.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _checkPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Try Again",
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _continueToHome,
                      child: Text(
                        "Skip to Home",
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "App Permissions",
                      style: TextStyle(
                        fontSize: 32,  // Increased font size
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Lilas Kokoro needs the following permissions to provide reminders and AI companion features on your device.",
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Notification Permission Card
                    _buildPermissionCard(
                      context,
                      "Notifications",
                      "Allow notifications so you never miss important reminders and updates.",
                      Icons.notifications_outlined,
                      _notificationsGranted,
                      () => _requestPermission(Permission.notification, 'notification'),
                      cardColor,
                      textColor,
                      secondaryTextColor,
                      primaryColor,
                    ),
                    
                    // Storage Permission Card (conditional based on API level)
                    if (_needsStoragePermissionResult)
                      _buildPermissionCard(
                        context,
                        "Storage",
                        "Access device storage to save images for the AI companion features.",
                        Icons.folder_outlined,
                        _storageGranted,
                        () => _requestPermission(Permission.storage, 'storage'),
                        cardColor,
                        textColor,
                        secondaryTextColor,
                        primaryColor,
                      ),
                    
                    // Battery Optimization Exemption Card (only for Android)
                    if (Platform.isAndroid)
                      _buildPermissionCard(
                        context,
                        "Battery Optimization",
                        "Keep this app exempt from battery optimization to ensure reminders work properly.",
                        Icons.battery_charging_full_outlined,
                        _batteryOptimizationExempt,
                        () => _requestPermission(Permission.ignoreBatteryOptimizations, 'battery'),
                        cardColor,
                        textColor,
                        secondaryTextColor,
                        primaryColor,
                      ),
                    
                    // Test Notification Button (only show if notifications are granted)
                    if (_notificationsGranted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          child: Material(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _testNotifications,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notification_add_outlined,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Test Notifications",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        child: Material(
                          color: _allPermissionsProcessed ? themeService.primary : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _allPermissionsProcessed ? _continueToHome : () {
                              // Show a dialog explaining why permissions are needed
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Permissions Required"),
                                  content: Text("You need to grant all required permissions to continue using the app."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text("OK"),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Center(
                              child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    "Continue",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<bool> _needsStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Android 10 or above doesn't need explicit storage permission 
        // for app-specific directories
        final bool usesScoped = androidInfo.version.sdkInt >= 29;
        debugPrint('Android SDK Version: ${androidInfo.version.sdkInt}, Uses Scoped Storage: $usesScoped');
        return !usesScoped;
      }
      return false; // iOS doesn't need explicit storage permission 
    } catch (e) {
      debugPrint('Error checking storage permission requirement: $e');
      return true; // Default to requiring permission on error
    }
  }
  
  Widget _buildPermissionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    bool isGranted,
    VoidCallback onRequestPermission,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isGranted ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGranted ? "Granted" : "Not Granted",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isGranted ? Colors.green : Colors.red,
                        ),
                      ),
                      const Spacer(),
                      if (!isGranted)
                        ElevatedButton(
                          onPressed: onRequestPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Grant"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}