import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_header.dart';
import '../widgets/m3_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/m3_button.dart';
import '../widgets/m3_switch.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/skeleton_service.dart';
import '../services/ai_companion_service.dart';
import '../services/navigation_state_service.dart';

import 'package:flutter/foundation.dart' show AutomaticKeepAliveClientMixin;
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/skeleton_loader.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  bool _notificationsEnabled = true;
  bool _isLoadingSettings = true;
  bool _isLoadingTheme = true;
  bool _skeletonEnabled = false;
  String _appVersion = '';
  String _appName = '';
  
  @override
  bool get wantKeepAlive => true; // Keep this widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkeletonService>(context, listen: false).isEnabled.then((value) {
        setState(() {
          _skeletonEnabled = value;
          _isLoadingTheme = false;
        });
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure settings are up to date when the theme changes
    _syncNotificationSettings();
  }

  // Sync state with the notification service to prevent visual flickers
  void _syncNotificationSettings() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    if (mounted && _notificationsEnabled != notificationService.notificationsEnabled) {
      setState(() {
        _notificationsEnabled = notificationService.notificationsEnabled;
      });
    }
  }

  Future<void> _loadSettings() async {
    // Use the NotificationService instead of SharedPreferences directly
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    setState(() {
      _notificationsEnabled = notificationService.notificationsEnabled;
      _isLoadingSettings = false;
      _isLoadingTheme = false;
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
      setState(() {
        _appName = 'Lilas Kokoro';
        _appVersion = '1.0.0';
      });
    }
  }

  Future<void> _saveNotificationSettings({
    bool? notificationsEnabled,
  }) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Update local state immediately to prevent flickering
    setState(() {
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
      }
    });
    
    // Then update the service
    if (notificationsEnabled != null) {
      await notificationService.setNotificationsEnabled(notificationsEnabled);
      
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationsEnabled 
                ? 'Notifications enabled - you will receive reminder pop-ups'
                : 'Notifications disabled - reminder pop-ups are blocked'
            ),
            backgroundColor: notificationsEnabled ? Colors.green : Colors.orange,
          ),
        );
      }
    }
  }



  void _handleSkeletonToggle(bool value) {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.setEnabled(value);
    setState(() {
      _skeletonEnabled = value;
    });
  }

  Future<void> _loadUserData() async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withQuickToggle(() async {
      // Simulate loading time for smooth UX
      await Future.delayed(const Duration(milliseconds: 600));
    });
  }

  Future<void> _onRefresh() async {
    await _loadUserData();
    if (mounted) {
      setState(() {}); // Trigger rebuild to refresh user data
    }
  }

  Future<void> _launchGitHub() async {
    final Uri githubUrl = Uri.parse('https://github.com/DiaeEddineJamal');
    try {
      if (await canLaunchUrl(githubUrl)) {
        await launchUrl(
          githubUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open GitHub profile'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening GitHub profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final ThemeService themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final userModel = Provider.of<UserModel>(context);
    final dataService = Provider.of<DataService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final notificationService = Provider.of<NotificationService>(context);
    final skeletonService = Provider.of<SkeletonService>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SkeletonLoaderFixed(
        isLoading: skeletonService.isLoading,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: themeService.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoadingSettings || _isLoadingTheme
                  ? const Center(child: CircularProgressIndicator())
                  : SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile section
                            Text(
                              '👤 Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            M3Card(
                              onTap: () {
                                context.push('/profile-edit');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Profile avatar with actual profile picture
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: userModel.profileImagePath.isNotEmpty
                                          ? FileImage(File(userModel.profileImagePath))
                                          : null,
                                      child: userModel.profileImagePath.isEmpty
                                          ? Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: RadialGradient(
                                                                                  colors: themeService.isDarkMode
                                  ? themeService.darkGradient
                                  : themeService.lightGradient,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    // Profile info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userModel.name.isNotEmpty ? userModel.name : 'User',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onBackground,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to edit profile',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onBackground.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit button
                                    IconButton(
                                      onPressed: () {
                                        context.push('/profile-edit');
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Theme settings section
                            Text(
                              '🎨 Theme Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            M3Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('Dark Mode'),
                                      value: themeService.isDarkMode,
                                      activeColor: colorScheme.primary,
                                      onChanged: (bool value) async {
                                        await themeService.toggleTheme();
                                      },
                                    ),
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Color Palette',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: ThemeService.availablePalettes.length,
                                      itemBuilder: (context, index) {
                                        final palette = ThemeService.availablePalettes[index];
                                        final isSelected = themeService.selectedPalette.name == palette.name;
                                        
                                        return GestureDetector(
                                          onTap: () async {
                                            await themeService.changeColorPalette(index);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Changed to ${palette.name} palette'),
                                                  backgroundColor: palette.primary,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: palette.lightGradient,
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              border: isSelected 
                                                  ? Border.all(
                                                      color: colorScheme.primary,
                                                      width: 3,
                                                    )
                                                  : Border.all(
                                                      color: Colors.grey.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: palette.primary.withOpacity(0.3),
                                                  blurRadius: isSelected ? 8 : 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  palette.icon,
                                                  style: const TextStyle(fontSize: 20),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  palette.name.split(' ')[0], // First word only
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black26,
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                    
                            // Notification Settings
                            Text(
                              '🔔 Notification Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            M3Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    M3Switch(
                                      title: 'Enable Notifications',
                                      subtitle: 'Receive notification pop-ups for reminders',
                                      value: _notificationsEnabled,
                                      onChanged: (value) async {
                                        await _saveNotificationSettings(notificationsEnabled: value);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // AI Settings
                            Text(
                              '🤖 AI Model Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            M3Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.smart_toy),
                                      title: const Text('Mistral Small'),
                                      subtitle: const Text('Free, powerful AI model with enough context for most conversations'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: themeService.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // About section
                            Text(
                              'About',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            M3Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      title: const Text('App Version'),
                                      subtitle: Text(_appVersion),
                                      leading: const Icon(Icons.info_outline),
                                    ),
                                    const Divider(),
                                    ListTile(
                                      title: const Text('Credits'),
                                      subtitle: const Text('Designed with ❤️ by Diae-Eddine Jamal'),
                                      leading: const Icon(Icons.favorite),
                                      trailing: const Icon(Icons.open_in_new),
                                      onTap: () => _launchGitHub(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 60), // Extra space at bottom to fix overflow
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
