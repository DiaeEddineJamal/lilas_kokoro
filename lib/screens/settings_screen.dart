import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';
import '../widgets/app_header.dart';
import '../widgets/m3_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/m3_button.dart';
import '../widgets/m3_switch.dart';
import '../models/user_model.dart';
import '../services/data_service.dart';
import '../services/skeleton_service.dart';
import '../services/ai_companion_service.dart';
import 'package:flutter/foundation.dart' show AutomaticKeepAliveClientMixin;
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _isLoadingSettings = true;
  bool _isLoadingTheme = true;
  bool _skeletonEnabled = false;
  AIModel _selectedModel = AIModel.mistral;
  final TextEditingController _customApiKeyController = TextEditingController();
  final TextEditingController _customModelEndpointController = TextEditingController();
  String _appVersion = '';
  String _appName = '';
  
  @override
  bool get wantKeepAlive => true; // Keep this widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAiSettings();
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

  @override
  void dispose() {
    _customApiKeyController.dispose();
    _customModelEndpointController.dispose();
    super.dispose();
  }

  // Sync state with the notification service to prevent visual flickers
  void _syncNotificationSettings() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    if (mounted && (
      _notificationsEnabled != notificationService.notificationsEnabled ||
      _soundEnabled != notificationService.soundEnabled ||
      _vibrationEnabled != notificationService.vibrationEnabled
    )) {
      setState(() {
        _notificationsEnabled = notificationService.notificationsEnabled;
        _soundEnabled = notificationService.soundEnabled;
        _vibrationEnabled = notificationService.vibrationEnabled;
      });
    }
  }

  Future<void> _loadSettings() async {
    // Use the NotificationService instead of SharedPreferences directly
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    setState(() {
      _notificationsEnabled = notificationService.notificationsEnabled;
      _soundEnabled = notificationService.soundEnabled;
      _vibrationEnabled = notificationService.vibrationEnabled;
      _isLoadingSettings = false;
      _isLoadingTheme = false;
    });
  }

  Future<void> _loadAiSettings() async {
    final aiService = Provider.of<AICompanionService>(context, listen: false);
    await aiService.initialize();
    
    setState(() {
      _selectedModel = aiService.selectedModel;
      _customApiKeyController.text = aiService.customApiKey ?? '';
      _customModelEndpointController.text = aiService.customModelEndpoint ?? '';
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
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Update local state immediately to prevent flickering
    setState(() {
      if (notificationsEnabled != null) {
        _notificationsEnabled = notificationsEnabled;
      }
      if (soundEnabled != null) {
        _soundEnabled = soundEnabled;
      }
      if (vibrationEnabled != null) {
        _vibrationEnabled = vibrationEnabled;
      }
    });
    
    // Then update the service
    if (notificationsEnabled != null) {
      await notificationService.setNotificationsEnabled(notificationsEnabled);
    }
    if (soundEnabled != null) {
      await notificationService.setSoundEnabled(soundEnabled);
    }
    if (vibrationEnabled != null) {
      await notificationService.setVibrationEnabled(vibrationEnabled);
    }
  }

  Future<void> _saveAiSettings() async {
    final aiService = Provider.of<AICompanionService>(context, listen: false);
    
    // Save AI model settings
    if (_selectedModel == AIModel.custom) {
      if (_customApiKeyController.text.isNotEmpty) {
        await aiService.setCustomApiKey(_customApiKeyController.text);
      }
      
      if (_customModelEndpointController.text.isNotEmpty) {
        await aiService.setCustomModelEndpoint(_customModelEndpointController.text);
      }
    }
    
    await aiService.setSelectedModel(_selectedModel);
  }

  void _handleSkeletonToggle(bool value) {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.setEnabled(value);
    setState(() {
      _skeletonEnabled = value;
    });
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
    
    return Scaffold(
      appBar: AppHeader(
        title: 'Settings',
        enableBackButton: true,
        enableActionButton: false,
      ),
      body: _isLoadingSettings || _isLoadingTheme
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme settings section
          Text(
            'Theme Settings',
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
                ],
              ),
            ),
          ),
                  const SizedBox(height: 32),
          
                  // Notification Settings
          Text(
            'Notification Settings',
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
                    value: _notificationsEnabled,
                    onChanged: (value) {
                              _saveNotificationSettings(notificationsEnabled: value);
                    },
                  ),
                          const SizedBox(height: 16),
                  M3Switch(
                    title: 'Sound',
                            subtitle: 'Play sound with notifications',
                    value: _soundEnabled,
                            onChanged: _notificationsEnabled 
                              ? (value) => _saveNotificationSettings(soundEnabled: value)
                              : (value) {} // Disabled but needs non-null callback
                          ),
                          const SizedBox(height: 16),
                  M3Switch(
                    title: 'Vibration',
                            subtitle: 'Vibrate on notification',
                    value: _vibrationEnabled,
                            onChanged: _notificationsEnabled 
                              ? (value) => _saveNotificationSettings(vibrationEnabled: value)
                              : (value) {} // Disabled but needs non-null callback
                  ),
                ],
              ),
            ),
          ),
                  const SizedBox(height: 32),
                  
                  // AI Settings
          Text(
            'AI Model Settings',
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
                  Text(
                    'Select AI Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                          // Just Mistral and Custom options
                  RadioListTile<AIModel>(
                    title: const Text('Mistral Small (Default)'),
                    subtitle: const Text('Uses Mistral Small - Free, powerful, with enough context for most conversations'),
                    value: AIModel.mistral,
                    groupValue: _selectedModel,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedModel = value!;
                      });
                              _saveAiSettings();
                    },
                  ),
                  RadioListTile<AIModel>(
                    title: const Text('Custom Model'),
                    subtitle: const Text('Use your own API model (requires API key and endpoint)'),
                    value: AIModel.custom,
                    groupValue: _selectedModel,
                    activeColor: colorScheme.primary,
                    onChanged: (value) {
                      setState(() {
                        _selectedModel = value!;
                      });
                              _saveAiSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Only show API settings for custom model
          if (_selectedModel == AIModel.custom)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      const SizedBox(height: 32),
              Text(
                'Custom Model Settings',
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _customApiKeyController,
                        decoration: const InputDecoration(
                          labelText: 'Custom API Key',
                          hintText: 'Enter your API key',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                                onChanged: (_) => _saveAiSettings(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customModelEndpointController,
                        decoration: const InputDecoration(
                          labelText: 'Model Endpoint URL',
                          hintText: 'Enter the API endpoint',
                          border: OutlineInputBorder(),
                        ),
                                onChanged: (_) => _saveAiSettings(),
                      ),
                      const SizedBox(height: 16),
                      M3Button(
                        text: 'Save API Settings',
                        icon: Icons.save,
                        onPressed: () {
                                  _saveAiSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('AI settings saved'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
                  const SizedBox(height: 32),
          Text(
            'Conversation Management',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  M3Button(
                    text: 'Clear All Conversations',
                    icon: Icons.delete_sweep,
                    buttonType: M3ButtonType.error,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Clear All Conversations'),
                          content: const Text(
                            'This will delete all your chat history with the AI companion. '
                            'This action cannot be undone. Continue?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('CLEAR'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        final aiService = Provider.of<AICompanionService>(context, listen: false);
                        await aiService.clearAllConversations();
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All conversations have been cleared'),
                            ),
                          );
                        }
                      }
                    },
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
                            subtitle: const Text('Designed with ❤️ by Lilas Kokoro Team'),
                            leading: const Icon(Icons.favorite),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
          const SizedBox(height: 40), // Extra space at bottom to prevent overflow
        ],
              ),
            ),
      ),
    );
  }
}
