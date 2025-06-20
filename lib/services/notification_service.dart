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
      
      // Initialize notification plugin with minimal settings
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
      ).catchError((error) {
        debugPrint('❌ Error initializing notification plugin: $error');
        return false;
      });
      
      debugPrint('🔔 Notification plugin initialized: $initialized');
      
      // Create notification channels for Android with error handling
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
            _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidPlugin != null) {
          // Create simple notification channel
          const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
            'reminder_channel',
            'Reminders',
            description: 'Critical reminders',
            importance: Importance.high,
            enableVibration: true,
            enableLights: true,
            playSound: true,
            showBadge: true,
          );
          await androidPlugin.createNotificationChannel(reminderChannel);
          debugPrint('🔔 Android notification channel created');
        }
      } catch (e) {
        debugPrint('⚠️ Error creating notification channel: $e');
      }
      
      // Request permissions with error handling
      try {
        final bool permissionGranted = await requestPermissions();
        debugPrint('🔔 Notification permissions granted: $permissionGranted');
        
        if (!permissionGranted) {
          debugPrint('⚠️ Notification permissions not granted - notifications may not work');
        }
      } catch (e) {
        debugPrint('⚠️ Error requesting permissions: $e');
      }
      
      debugPrint('✅ NotificationService initialized successfully');
      
    } catch (e) {
      debugPrint('❌ Critical error in NotificationService initialization: $e');
      // Don't rethrow - allow app to continue without notifications
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
  
  // Add this method to mark a reminder as complete
  Future<void> _markReminderComplete(String reminderId) async {
    try {
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminderIndex = reminders.indexWhere((r) => r.id == reminderId);
      
      if (reminderIndex >= 0) {
        final reminder = reminders[reminderIndex];
        final updatedReminder = reminder.copyWith(isCompleted: true);
        await dataService.updateReminder(updatedReminder);
      
        // Cancel the notification
        final notificationId = reminderId.hashCode.abs() % 100000;
      await cancelNotification(notificationId);
      
        debugPrint('✅ Marked reminder complete: $reminderId');
      }
    } catch (e) {
      debugPrint('❌ Error marking reminder complete: $e');
    }
  }
  
  // Add this method to snooze a reminder
  Future<void> _snoozeReminder(String reminderId) async {
    try {
      final dataService = DataService();
      final reminders = await dataService.getReminders();
      final reminder = reminders.firstWhere(
        (r) => r.id == reminderId,
        orElse: () => null as Reminder,
      );
      
      if (reminder != null) {
        // Cancel the current notification
        final notificationId = reminderId.hashCode.abs() % 100000;
        await cancelNotification(notificationId);
        
        // Schedule a new notification for 5 minutes later
        final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
        
        // For snoozed reminders, we want to show them even if today isn't in the repeat days
        // So create a direct notification rather than using scheduleReminderNotification
        await scheduleNotification(
          title: '⏰ ${reminder.title} (Snoozed)',
          body: '⏰ Snoozed reminder!\nWill remind again at ${DateFormat('HH:mm').format(snoozeTime)}',
          id: notificationId,
          scheduledTime: snoozeTime,
          payload: 'reminder:${reminder.id}',
          isSnoozeReminder: true,
        );
        
        debugPrint('✅ Reminder snoozed for 5 minutes: $reminderId');
      }
    } catch (e) {
      debugPrint('❌ Error snoozing reminder: $e');
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
      // Only use matchDateTimeComponents for regular reminders, not for snoozed ones
      matchDateTimeComponents: isSnoozeReminder ? null : DateTimeComponents.dateAndTime,
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
        sound: notificationSound,
        playSound: _soundEnabled,
        enableVibration: vibrate && _vibrationEnabled,
        vibrationPattern: vibrationPattern,
        ongoing: ongoing,
        autoCancel: autoCancel,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        channelAction: AndroidNotificationChannelAction.createIfNotExists,
        audioAttributesUsage: AudioAttributesUsage.notification,
        // Remove potentially problematic properties that might cause crashes
        enableLights: true,
        ledColor: const Color(0xFFFF69B4),
        ledOnMs: 1000,
        ledOffMs: 500,
      );
    } catch (e) {
      debugPrint('❌ Error creating Android notification details: $e');
      // Return a minimal safe configuration if there's an error
      return const AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Critical reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
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
      
      // Schedule with minimal configuration to prevent crashes
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduleTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
            autoCancel: false,
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

  // Simple and safe notification test
  Future<void> runNotificationDiagnostic() async {
    if (kIsWeb) {
      debugPrint('🌐 Running on web - notifications not supported');
      return;
    }
    
    debugPrint('🔍 === SIMPLE NOTIFICATION TEST START ===');
    
    try {
      // Test 1: Simple immediate notification
      debugPrint('📱 Testing immediate notification...');
      await _flutterLocalNotificationsPlugin.show(
        12345,
        'Test Notification',
        'This is a test notification from Lilas Kokoro!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Test notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('✅ Immediate notification sent');
      
      // Test 2: Simple scheduled notification (5 seconds)
      debugPrint('⏰ Testing scheduled notification (5 seconds)...');
      final testTime = DateTime.now().add(const Duration(seconds: 5));
      final tzTestTime = tz.TZDateTime.from(testTime, tz.local);
      
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        12346,
        'Scheduled Test',
        'This scheduled notification shows background notifications work!',
        tzTestTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Test scheduled notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('✅ Scheduled notification set for: $testTime');
      
      debugPrint('🔍 === NOTIFICATION TEST COMPLETE ===');
      debugPrint('📱 You should see an immediate notification now and another in 5 seconds!');
      
    } catch (e) {
      debugPrint('❌ Notification test failed: $e');
      rethrow; // Let the UI handle the error
    }
  }
}
