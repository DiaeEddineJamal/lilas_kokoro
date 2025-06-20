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

  // Initialize notification service
  Future<void> initialize() async {
    if (kIsWeb) return;
    
    debugPrint('🔔 Initializing NotificationService...');
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    debugPrint('🌍 Timezone set to: $timeZoneName');
    
    // Initialize notification plugin
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        // Add reminder category
        DarwinNotificationCategory(
          'reminder',
          actions: [
            DarwinNotificationAction.plain(
              'mark_complete',
              '✅ Complete',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'snooze_reminder',
              '⏰ Remind Later',
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    
    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
    
    debugPrint('🔔 Notification plugin initialized: $initialized');
    
    // Load preferences
    await _loadPreferences();
    
    // Create notification channels for Android
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      // Create reminder channel with high importance
      final AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
        'reminder_channel',
        'Reminders',
        description: 'Notifications for reminders',
        importance: Importance.max, // Changed to max for better visibility
        // Use preferences to configure channel defaults
        enableVibration: _vibrationEnabled,
        enableLights: true,
        playSound: _soundEnabled,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(reminderChannel);
      debugPrint('🔔 Android notification channel created');
    }
    
    // Always request notification permissions during initialization
    final bool permissionGranted = await requestPermissions();
    debugPrint('🔔 Notification permissions granted: $permissionGranted');
    
    if (!permissionGranted) {
      debugPrint('⚠️ Notification permissions not granted - notifications may not work');
    }
    
    debugPrint('✅ NotificationService initialized successfully');
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
  
  // Handle notification response (including action buttons)
  void onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
      
      // Handle reminder actions
      if (response.actionId == 'mark_complete' && response.payload!.startsWith('reminder:')) {
        final reminderId = response.payload!.split(':')[1];
        _markReminderComplete(reminderId);
      } 
      else if (response.actionId == 'snooze_reminder' && response.payload!.startsWith('reminder:')) {
        final reminderId = response.payload!.split(':')[1];
        _snoozeReminder(reminderId);
      }
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
    // Define vibration pattern
    final vibrationPattern = Int64List.fromList([0, 500]);
  
    // Process sound path for Android
    String? processedSoundPath;
    if (customSoundPath.isNotEmpty && customSoundPath != 'default') {
      processedSoundPath = await _getSoundFilePath(customSoundPath);
      debugPrint('🔊 Processed sound path for notification: $processedSoundPath');
    }
  
    // Create a unique channel ID for the notification
    final channelId = 'reminder_channel';
    
    return AndroidNotificationDetails(
      channelId,
      'Reminders',
      channelDescription: 'Notifications for reminders',
      importance: Importance.max,
      priority: Priority.max,
      sound: processedSoundPath != null && processedSoundPath != 'default_sound'
          ? UriAndroidNotificationSound(processedSoundPath)
          : null,
      playSound: true,
      enableVibration: vibrate,
      vibrationPattern: vibrationPattern,
      ongoing: ongoing,
      autoCancel: autoCancel,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
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

  // Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_notificationsEnabled || reminder.isCompleted) {
      debugPrint('⚠️ Skipping notification for ${reminder.title}: notificationsEnabled=$_notificationsEnabled, isCompleted=${reminder.isCompleted}');
      return;
    }
    
    try {
      debugPrint('🔔 Starting to schedule notification for: ${reminder.title}');
      
      // Generate notification ID from reminder ID (ensure consistency)
      final int notificationId = reminder.id.hashCode.abs() % 100000;
      debugPrint('📱 Notification ID: $notificationId');
      
      // Get reminder time as TZDateTime for correct timezone handling
      final reminderTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      
      debugPrint('📅 Reminder time: ${reminder.dateTime}');
      debugPrint('📅 TZ Reminder time: $reminderTime');
      debugPrint('📅 Current time: $now');
      debugPrint('🔁 Is repeating: ${reminder.isRepeating}');
      debugPrint('📅 Repeat days: ${reminder.repeatDays}');
      
      DateTime? scheduleTime;
      
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        // For repeating reminders, find the next occurrence
        scheduleTime = _getNextReminderOccurrence(reminder);
        if (scheduleTime == null) {
          debugPrint('⚠️ No valid next occurrence found for repeating reminder: ${reminder.title}');
          return;
        }
        debugPrint('🔄 Next occurrence for repeating reminder: $scheduleTime');
      } else {
        // For one-time reminders, use the exact scheduled time
        if (reminderTime.isBefore(now)) {
          debugPrint('⚠️ Cannot schedule notification for past time: ${reminder.dateTime}');
          return;
        }
        scheduleTime = reminder.dateTime;
        debugPrint('📅 One-time reminder scheduled for: $scheduleTime');
      }
      
      // Convert to TZDateTime for scheduling
      final tzScheduleTime = tz.TZDateTime.from(scheduleTime, tz.local);
      debugPrint('🌍 TZ Schedule time: $tzScheduleTime');
      
      // Verify the schedule time is in the future
      if (tzScheduleTime.isBefore(now)) {
        debugPrint('⚠️ Calculated schedule time is in the past: $tzScheduleTime vs $now');
        return;
      }
      
      // Check if notifications are actually enabled on the device
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final bool? enabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('📱 Device notifications enabled: $enabled');
        if (enabled == false) {
          debugPrint('⚠️ Device notifications are disabled - notification may not appear');
        }
      }
      
      // Create personalized title and body for the notification
      final String title = '${reminder.emoji} ${reminder.title}';
      String body = '';
      
      // Add description if available
      if (reminder.description.isNotEmpty) {
        body = reminder.description;
      }
      
      // Add scheduled time information
      final timeFormat = DateFormat('h:mm a');
      final dateFormat = DateFormat('MMM d, yyyy');
      body += body.isNotEmpty ? '\n\n' : '';
      body += '⏰ Scheduled for ${timeFormat.format(scheduleTime)}';
      
      // Add date if it's not today
      final today = DateTime.now();
      final isToday = scheduleTime.year == today.year && 
                     scheduleTime.month == today.month && 
                     scheduleTime.day == today.day;
      
      if (!isToday) {
        body += ' on ${dateFormat.format(scheduleTime)}';
      }
      
      // If it's a repeating reminder, add info about the recurrence
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        body += '\n🔁 Repeats: ${reminder.repeatDays.join(", ")}';
      }
      
      // Add category if available
      if (reminder.category.isNotEmpty && reminder.category != 'General') {
        body += '\n📂 ${reminder.category}';
      }
      
      debugPrint('📝 Notification title: $title');
      debugPrint('📝 Notification body: $body');
      
      // Prepare Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Notifications for reminders',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
        color: const Color(0xFFFF85A2), // Will be updated by theme
        ledColor: const Color(0xFFFF85A2), // Will be updated by theme
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: _vibrationEnabled,
        playSound: _soundEnabled,
        category: AndroidNotificationCategory.reminder,
        fullScreenIntent: true,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(body),
        actions: [
          const AndroidNotificationAction(
            'mark_complete',
            '✅ Complete',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze_reminder',
            '⏰ Later',
            showsUserInterface: true,
          ),
        ],
      );
      
      // Configure iOS notification details
      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: _soundEnabled,
        categoryIdentifier: 'reminder',
        threadIdentifier: 'reminder_${reminder.id}',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      
      // Add a unique ID as payload for handling notification taps
      final String payload = 'reminder:${reminder.id}';
      
      debugPrint('🚀 Attempting to schedule notification...');
      
      // Schedule the notification with proper details
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzScheduleTime,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        // For repeating reminders, use weekly matching
        matchDateTimeComponents: reminder.isRepeating && reminder.repeatDays.isNotEmpty 
            ? DateTimeComponents.dayOfWeekAndTime 
            : null,
      );
      
      debugPrint('✅ Notification scheduled successfully for ${reminder.title} at ${DateFormat('yyyy-MM-dd – kk:mm').format(scheduleTime)}');
      
    } catch (e) {
      debugPrint('❌ Error scheduling notification for ${reminder.title}: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    // Handle both full names and abbreviations
    if (day.length >= 3) {
      for (int i = 0; i < days.length; i++) {
        if (days[i].startsWith(day) || day.startsWith(days[i].substring(0, 3))) {
          return i + 1;
        }
      }
    }
    return days.indexOf(day) + 1;
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

  // Comprehensive notification system diagnostic
  Future<void> runNotificationDiagnostic() async {
    if (kIsWeb) {
      debugPrint('🌐 Running on web - notifications not supported');
      return;
    }
    
    debugPrint('🔍 === NOTIFICATION DIAGNOSTIC START ===');
    
    try {
      // 1. Check if notifications are enabled in service
      debugPrint('1️⃣ Service notification settings:');
      debugPrint('   - Notifications enabled: $_notificationsEnabled');
      debugPrint('   - Sound enabled: $_soundEnabled');
      debugPrint('   - Vibration enabled: $_vibrationEnabled');
      
      // 2. Check Android permissions
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        debugPrint('2️⃣ Android notification status:');
        try {
          final bool? enabled = await androidPlugin.areNotificationsEnabled();
          debugPrint('   - Device notifications enabled: $enabled');
          
          final bool? permissionGranted = await androidPlugin.requestNotificationsPermission();
          debugPrint('   - Permission request result: $permissionGranted');
        } catch (e) {
          debugPrint('   - Error checking Android status: $e');
        }
      }
      
      // 3. Check iOS permissions
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      
      if (iosPlugin != null) {
        debugPrint('3️⃣ iOS notification status:');
        try {
          final bool? result = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          debugPrint('   - Permission request result: $result');
        } catch (e) {
          debugPrint('   - Error checking iOS status: $e');
        }
      }
      
      // 4. Test timezone setup
      debugPrint('4️⃣ Timezone information:');
      try {
        final String timeZoneName = await FlutterTimezone.getLocalTimezone();
        final tz.Location location = tz.getLocation(timeZoneName);
        final tz.TZDateTime now = tz.TZDateTime.now(location);
        debugPrint('   - Timezone: $timeZoneName');
        debugPrint('   - Current TZ time: $now');
      } catch (e) {
        debugPrint('   - Error with timezone: $e');
      }
      
      // 5. Test immediate notification
      debugPrint('5️⃣ Testing immediate notification...');
      try {
        await showNotification(
          title: '🔍 Diagnostic Test',
          body: 'If you see this, immediate notifications work!',
          id: 99997,
          payload: 'diagnostic:immediate',
        );
        debugPrint('   - Immediate notification sent successfully');
      } catch (e) {
        debugPrint('   - Error sending immediate notification: $e');
      }
      
      // 6. Test scheduled notification (10 seconds)
      debugPrint('6️⃣ Testing scheduled notification (10 seconds)...');
      try {
        final testTime = DateTime.now().add(const Duration(seconds: 10));
        await scheduleNotification(
          title: '⏰ Diagnostic Scheduled Test',
          body: 'If you see this, scheduled notifications work!',
          id: 99996,
          scheduledTime: testTime,
          payload: 'diagnostic:scheduled',
        );
        debugPrint('   - Scheduled notification set for: $testTime');
      } catch (e) {
        debugPrint('   - Error scheduling notification: $e');
      }
      
      debugPrint('🔍 === NOTIFICATION DIAGNOSTIC COMPLETE ===');
      debugPrint('📱 Check your notification panel for test notifications!');
      
    } catch (e) {
      debugPrint('❌ Diagnostic failed with error: $e');
    }
  }
}
