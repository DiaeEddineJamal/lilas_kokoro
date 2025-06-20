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
    
    // Initialize timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    
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
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
    
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
        importance: Importance.high,
        // Use preferences to configure channel defaults
        enableVibration: _vibrationEnabled,
        enableLights: true,
        playSound: _soundEnabled,
      );
      await androidPlugin.createNotificationChannel(reminderChannel);
    }
    
    // Request notification permissions
    if (_notificationsEnabled) {
      await requestPermissions();
    }
    
    debugPrint('✅ NotificationService initialized successfully');
  }
  
  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidPlugin != null) {
      final bool granted = await androidPlugin.areNotificationsEnabled() ?? false;
      return granted;
    }
    
    // For iOS, request permission
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
            
    if (iosPlugin != null) {
      final bool? result = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
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
    final now = DateTime.now().add(const Duration(seconds: 5));
    
    await scheduleNotification(
      title: '⏰ Test Notification',
      body: '🌸 This is a test notification!',
      id: 9999,
      scheduledTime: now,
      ongoing: false,
      autoCancel: true,
      vibrate: true,
    );
    
    debugPrint('✅ Test notification scheduled for ${now.toString()}');
  }

  // Schedule a notification for a reminder
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!_notificationsEnabled || reminder.isCompleted) return;
    
    try {
      // Generate notification ID from reminder ID (ensure consistency)
      final int notificationId = reminder.id.hashCode.abs() % 100000;
      
      // Get reminder time as TZDateTime for correct timezone handling
      final reminderTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
      
      // If the scheduled time is in the past, don't schedule
      if (reminderTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('⚠️ Cannot schedule notification for past time: ${reminder.dateTime}');
        return;
      }
      
      // Check for repeating reminders
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        final now = DateTime.now();
        final currentDayName = _getDayName(now.weekday);
        final reminderDay = DateTime(reminderTime.year, reminderTime.month, reminderTime.day);
        final today = DateTime(now.year, now.month, now.day);
        
        // Skip notification if today is not in the repeat days (for both today and future dates)
        if (!reminder.repeatDays.contains(currentDayName)) {
          debugPrint('⚠️ Not scheduling notification for ${reminder.title} on ${currentDayName} as it is not in repeat days: ${reminder.repeatDays.join(", ")}');
          return;
        }
      }
      
      // Create personalized title and body for the notification
      final String title = '${reminder.emoji} ${reminder.title}';
      String body = reminder.description;
      
      // If it's a repeating reminder, add info about the recurrence
      if (reminder.isRepeating && reminder.repeatDays.isNotEmpty) {
        final String recurrencePattern = 'Repeats on: ${reminder.repeatDays.join(", ")}';
        body = '$body\n$recurrencePattern';
      }
      
      // Prepare Android-specific notification details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Notifications for reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        color: const Color(0xFFFF85A2), // Pink color
        ledColor: const Color(0xFFFF85A2),
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
      
      // Schedule the notification with proper details
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        reminderTime,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      
      debugPrint('✅ Scheduled notification for ${reminder.title} at ${DateFormat('yyyy-MM-dd – kk:mm').format(reminder.dateTime)}');
      
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
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
}
