import 'package:flutter/material.dart';
import 'package:lilas_kokoro/models/reminder_model.dart';
import 'package:lilas_kokoro/services/data_service.dart';
import 'package:lilas_kokoro/services/navigation_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'theme_service.dart';
import '../models/user_model.dart';
import '../models/sound_model.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'sound_manager.dart';
import 'audio_service.dart';
import 'dart:convert';
import 'package:go_router/go_router.dart';

// This needs to be a top-level function or a static method to be accessible from the background.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This function is called when the app is in the background or terminated.
  debugPrint('🔔 Background notification tapped: ${notificationResponse.payload}');
  debugPrint('🔔 Action ID: ${notificationResponse.actionId}');
  
  try {
    // Handle notification actions in background with enhanced error handling
    if (notificationResponse.payload != null && 
        notificationResponse.payload!.isNotEmpty &&
        notificationResponse.payload!.startsWith('reminder:')) {
      
        final parts = notificationResponse.payload!.split(':');
        if (parts.length >= 2) {
          final reminderId = parts[1];
        
        if (notificationResponse.actionId == 'mark_complete') {
          NotificationService._markReminderCompleteNew(reminderId).catchError((error) {
            debugPrint('❌ Background error marking reminder complete: $error');
          });
        } 
        else if (notificationResponse.actionId == 'snooze_reminder') {
          NotificationService._snoozeReminderNew(reminderId).catchError((error) {
            debugPrint('❌ Background error snoozing reminder: $error');
          });
        }
        else {
          // Regular notification tap - navigate to reminders
          debugPrint('📱 Background notification tap - navigating to reminders');
        }
      }
    }
  } catch (e) {
    debugPrint('❌ Critical error in background notification handler: $e');
    // Don't rethrow - prevent app crashes
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  bool _notificationsEnabled = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  factory NotificationService() => _instance;
  
  NotificationService._internal();

  // Getters for state
  bool get notificationsEnabled => _notificationsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  // Add this method to handle iOS local notifications
  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('Received iOS local notification: $id, $title, $body, $payload');
    // You can implement custom handling for iOS notifications here
  }
  
  // Add this method to load user preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      debugPrint('✅ Notification preferences loaded: sound=$_soundEnabled, notifications=$_notificationsEnabled, vibration=$_vibrationEnabled');
    } catch (e) {
      debugPrint('❌ Error loading notification preferences: $e');
      // Use defaults if there's an error
      _soundEnabled = true;
      _notificationsEnabled = true;
      _vibrationEnabled = true;
    }
  }
  
  // Setters for state with persistence
  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    
    // If disabling notifications, cancel all scheduled notifications
    if (!value) {
      await cancelAllNotifications();
    }
    
    notifyListeners();
  }
  
  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) return;
    
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    notifyListeners();
  }
  
  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value) return;
    
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', value);
    notifyListeners();
  }

  // Initialize notification service with enhanced crash prevention
  Future<void> initialize() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🔔 Initializing NotificationService...');
      
      // Initialize timezone with comprehensive error handling
      try {
        tz_data.initializeTimeZones();
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('🌍 Timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('⚠️ Error setting timezone: $e - using UTC as fallback');
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (fallbackError) {
          debugPrint('❌ Critical timezone error: $fallbackError');
        }
      }
      
      // Load preferences first with error handling
      try {
      await _loadPreferences();
      } catch (e) {
        debugPrint('⚠️ Error loading preferences: $e - using defaults');
        _soundEnabled = true;
        _notificationsEnabled = true;
        _vibrationEnabled = true;
      }
      
      // Initialize notification plugin with enhanced error handling
      try {
      const AndroidInitializationSettings androidInitializationSettings =
            AndroidInitializationSettings('@mipmap/launcher_icon');
      
      const DarwinInitializationSettings iosInitializationSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );
      
      final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
        );
      
      debugPrint('🔔 Notification plugin initialized: $initialized');
      
        if (initialized != true) {
          debugPrint('⚠️ Notification plugin initialization returned false');
        }
        
      } catch (e) {
        debugPrint('❌ Critical error initializing notification plugin: $e');
        // Continue with reduced functionality
      }
      
      // Create notification channels for Android with enhanced error handling
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          // Create channels with safe configuration
          const List<AndroidNotificationChannel> channels = [
            AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Important reminders and notifications',
              importance: Importance.max,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
              ledColor: Color(0xFFFF69B4),
            ),
            AndroidNotificationChannel(
            'test_channel',
            'Test Notifications',
            description: 'Test notifications for debugging',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
            ledColor: Color(0xFFFF69B4),
            ),
            AndroidNotificationChannel(
            'completion_channel',
            'Task Completions',
            description: 'Confirmations when tasks are completed',
            importance: Importance.low,
            enableVibration: false,
            enableLights: false,
            playSound: false,
            showBadge: false,
            ),
          ];
          
          // Create each channel with individual error handling
          for (final channel in channels) {
            try {
              await androidPlugin.createNotificationChannel(channel);
              debugPrint('✅ Created notification channel: ${channel.id}');
      } catch (e) {
              debugPrint('⚠️ Error creating channel ${channel.id}: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error creating notification channels: $e');
      }
      
      debugPrint('✅ NotificationService initialization completed');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error during NotificationService initialization: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Set safe defaults
      _notificationsEnabled = false; // Disable notifications if initialization fails
      _soundEnabled = true;
      _vibrationEnabled = true;
      
      // Don't rethrow - allow app to continue with reduced functionality
    }
  }
  
  // Add debug logging method
  Future<void> _logNotificationStatus() async {
    try {
      debugPrint('📊 === NOTIFICATION STATUS DEBUG ===');
      final status = await getDetailedNotificationStatus();
      status.forEach((key, value) {
        debugPrint('📊 $key: $value');
      });
      debugPrint('📊 === END NOTIFICATION STATUS ===');
    } catch (e) {
      debugPrint('❌ Error logging notification status: $e');
    }
  }
  
  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    debugPrint('🔔 Requesting notification permissions...');
    
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      // For Android 13+ (API 33+), we need to explicitly request permission
      try {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        debugPrint('🔔 Android notification permission granted: $granted');
        
        // Also check if notifications are enabled
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('🔔 Android notifications enabled: $enabled');
        
        // Request exact alarm permission for Android 12+
        try {
          final bool? exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
          debugPrint('🔔 Exact alarm permission granted: $exactAlarmPermission');
        } catch (e) {
          debugPrint('⚠️ Exact alarm permission not available or error: $e');
        }
        
        return granted ?? false;
      } catch (e) {
        debugPrint('❌ Error requesting Android permissions: $e');
        return false;
      }
    }
    
    // For iOS, request permission
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
            
    if (iosPlugin != null) {
      try {
        final bool? result = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        debugPrint('🔔 iOS notification permission granted: $result');
        return result ?? false;
      } catch (e) {
        debugPrint('❌ Error requesting iOS permissions: $e');
        return false;
      }
    }
    
    return false;
  }

  // Request battery optimization exemption for better background notifications
  Future<void> requestBatteryOptimizationExemption() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🔋 Requesting battery optimization exemption...');
      
      // For Android, we can guide the user to disable battery optimization
      // The actual implementation would require platform-specific code
      debugPrint('💡 User should disable battery optimization for the app in device settings');
      debugPrint('📱 This helps ensure notifications work when the app is closed');
      
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization exemption: $e');
    }
  }
  
  // Handle notification response (including action buttons) - Enhanced crash prevention
  void onNotificationResponse(NotificationResponse response) {
    // Use the new static handler for better reliability
    _onNotificationResponseNew(response).catchError((error) {
      debugPrint('❌ Error in notification response handler: $error');
    });
  }
  
  // Handle notification tap to navigate to reminders screen
  Future<void> _handleNotificationTap(String reminderId) async {
    try {
      debugPrint('📱 Handling notification tap for reminder: $reminderId');
      
      // Cancel the notification since user tapped it
      final notificationId = reminderId.hashCode.abs() % 100000;
      await cancelNotification(notificationId);
      
      // Navigate to reminders tab (index 1) in main layout
      final navigatorKey = NavigationStateService.navigatorKey;
      if (navigatorKey.currentContext != null) {
        navigatorKey.currentContext!.go('/', extra: {'initialTab': 1});
      }
      
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }
  
  // Enhanced method to mark a reminder as complete with UI updates
  Future<void> _markReminderComplete(String reminderId) async {
    try {
      debugPrint('🔔 Marking reminder complete: $reminderId');
      
      // Validate input
      if (reminderId.isEmpty) {
        debugPrint('⚠️ Empty reminder ID provided');
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      
      if (reminders.isEmpty) {
        debugPrint('⚠️ No reminders found');
        return;
      }
      
      final reminderIndex = reminders.indexWhere((r) => r.id == reminderId);
      
      if (reminderIndex < 0) {
        debugPrint('⚠️ Reminder not found: $reminderId');
        return;
      }
      
      final reminder = reminders[reminderIndex];
      final updatedReminder = reminder.copyWith(isCompleted: true);
      
      // Update reminder in data service (this will notify UI listeners)
      await dataService.updateReminder(updatedReminder);
    
      // Cancel the original notification
      final notificationId = reminderId.hashCode.abs() % 100000;
      await cancelNotification(notificationId);
      
      // Show completion confirmation
      await showNotification(
        title: '✅ Task Completed!',
        body: '${reminder.title} has been marked as complete',
        id: 99990 + notificationId,
        payload: 'feedback:completed',
      );
      
      debugPrint('✅ Marked reminder complete: $reminderId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error marking reminder complete: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  // Enhanced method to snooze a reminder with better scheduling
  Future<void> _snoozeReminder(String reminderId) async {
    try {
      debugPrint('🔔 Snoozing reminder: $reminderId');
      
      // Validate input
      if (reminderId.isEmpty) {
        debugPrint('⚠️ Empty reminder ID provided');
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      
      if (reminders.isEmpty) {
        debugPrint('⚠️ No reminders found');
        return;
      }
      
      final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;
      
      if (reminder == null) {
        debugPrint('⚠️ Reminder not found: $reminderId');
        return;
      }
      
      final notificationId = reminderId.hashCode.abs() % 100000;
      
      // Cancel the current notification
      await cancelNotification(notificationId);
      
      // Calculate snooze time (5 minutes from now)
      final now = DateTime.now();
      final snoozeTime = now.add(const Duration(minutes: 5));
      
      // Schedule the snoozed notification
      await scheduleNotification(
        title: '⏰ ${reminder.title} (Snoozed)',
        body: 'Snoozed for 5 minutes • Will remind again at ${DateFormat('HH:mm').format(snoozeTime)}',
        id: notificationId,
        scheduledTime: snoozeTime,
        payload: 'reminder:${reminder.id}',
      );
      
      // Show snooze feedback
      await showNotification(
        title: '⏰ Reminder Snoozed',
        body: 'Will remind you again at ${DateFormat('HH:mm').format(snoozeTime)}',
        id: 99980 + notificationId,
        payload: 'feedback:snoozed',
      );
      
      debugPrint('✅ Reminder snoozed for 5 minutes: $reminderId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error snoozing reminder: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  // Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    bool vibrate = true,
  }) async {
    if (kIsWeb) return;

    final androidDetails = await _getAndroidNotificationDetails(
      ongoing: ongoing,
      autoCancel: autoCancel,
      vibrate: vibrate,
    );

    final iosDetails = await _getIOSNotificationDetails();

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // Schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required int id,
    required DateTime scheduledTime,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
    bool vibrate = true,
    String? customSoundPath,
    bool isSnoozeReminder = false,
  }) async {
    if (kIsWeb) return;
    
    if (!_notificationsEnabled) {
      debugPrint('⚠️ Notifications are disabled. Skipping scheduling.');
      return;
    }

    debugPrint('📅 Scheduling notification for ${scheduledTime.toString()}');
    debugPrint('🔊 Custom sound path: $customSoundPath');
    
    final androidDetails = await _getAndroidNotificationDetails(
      ongoing: ongoing,
      autoCancel: autoCancel,
      vibrate: vibrate,
      customSoundPath: customSoundPath ?? '', // Convert null to empty string
    );

    final iosDetails = await _getIOSNotificationDetails(
      customSoundPath: customSoundPath,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    
    debugPrint('✅ Notification scheduled for ${tzDateTime.toString()}');
  }

  // Cancel a notification
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get Android notification details
  Future<AndroidNotificationDetails> _getAndroidNotificationDetails({
    bool ongoing = false,
    bool autoCancel = true,
    bool vibrate = true,
    String customSoundPath = '',
  }) async {
    try {
      // Define vibration pattern - use a simpler pattern to avoid crashes
      final vibrationPattern = vibrate ? Int64List.fromList([0, 250, 250, 250]) : null;
    
      // Simplified sound handling to prevent crashes
      AndroidNotificationSound? notificationSound;
      if (_soundEnabled && customSoundPath.isNotEmpty && customSoundPath != 'default') {
        try {
          final processedSoundPath = await _getSoundFilePath(customSoundPath);
          if (processedSoundPath != 'default_sound') {
            notificationSound = UriAndroidNotificationSound(processedSoundPath);
          }
        } catch (e) {
          debugPrint('⚠️ Error processing custom sound, using default: $e');
          notificationSound = null; // Fall back to default system sound
        }
      }
    
      // Create notification details with app icon
      return AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Critical reminders that must be delivered',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification', // Small icon for status bar
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
        sound: notificationSound,
        playSound: _soundEnabled,
        enableVibration: vibrate && _vibrationEnabled,
        vibrationPattern: vibrationPattern,
        ongoing: ongoing,
        autoCancel: autoCancel,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        // Remove potentially problematic audio attributes
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        enableLights: true,
        ledColor: const Color(0xFFFF69B4),
        ledOnMs: 1000,
        ledOffMs: 500,
        // Add ticker for better visibility
        ticker: 'New reminder from Lilas Kokoro',
      );
    } catch (e) {
      debugPrint('❌ Error creating Android notification details: $e');
      // Return a minimal safe configuration if there's an error
      return const AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Critical reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification', // Small icon for status bar
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        showWhen: true,
        ticker: 'Lilas Kokoro reminder',
      );
    }
  }

  // Add this method to process sound files
  Future<String?> _processSoundFile(String soundPath) async {
    try {
      // Check if the file exists
      final file = File(soundPath);
      if (await file.exists()) {
        // Make sure the file is in the app's directory for notification access
        final appDir = await getApplicationDocumentsDirectory();
        final soundsDir = Directory('${appDir.path}/notification_sounds');
        if (!await soundsDir.exists()) {
          await soundsDir.create(recursive: true);
        }
        
        final fileName = path.basename(soundPath);
        final destinationPath = '${soundsDir.path}/$fileName';
        
        // Copy the file if it's not already in the app's directory
        if (soundPath != destinationPath) {
          await file.copy(destinationPath);
          debugPrint('✅ Copied sound file to app directory: $destinationPath');
          return destinationPath;
        }
        
        return soundPath;
      } else {
        debugPrint('⚠️ Sound file does not exist: $soundPath');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error processing sound file: $e');
      return null;
    }
  }

  // Get iOS notification details
  Future<DarwinNotificationDetails> _getIOSNotificationDetails({
    String? customSoundPath,
  }) async {
    // Handle custom sound for iOS
    String? soundName;
    if (_soundEnabled) {
      if (customSoundPath != null && customSoundPath.isNotEmpty && customSoundPath != 'default') {
        // For iOS, we need to extract just the filename
        final fileName = path.basename(customSoundPath);
        soundName = fileName;
      } else {
        soundName = 'notification_sound.aiff';
      }
    }

    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _soundEnabled,
      sound: soundName,
      categoryIdentifier: 'reminder',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
  }

  // Get sound file path
  Future<String> _getSoundFilePath(String soundPath) async {
    if (soundPath.isEmpty) {
      return 'default_sound';
    }
  
    try {
      // If it's an asset path, return it directly
      if (soundPath.startsWith('assets/')) {
        return soundPath;
      }
      
      // Check if it's a file path
      final file = File(soundPath);
      if (await file.exists()) {
        return soundPath; // Return the valid file path directly
        }
        
      // If we get here, the sound path doesn't exist
      debugPrint('⚠️ Sound file not found at path: $soundPath');
      return 'default_sound';
    } catch (e) {
      debugPrint('❌ Error getting sound file path: $e');
      return 'default_sound';
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
        return areEnabled ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking notification permissions: $e');
      return false;
    }
  }
  
  // Add this method to test notifications directly
  Future<void> testNotification() async {
    if (kIsWeb) return;
    
    debugPrint('🧪 Testing immediate notification...');
    
    try {
      await showNotification(
        title: '🧪 Test Notification',
        body: 'This is a test notification to verify the system is working correctly.',
        id: 99999,
        payload: 'test:notification',
      );
      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  // Add this method to test scheduled notifications
  Future<void> testScheduledNotification() async {
    if (kIsWeb) return;
    
    final now = DateTime.now().add(const Duration(seconds: 10));
    debugPrint('🧪 Testing scheduled notification for ${now.toString()}...');
    
    try {
      await scheduleNotification(
        title: '⏰ Test Scheduled Notification',
        body: 'This scheduled test notification should appear in 10 seconds.',
        id: 99998,
        scheduledTime: now,
        payload: 'test:scheduled',
      );
      debugPrint('✅ Test scheduled notification set for ${now.toString()}');
    } catch (e) {
      debugPrint('❌ Error scheduling test notification: $e');
    }
  }

  // Schedule a notification for a reminder - Enhanced crash prevention
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_notificationsEnabled || reminder.isCompleted) {
      debugPrint('⚠️ Skipping notification for ${reminder.title}: notificationsEnabled=$_notificationsEnabled, isCompleted=${reminder.isCompleted}');
      return;
    }
    
    // Enhanced notification scheduling with comprehensive error handling
    try {
      debugPrint('🔔 Scheduling notification for: ${reminder.title}');
      
      // Validate reminder data
      if (reminder.id.isEmpty || reminder.title.isEmpty) {
        debugPrint('⚠️ Invalid reminder data - skipping notification');
        return;
      }
      
      // Generate simple notification ID
      final int notificationId = reminder.id.hashCode.abs() % 100000;
      
      // Calculate schedule time with validation
      DateTime scheduleTime;
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        scheduleTime = _getNextReminderOccurrence(reminder) ?? reminder.dateTime;
      } else {
        scheduleTime = reminder.dateTime;
      }
      
      // Skip if time is in the past
      if (scheduleTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Schedule time is in the past, skipping: $scheduleTime');
        return;
      }
      
      // Create safe notification title and body
      final String title = '${reminder.emoji} ${reminder.title}'.trim();
      final String body = reminder.description.isNotEmpty 
          ? reminder.description.trim()
          : 'Reminder scheduled for ${DateFormat('h:mm a').format(scheduleTime)}';
      
      // Convert to timezone safely
      final tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);
      
      // Schedule with simplified configuration to prevent crashes
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduleTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Important reminders and notifications',
            importance: Importance.max,
            priority: Priority.max,
            autoCancel: false,
            icon: 'ic_notification', // Small icon for status bar
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
            showWhen: true,
            enableVibration: _vibrationEnabled,
            playSound: _soundEnabled,
            ongoing: false,
            ticker: 'Reminder from Lilas Kokoro',
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            // No action buttons - just tap to open
            // actions: [], // Removed action buttons as they weren't working reliably
          ),
          iOS: DarwinNotificationDetails(
            categoryIdentifier: 'reminder_category',
            presentAlert: true,
            presentBadge: true,
            presentSound: _soundEnabled,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:${reminder.id}',
      );
      
      debugPrint('✅ Notification scheduled successfully for ${reminder.title} at $scheduleTime');
      debugPrint('🆔 Notification ID: $notificationId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Critical error scheduling notification for ${reminder.title}: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Try to show a simple notification as fallback
      try {
        await showNotification(
          title: '⚠️ Reminder Scheduling Error',
          body: 'Could not schedule reminder: ${reminder.title}',
          id: 99997,
          payload: 'error:scheduling',
        );
      } catch (fallbackError) {
        debugPrint('❌ Fallback notification also failed: $fallbackError');
      }
      
      // Don't rethrow - allow app to continue
    }
  }
  
  // Helper method to get the next occurrence of a repeating reminder
  DateTime? _getNextReminderOccurrence(Reminder reminder) {
    if (!reminder.isRepeating || reminder.repeatDays.isEmpty) {
      return null;
    }
    
    final now = DateTime.now();
    final reminderTime = reminder.dateTime;
    
    // Convert repeat day names to weekday numbers
    final repeatWeekdays = reminder.repeatDays.map((day) => _getDayNumber(day)).toList();
    
    // Start checking from today
    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    
    // If today's time hasn't passed and today is in the repeat days, use today
    if (repeatWeekdays.contains(now.weekday) && candidate.isAfter(now)) {
      return candidate;
    }
    
    // Otherwise, find the next occurrence within the next 7 days
    for (int i = 1; i <= 7; i++) {
      candidate = candidate.add(Duration(days: 1));
      if (repeatWeekdays.contains(candidate.weekday)) {
        return candidate;
      }
    }
    
    return null; // Should not happen if repeatDays is not empty
  }
  
  // Helper method to get day name from weekday number
  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1]; // weekday is 1-7, array is 0-6
  }
  
  // Helper method to get day number from day name
  int _getDayNumber(String day) {
    const dayAbbreviations = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    // First check for abbreviations (used by reminder editor)
    int index = dayAbbreviations.indexOf(day);
    if (index != -1) {
      return index + 1; // Convert to weekday (1-7)
    }
    
    // Then check for full names
    index = dayNames.indexOf(day);
    if (index != -1) {
      return index + 1; // Convert to weekday (1-7)
    }
    
    // Handle partial matches
    if (day.length >= 3) {
      for (int i = 0; i < dayNames.length; i++) {
        if (dayNames[i].toLowerCase().startsWith(day.toLowerCase()) || 
            dayAbbreviations[i].toLowerCase().startsWith(day.toLowerCase())) {
          return i + 1;
        }
      }
    }
    
    debugPrint('⚠️ Could not parse day: $day');
    return 1; // Default to Monday if parsing fails
  }
  
  // Add this method to test notification sounds
  Future<void> testSound(String soundPath) async {
    try {
      final audioService = AudioService.instance;
      final dataService = DataService();
      final sounds = await dataService.getSounds();
      
      // Try to find the sound by path
      final sound = sounds.firstWhere(
        (s) => s.storageUrl == soundPath,
        orElse: () => sounds.firstWhere(
          (s) => s.isDefault && s.type == SoundType.notification,
          orElse: () => Sound(
            name: 'Default Sound',
            storageUrl: 'assets/sounds/default_notification.mp3',
            userId: 'system',
            isAsset: true,
            isDefault: true,
            type: SoundType.notification,
          ),
        ),
      );
      
      // Play the sound
      await audioService.playSound(sound);
      debugPrint('✅ Testing notification sound: ${sound.name}');
    } catch (e) {
      debugPrint('❌ Error testing notification sound: $e');
    }
  }
  
  // Add this method to stop sounds
  Future<void> stopSound() async {
    try {
      final audioService = AudioService.instance;
      await audioService.stopSound();
      debugPrint('✅ Stopped sound');
    } catch (e) {
      debugPrint('❌ Error stopping sound: $e');
    }
  }

  // Test notification with action buttons
  Future<void> sendTestNotificationWithActions() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🧪 Sending test notification with action buttons...');
      
      await _flutterLocalNotificationsPlugin.show(
        88888,
        '🧪 Test Notification',
        'Tap to test navigation to reminders tab!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notifications with action buttons',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
            // No action buttons - simplified for reliability
            // actions: [],
          ),
        ),
        payload: 'reminder:test-id-12345',
      );
      
      debugPrint('✅ Test notification sent with actions');
      
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }
  
  // Reschedule all active reminders
  Future<void> rescheduleAllReminders() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🔄 Rescheduling all reminders...');
      
      // Cancel all existing notifications first
      await cancelAllNotifications();
      
      // Get all reminders from data service
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      
      int scheduledCount = 0;
      
      // Schedule notifications for active reminders
      for (final reminder in reminders) {
        if (!reminder.isCompleted) {
          await scheduleReminderNotification(reminder);
          scheduledCount++;
        }
      }
      
      debugPrint('✅ Rescheduled $scheduledCount reminders successfully');
      
    } catch (e) {
      debugPrint('❌ Error rescheduling reminders: $e');
    }
  }

  // Comprehensive notification diagnostic and guidance
  Future<Map<String, dynamic>> runNotificationDiagnostic() async {
    if (kIsWeb) {
      return {
        'success': false,
        'message': 'Notifications are not supported on web platforms',
        'details': []
      };
    }
    
    debugPrint('🔍 === COMPREHENSIVE NOTIFICATION DIAGNOSTIC START ===');
    
    final List<String> issues = [];
    final List<String> suggestions = [];
    bool canSendNotifications = true;
    
    try {
      // Check 1: Plugin initialization
      debugPrint('1️⃣ Checking plugin initialization...');
      
      // Check 2: Android-specific checks
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Check notifications enabled
        final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('2️⃣ System notifications enabled: $areEnabled');
        
        if (areEnabled == false) {
          issues.add('Notifications are disabled in system settings');
          suggestions.add('Go to Settings > Apps > Lilas Kokoro > Notifications and enable them');
          canSendNotifications = false;
        }
        
        // Check exact alarm permission (Android 12+)
        try {
          final bool? canScheduleExact = await androidPlugin.canScheduleExactNotifications();
          debugPrint('3️⃣ Can schedule exact alarms: $canScheduleExact');
          
          if (canScheduleExact == false) {
            issues.add('Exact alarm scheduling is disabled');
            suggestions.add('Go to Settings > Apps > Special app access > Alarms & reminders > Lilas Kokoro and enable it');
          }
        } catch (e) {
          debugPrint('⚠️ Exact alarm check not available: $e');
        }
      }
      
      // Check 3: App-level notification settings
      debugPrint('4️⃣ App notification settings enabled: $_notificationsEnabled');
      if (!_notificationsEnabled) {
        issues.add('Notifications are disabled in app settings');
        suggestions.add('Enable notifications in the app permissions screen');
        canSendNotifications = false;
      }
      
      // Check 4: Try sending a test notification
      if (canSendNotifications) {
        debugPrint('5️⃣ Attempting to send test notification...');
        
        await _flutterLocalNotificationsPlugin.show(
          99999,
          '✅ Notification Test',
          'If you can see this, notifications are working correctly!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_channel',
              'Test Notifications',
              channelDescription: 'Test notifications for debugging',
              importance: Importance.max,
              priority: Priority.max,
              icon: 'ic_notification', // Small icon for status bar
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
              showWhen: true,
              enableVibration: true,
              playSound: true,
              autoCancel: true,
              ongoing: false,
              ticker: 'Test notification from Lilas Kokoro',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
        );
        
        debugPrint('✅ Test notification sent successfully');
        
        // Schedule a follow-up notification
        final testTime = DateTime.now().add(const Duration(seconds: 5));
        final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          99998,
          '⏰ Scheduled Test',
          'This proves scheduled notifications work too!',
          tzTestTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'test_channel',
              'Test Notifications',
              channelDescription: 'Test scheduled notifications',
              importance: Importance.max,
              priority: Priority.max,
              icon: 'ic_notification', // Small icon for status bar
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
              showWhen: true,
              enableVibration: true,
              playSound: true,
              autoCancel: true,
              ongoing: false,
              ticker: 'Scheduled test from Lilas Kokoro',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        debugPrint('✅ Scheduled test notification set for: $testTime');
      }
      
      debugPrint('🔍 === NOTIFICATION DIAGNOSTIC COMPLETE ===');
      
      final String resultMessage = issues.isEmpty 
          ? 'Notifications are working correctly! You should see test notifications now.'
          : 'Found ${issues.length} issue(s) that may prevent notifications from working.';
      
      return {
        'success': issues.isEmpty,
        'message': resultMessage,
        'issues': issues,
        'suggestions': suggestions,
        'details': [
          'System notifications enabled: ${androidPlugin != null ? await androidPlugin.areNotificationsEnabled() : 'Unknown'}',
          'App notifications enabled: $_notificationsEnabled',
          'Test notifications sent: ${canSendNotifications ? 'Yes' : 'No'}',
        ]
      };
      
    } catch (e) {
      debugPrint('❌ Notification diagnostic failed: $e');
      return {
        'success': false,
        'message': 'Notification diagnostic failed: $e',
        'issues': ['Diagnostic error: $e'],
        'suggestions': ['Please try restarting the app and checking system notification settings'],
        'details': []
      };
    }
  }

  // Add a simple test notification method for immediate testing
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🧪 Sending immediate test notification...');
      
      // Test 1: Using the custom icon
      await _flutterLocalNotificationsPlugin.show(
        12345,
        '🧪 Test 1: Custom Icon',
        'This notification uses your app\'s icon.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Immediate test notifications',
            importance: Importance.max,
            priority: Priority.max,
            icon: 'ic_notification', // Small icon for status bar
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
            ticker: 'Immediate test notification',
          ),
        ),
      );

      // Test 2: Using a standard system icon as a fallback
      await _flutterLocalNotificationsPlugin.show(
        12346,
        '🧪 Test 2: System Icon',
        'This notification uses a standard system icon.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Immediate test notifications with system icon',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@android:drawable/ic_dialog_info', // A standard Android resource
            ticker: 'Immediate system icon test',
          ),
        ),
      );
      
      debugPrint('✅ Immediate test notifications sent');
      
      // Also send a scheduled one for a few seconds later
      final scheduledTime = DateTime.now().add(const Duration(seconds: 10));
      await scheduleNotification(
        title: '⏰ Scheduled Test',
        body: 'This scheduled notification should appear in 10 seconds!',
        id: 12347,
        scheduledTime: scheduledTime,
        payload: 'test:scheduled',
      );
      
      debugPrint('✅ Scheduled test notification for 10 seconds from now');
      
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      rethrow;
    }
  }

  // Add a method to check notification settings in detail
  Future<Map<String, dynamic>> getDetailedNotificationStatus() async {
    if (kIsWeb) {
      return {'supported': false, 'reason': 'Web platform not supported'};
    }
    
    final Map<String, dynamic> status = {};
    
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        // Check basic notification permission
        final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
        status['notifications_enabled'] = areEnabled;
        
        // Check exact alarm permission
        try {
          final bool? canScheduleExact = await androidPlugin.canScheduleExactNotifications();
          status['can_schedule_exact'] = canScheduleExact;
        } catch (e) {
          status['can_schedule_exact'] = 'error: $e';
        }
        
        // Check app settings
        status['app_notifications_enabled'] = _notificationsEnabled;
        status['app_sound_enabled'] = _soundEnabled;
        status['app_vibration_enabled'] = _vibrationEnabled;
        
        // Try to get active notifications
        try {
          final List<ActiveNotification> activeNotifications = 
              await androidPlugin.getActiveNotifications();
          status['active_notifications_count'] = activeNotifications.length;
          status['active_notification_ids'] = activeNotifications.map((n) => n.id).toList();
        } catch (e) {
          status['active_notifications_error'] = e.toString();
        }
        
        // Try to get pending notifications
        try {
          final List<PendingNotificationRequest> pendingNotifications = 
              await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
          status['pending_notifications_count'] = pendingNotifications.length;
          status['pending_notification_ids'] = pendingNotifications.map((n) => n.id).toList();
        } catch (e) {
          status['pending_notifications_error'] = e.toString();
        }
      }
      
      return status;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Static method to mark a reminder as complete (for background processing) - Enhanced crash prevention
  static Future<void> _markReminderCompleteStatic(String reminderId) async {
    try {
      debugPrint('🔔 Static: Marking reminder complete: $reminderId');
      
      // Validate input
      if (reminderId.isEmpty) {
        debugPrint('⚠️ Static: Empty reminder ID provided');
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      
      if (reminders.isEmpty) {
        debugPrint('⚠️ Static: No reminders found');
        return;
      }
      
      final reminderIndex = reminders.indexWhere((r) => r.id == reminderId);
      
      if (reminderIndex < 0) {
        debugPrint('⚠️ Static: Reminder not found: $reminderId');
        return;
      }
      
        final reminder = reminders[reminderIndex];
        final updatedReminder = reminder.copyWith(isCompleted: true);
      
      // Update reminder in data service (this will notify UI listeners)
        await dataService.updateReminder(updatedReminder);
      
      // Cancel the original notification safely
      try {
        final notificationId = reminderId.hashCode.abs() % 100000;
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        debugPrint('✅ Static: Cancelled notification: $notificationId');
      } catch (e) {
        debugPrint('⚠️ Static: Error cancelling notification: $e');
        // Continue - not critical
      }
      
      // Show completion confirmation safely
      try {
        final notificationId = reminderId.hashCode.abs() % 100000;
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
        await flutterLocalNotificationsPlugin.show(
          99990 + notificationId,
          '✅ Task Completed!',
          '${reminder.title} has been marked as complete',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'completion_channel',
              'Task Completions',
              channelDescription: 'Confirmations when tasks are completed',
              importance: Importance.low,
              priority: Priority.low,
              icon: 'ic_notification',
              autoCancel: true,
              ongoing: false,
              showWhen: true,
              enableVibration: false,
              playSound: false,
              ticker: 'Task completed',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.status,
            ),
          ),
          payload: 'feedback:completed',
        );
        
        debugPrint('✅ Static: Marked reminder complete: $reminderId');
    } catch (e) {
        debugPrint('⚠️ Static: Error showing completion notification: $e');
        // Continue - main task is done
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Static: Critical error marking reminder complete: $e');
      debugPrint('❌ Static: Stack trace: $stackTrace');
      // Don't rethrow - prevent app crashes
    }
  }
  
  // Static method to snooze a reminder (for background processing) - Enhanced crash prevention
  static Future<void> _snoozeReminderStatic(String reminderId) async {
    try {
      debugPrint('🔔 Static: Snoozing reminder: $reminderId');
      
      // Validate input
      if (reminderId.isEmpty) {
        debugPrint('⚠️ Static: Empty reminder ID provided');
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      
      if (reminders.isEmpty) {
        debugPrint('⚠️ Static: No reminders found');
        return;
      }
      
      final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;
      
      if (reminder == null) {
        debugPrint('⚠️ Static: Reminder not found: $reminderId');
        return;
      }
      
        final notificationId = reminderId.hashCode.abs() % 100000;
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
      // Cancel the current notification safely
      try {
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        debugPrint('✅ Static: Cancelled original notification: $notificationId');
      } catch (e) {
        debugPrint('⚠️ Static: Error cancelling notification: $e');
        // Continue - not critical
      }
        
      // Calculate snooze time (5 minutes from now)
        final now = DateTime.now();
      final snoozeTime = now.add(const Duration(minutes: 5));
        
      // Schedule the snoozed notification safely
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '⏰ ${reminder.title} (Snoozed)',
          'Snoozed for 5 minutes • Will remind again at ${DateFormat('HH:mm').format(snoozeTime)}',
          tz.TZDateTime.from(snoozeTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Reminders',
              channelDescription: 'Snoozed reminders',
              importance: Importance.max,
              priority: Priority.max,
              icon: 'ic_notification', // Small icon for status bar
              largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), // App icon for notification content
              showWhen: true,
              enableVibration: true,
              playSound: true,
              autoCancel: false,
              ongoing: false,
              ticker: 'Snoozed reminder from Lilas Kokoro',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.reminder,
              // No action buttons - simplified for reliability
              // actions: [],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:${reminder.id}',
        );
        
        debugPrint('✅ Static: Scheduled snoozed notification for: ${snoozeTime.toString()}');
      } catch (e) {
        debugPrint('❌ Static: Error scheduling snoozed notification: $e');
        // Continue to show feedback
      }
      
      // Show snooze feedback safely
      try {
        await flutterLocalNotificationsPlugin.show(
          99980 + notificationId,
          '⏰ Reminder Snoozed',
          'Will remind you again at ${DateFormat('HH:mm').format(snoozeTime)}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'completion_channel',
              'Task Completions',
              channelDescription: 'Confirmations when reminders are snoozed',
              importance: Importance.low,
              priority: Priority.low,
              icon: 'ic_notification',
              autoCancel: true,
              ongoing: false,
              showWhen: true,
              enableVibration: false,
              playSound: false,
              ticker: 'Reminder snoozed',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.status,
            ),
          ),
          payload: 'feedback:snoozed',
        );
        
        debugPrint('✅ Static: Reminder snoozed for 5 minutes: $reminderId');
      } catch (e) {
        debugPrint('⚠️ Static: Error showing snooze feedback: $e');
        // Main task is done
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Static: Critical error snoozing reminder: $e');
      debugPrint('❌ Static: Stack trace: $stackTrace');
      // Don't rethrow - prevent app crashes
    }
  }

  // Helper method to show error notifications
  Future<void> _showErrorNotification(String message) async {
    try {
      await showNotification(
        title: '⚠️ Notification Error',
        body: message,
        id: 99999,
        payload: 'error:notification',
      );
    } catch (e) {
      debugPrint('❌ Failed to show error notification: $e');
    }
  }

  /// Enhanced notification response handler for new notification system
  static Future<void> _onNotificationResponseNew(NotificationResponse response) async {
    try {
      debugPrint('📱 New notification response: ${response.actionId}, payload: ${response.payload}');
      
      if (response.payload == null || response.payload!.isEmpty) {
        debugPrint('⚠️ Empty payload received');
        return;
      }

      // Handle simple payloads (legacy format)
      if (response.payload!.startsWith('reminder:')) {
        final parts = response.payload!.split(':');
        if (parts.length >= 2) {
          final reminderId = parts[1];
          await _handleReminderAction(response.actionId, reminderId);
        }
        return;
      }

      // Handle JSON payloads (new format)
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        final String type = data['type'] ?? '';
        
        switch (type) {
          case 'reminder':
            final reminderId = data['reminder_id'] ?? '';
            await _handleReminderAction(response.actionId, reminderId);
            break;
            
          case 'test':
          case 'error':
          case 'feedback':
            // No action needed for these types
            break;
            
          default:
            debugPrint('⚠️ Unknown notification type: $type');
            break;
        }
      } catch (e) {
        debugPrint('❌ Failed to parse JSON payload: $e');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error in notification response handler: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Handle reminder actions (only tap to navigate now)
  static Future<void> _handleReminderAction(String? actionId, String reminderId) async {
    try {
      if (reminderId.isEmpty) {
        debugPrint('⚠️ Empty reminder ID');
        return;
      }

      debugPrint('🔔 Handling reminder tap for ID: $reminderId');

      // Cancel the notification first
      final notificationId = reminderId.hashCode.abs() % 100000;
      await FlutterLocalNotificationsPlugin().cancel(notificationId);

      // Handle test notifications
      if (reminderId.startsWith('test-id')) {
        debugPrint('🧪 Test notification tapped - navigating to reminders');
        await _navigateToReminders();
        return;
      }

      // All taps navigate to reminders tab
      await _navigateToReminders();
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error handling reminder action: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Navigate to reminders tab
  static Future<void> _navigateToReminders() async {
    try {
      final navigatorKey = NavigationStateService.navigatorKey;
      if (navigatorKey.currentContext == null) {
        debugPrint('⚠️ Navigator context is null, cannot navigate');
        return;
      }

      debugPrint('🧭 Navigating to reminders tab (index 1)');

      // Use the correct navigation method that matches the app's routing system
      await Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
        '/', // Routes.home
        (route) => false, // Remove all previous routes
        arguments: {'initialTab': 1}, // Pass initialTab as arguments
      );

      debugPrint('✅ Navigation to reminders completed');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Navigation error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Mark reminder as complete (new implementation)
  static Future<void> _markReminderCompleteNew(String reminderId) async {
    try {
      debugPrint('✅ Marking reminder complete: $reminderId');
      
      // Handle test notifications
      if (reminderId.startsWith('test-id')) {
        debugPrint('🧪 Test notification - Complete button works!');
        // Complete button works
        
        // Cancel the test notification
        await FlutterLocalNotificationsPlugin().cancel(88888);
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;
      
      if (reminder == null) {
        debugPrint('⚠️ Reminder not found: $reminderId');
        return;
      }

      // Update reminder as completed
      final updatedReminder = reminder.copyWith(isCompleted: true);
      await dataService.updateReminder(updatedReminder);
      debugPrint('📝 Reminder marked complete in DataService');

      // Cancel the notification
      final notificationId = reminderId.hashCode.abs() % 100000;
      await FlutterLocalNotificationsPlugin().cancel(notificationId);
      debugPrint('🔕 Notification cancelled');

      // Task completed successfully
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error completing reminder: $e');
      debugPrint('Stack trace: $stackTrace');
              // Failed to complete task
    }
  }

  /// Snooze reminder for 5 minutes (new implementation)
  static Future<void> _snoozeReminderNew(String reminderId) async {
    try {
      debugPrint('😴 Snoozing reminder: $reminderId');
      
      // Handle test notifications
      if (reminderId.startsWith('test-id')) {
        debugPrint('🧪 Test notification - Snooze button works!');
        
        // Cancel the test notification
        await FlutterLocalNotificationsPlugin().cancel(88888);
        
        // Show snooze feedback with actual time
        final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
        final formattedTime = '${snoozeTime.hour.toString().padLeft(2, '0')}:${snoozeTime.minute.toString().padLeft(2, '0')}';
        // Snooze button works
        return;
      }
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminder = reminders.where((r) => r.id == reminderId).firstOrNull;
      
      if (reminder == null) {
        debugPrint('⚠️ Reminder not found: $reminderId');
        return;
      }

      final notificationId = reminderId.hashCode.abs() % 100000;
      
      // Cancel current notification
      await FlutterLocalNotificationsPlugin().cancel(notificationId);
      debugPrint('🔕 Original notification cancelled');

      // Calculate snooze time (5 minutes from now)
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      final formattedTime = '${snoozeTime.hour.toString().padLeft(2, '0')}:${snoozeTime.minute.toString().padLeft(2, '0')}';
      
      // Schedule new notification with corrected parameters
      await FlutterLocalNotificationsPlugin().zonedSchedule(
        notificationId,
        '😴 Snoozed: ${reminder.title}',
        'Will remind again at $formattedTime',
        tz.TZDateTime.from(snoozeTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminder Notifications',
            channelDescription: 'Snoozed reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            autoCancel: false,
            actions: [
              AndroidNotificationAction(
                'mark_complete',
                '✅ Complete',
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'snooze_reminder',
                '😴 Snooze +5min',
                showsUserInterface: false,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:$reminderId',
      );
      
      debugPrint('⏰ Snoozed notification scheduled for: $snoozeTime');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error snoozing reminder: $e');
      debugPrint('Stack trace: $stackTrace');
              // Failed to snooze reminder
    }
  }

  /// Show simple feedback notification
  static Future<void> _showSimpleFeedback(String message) async {
    try {
      await FlutterLocalNotificationsPlugin().show(
        999999,
        'Lilas Kokoro',
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'feedback_channel',
            'Feedback Notifications',
            channelDescription: 'User feedback notifications',
            importance: Importance.low,
            priority: Priority.low,
            autoCancel: true,
            timeoutAfter: 3000,
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Failed to show feedback: $e');
    }
  }
}
