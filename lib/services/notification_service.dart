import 'package:flutter/material.dart';
import 'package:lilas_kokoro/models/reminder_model.dart';
import 'package:lilas_kokoro/services/data_service.dart';
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

// This needs to be a top-level function or a static method to be accessible from the background.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This function is called when the app is in the background or terminated.
  debugPrint('🔔 Background notification tapped: ${notificationResponse.payload}');
  debugPrint('🔔 Action ID: ${notificationResponse.actionId}');
  
  try {
    // Handle notification actions in background
    if (notificationResponse.payload != null && notificationResponse.payload!.isNotEmpty) {
      if (notificationResponse.actionId == 'mark_complete' && notificationResponse.payload!.startsWith('reminder:')) {
        final parts = notificationResponse.payload!.split(':');
        if (parts.length >= 2) {
          final reminderId = parts[1];
          NotificationService._markReminderCompleteStatic(reminderId);
        }
      } 
      else if (notificationResponse.actionId == 'snooze_reminder' && notificationResponse.payload!.startsWith('reminder:')) {
        final parts = notificationResponse.payload!.split(':');
        if (parts.length >= 2) {
          final reminderId = parts[1];
          NotificationService._snoozeReminderStatic(reminderId);
        }
      }
    }
  } catch (e) {
    debugPrint('❌ Error in background notification handler: $e');
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

  // Initialize notification service with crash prevention
  Future<void> initialize() async {
    if (kIsWeb) return;
    
    try {
      debugPrint('🔔 Initializing NotificationService...');
      
      // Initialize timezone with error handling
      try {
        tz_data.initializeTimeZones();
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('🌍 Timezone set to: $timeZoneName');
      } catch (e) {
        debugPrint('⚠️ Error setting timezone: $e - using default');
      }
      
      // Load preferences first
      await _loadPreferences();
      
      // Initialize notification plugin with custom app icon
      const AndroidInitializationSettings androidInitializationSettings =
          AndroidInitializationSettings('ic_notification');
      
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
      ).catchError((error) {
        debugPrint('❌ Error initializing notification plugin: $error');
        return false;
      });
      
      debugPrint('🔔 Notification plugin initialized: $initialized');
      
      // Create notification channels for Android with enhanced configuration
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          // Create high importance notification channel for reminders
          const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Important reminders and notifications',
            importance: Importance.max, // Changed to max for heads-up notifications
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
            ledColor: Color(0xFFFF69B4), // Pink LED color
          );
          
          // Create test notification channel
          const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
            'test_channel',
            'Test Notifications',
            description: 'Test notifications for debugging',
            importance: Importance.max,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
            ledColor: Color(0xFFFF69B4),
          );
          
          // Create completion feedback channel
          const AndroidNotificationChannel completionChannel = AndroidNotificationChannel(
            'completion_channel',
            'Task Completions',
            description: 'Confirmations when tasks are completed',
            importance: Importance.low,
            enableVibration: false,
            enableLights: false,
            playSound: false,
            showBadge: false,
          );
          
          // Create snooze feedback channel
          const AndroidNotificationChannel snoozeFeedbackChannel = AndroidNotificationChannel(
            'snooze_feedback_channel',
            'Snooze Confirmations',
            description: 'Confirmations when reminders are snoozed',
            importance: Importance.low,
            enableVibration: false,
            enableLights: false,
            playSound: false,
            showBadge: false,
          );
          
          await androidPlugin.createNotificationChannel(reminderChannel);
          await androidPlugin.createNotificationChannel(testChannel);
          await androidPlugin.createNotificationChannel(completionChannel);
          await androidPlugin.createNotificationChannel(snoozeFeedbackChannel);
          debugPrint('🔔 Android notification channels created');
          
          // Check if notifications are enabled
          final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('🔔 Notifications enabled: $areEnabled');
          
          if (areEnabled == false) {
            debugPrint('⚠️ Notifications are disabled in system settings');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error creating notification channel: $e');
      }
      
      // Request permissions with enhanced handling
      try {
        final bool permissionGranted = await requestPermissions();
        debugPrint('🔔 Notification permissions granted: $permissionGranted');
        
        if (!permissionGranted) {
          debugPrint('⚠️ Notification permissions not granted - notifications may not work');
          // Request battery optimization exemption
          await requestBatteryOptimizationExemption();
        }
      } catch (e) {
        debugPrint('⚠️ Error requesting permissions: $e');
      }
      
      debugPrint('✅ NotificationService initialized successfully');
      
      // Log detailed notification status for debugging
      _logNotificationStatus();
      
    } catch (e) {
      debugPrint('❌ Critical error in NotificationService initialization: $e');
      // Don't rethrow - allow app to continue without notifications
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
  
  // Handle notification response (including action buttons)
  void onNotificationResponse(NotificationResponse response) {
    try {
      debugPrint('🔔 Notification response received: ${response.payload}');
      
      // Handle notification tap
      if (response.payload != null && response.payload!.isNotEmpty) {
        debugPrint('📱 Processing notification payload: ${response.payload}');
        
        // Handle reminder actions with proper error handling
        if (response.actionId == 'mark_complete' && response.payload!.startsWith('reminder:')) {
          final parts = response.payload!.split(':');
          if (parts.length >= 2) {
            final reminderId = parts[1];
            _markReminderComplete(reminderId).catchError((error) {
              debugPrint('❌ Error marking reminder complete: $error');
            });
          }
        } 
        else if (response.actionId == 'snooze_reminder' && response.payload!.startsWith('reminder:')) {
          final parts = response.payload!.split(':');
          if (parts.length >= 2) {
            final reminderId = parts[1];
            _snoozeReminder(reminderId).catchError((error) {
              debugPrint('❌ Error snoozing reminder: $error');
            });
          }
        }
        else {
          // Handle regular notification tap (no action button)
          debugPrint('📱 Regular notification tap - no specific action needed');
        }
      } else {
        debugPrint('📱 Notification response with no payload');
      }
    } catch (e) {
      debugPrint('❌ Error handling notification response: $e');
      // Don't rethrow - we don't want to crash the app
    }
  }
  
  // Enhanced method to mark a reminder as complete with visual feedback
  Future<void> _markReminderComplete(String reminderId) async {
    // Call the static method to ensure consistency
    await _markReminderCompleteStatic(reminderId);
  }
  
  // Enhanced method to snooze a reminder with better scheduling
  Future<void> _snoozeReminder(String reminderId) async {
    // Call the static method to ensure consistency
    await _snoozeReminderStatic(reminderId);
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
    
      // Create notification details with safer configuration
      return AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Critical reminders that must be delivered',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_notification',
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

  // Schedule a notification for a reminder - simplified to prevent crashes
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_notificationsEnabled || reminder.isCompleted) {
      debugPrint('⚠️ Skipping notification for ${reminder.title}: notificationsEnabled=$_notificationsEnabled, isCompleted=${reminder.isCompleted}');
      return;
    }
    
    // Simple notification scheduling to prevent crashes
    try {
      debugPrint('🔔 Scheduling notification for: ${reminder.title}');
      
      // Generate simple notification ID
      final int notificationId = reminder.id.hashCode.abs() % 100000;
      
      // Calculate schedule time
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
      
      // Create simple notification title and body
      final String title = '${reminder.emoji} ${reminder.title}';
      final String body = reminder.description.isNotEmpty 
          ? reminder.description 
          : 'Reminder scheduled for ${DateFormat('h:mm a').format(scheduleTime)}';
      
      // Convert to timezone
      final tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);
      
      // Schedule with enhanced configuration for better visibility
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Important reminders and notifications',
            importance: Importance.max,
            priority: Priority.max,
            autoCancel: false,
            icon: 'ic_notification',
            showWhen: true,
            enableVibration: true,
            playSound: true,
            ongoing: false,
            fullScreenIntent: true, // Helps show heads-up notifications
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_complete',
                '✅ Complete',
                icon: DrawableResourceAndroidBitmap('ic_check_complete'),
                showsUserInterface: false,
              ),
              AndroidNotificationAction(
                'snooze_reminder',
                '⏰ Snooze +5min',
                icon: DrawableResourceAndroidBitmap('ic_snooze'),
                showsUserInterface: false,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:${reminder.id}',
      );
      
      debugPrint('✅ Notification scheduled successfully for ${reminder.title} at $scheduleTime');
      
    } catch (e) {
      debugPrint('❌ Error scheduling notification for ${reminder.title}: $e');
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
              icon: 'ic_notification',
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
              icon: 'ic_notification',
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
            icon: 'ic_notification', // Your custom icon
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

  // Static method to mark a reminder as complete (for background processing)
  static Future<void> _markReminderCompleteStatic(String reminderId) async {
    try {
      debugPrint('🔔 Static: Marking reminder complete: $reminderId');
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminderIndex = reminders.indexWhere((r) => r.id == reminderId);
      
      if (reminderIndex >= 0) {
        final reminder = reminders[reminderIndex];
        final updatedReminder = reminder.copyWith(isCompleted: true);
        await dataService.updateReminder(updatedReminder);
      
        // Cancel the original notification
        final notificationId = reminderId.hashCode.abs() % 100000;
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        
        // Show completion confirmation
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
              icon: 'ic_check_complete',
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
        );
        
        debugPrint('✅ Static: Marked reminder complete: $reminderId');
      }
    } catch (e) {
      debugPrint('❌ Static: Error marking reminder complete: $e');
    }
  }
  
  // Static method to snooze a reminder (for background processing)
  static Future<void> _snoozeReminderStatic(String reminderId) async {
    try {
      debugPrint('🔔 Static: Snoozing reminder: $reminderId');
      
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminder = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => null as Reminder,
      );
      
      if (reminder != null) {
        final notificationId = reminderId.hashCode.abs() % 100000;
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        
        // Cancel the current notification
        await flutterLocalNotificationsPlugin.cancel(notificationId);
        
        // Calculate snooze time
        final originalTime = reminder.dateTime;
        final now = DateTime.now();
        final baseTime = originalTime.isBefore(now) ? now : originalTime;
        final snoozeTime = baseTime.add(const Duration(minutes: 5));
        
        // Schedule the snoozed notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          '⏰ ${reminder.title} (Snoozed)',
          'Snoozed for 5 minutes • Will remind again at ${DateFormat('HH:mm').format(snoozeTime)}',
          tz.TZDateTime.from(snoozeTime, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Reminders',
              channelDescription: 'Snoozed reminders',
              importance: Importance.max,
              priority: Priority.max,
              icon: 'ic_notification',
              showWhen: true,
              enableVibration: true,
              playSound: true,
              autoCancel: false,
              ongoing: false,
              ticker: 'Snoozed reminder from Lilas Kokoro',
              visibility: NotificationVisibility.public,
              category: AndroidNotificationCategory.reminder,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction(
                  'mark_complete',
                  '✅ Complete',
                  icon: DrawableResourceAndroidBitmap('ic_check_complete'),
                  showsUserInterface: false,
                ),
                AndroidNotificationAction(
                  'snooze_reminder',
                  '⏰ Snooze +5min',
                  icon: DrawableResourceAndroidBitmap('ic_snooze'),
                  showsUserInterface: false,
                ),
              ],
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'reminder:${reminder.id}',
        );
        
        // Show snooze feedback
        await flutterLocalNotificationsPlugin.show(
          99980 + notificationId,
          '⏰ Reminder Snoozed',
          'Will remind you again at ${DateFormat('HH:mm').format(snoozeTime)}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'snooze_feedback_channel',
              'Snooze Confirmations',
              channelDescription: 'Confirmations when reminders are snoozed',
              importance: Importance.low,
              priority: Priority.low,
              icon: 'ic_snooze',
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
        );
        
        debugPrint('✅ Static: Reminder snoozed for 5 minutes: $reminderId');
      }
    } catch (e) {
      debugPrint('❌ Static: Error snoozing reminder: $e');
    }
  }
}
