import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Alarm {
  final String id;
  final String name;
  final int hour;
  final int minute;
  final bool isEnabled;
  final String userId;
  final String emoji;
  final List<String> repeatDays;
  final String soundPath;
  final bool isCustomSound;
  final String soundName;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final String customSoundPath;

  Alarm({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.userId,
    this.isEnabled = true,
    this.emoji = '⏰',
    this.repeatDays = const [],
    this.soundPath = '',
    this.isCustomSound = false,
    this.soundName = 'Default Sound',
    this.customSoundPath = '',
    DateTime? createdAt,
    this.lastTriggered,
  }) : createdAt = createdAt ?? DateTime.now();

  // Get a cute random emoji for the alarm
  static String _getRandomEmoji() {
    final List<String> emojis = [
      '⏰', '🌙', '✨', '🌸', '🎀', '🌈', '🍰', '🌷', '🦄', '🎵', 
      '🌟', '💫', '🌺', '🍓', '🧁', '🍭', '🌻', '🦋', '🐱', '🌞'
    ];
    return emojis[DateTime.now().millisecond % emojis.length];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'userId': userId,
      'emoji': emoji,
      'repeatDays': repeatDays,
      'soundPath': soundPath,
      'isCustomSound': isCustomSound,
      'soundName': soundName,
      'customSoundPath': customSoundPath,
      'createdAt': createdAt.toIso8601String(),
      'lastTriggered': lastTriggered?.toIso8601String(),
    };
  }

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] ?? const Uuid().v4(),
      name: map['name'] ?? 'Alarm',
      hour: map['hour'] ?? 8,
      minute: map['minute'] ?? 0,
      isEnabled: map['isEnabled'] ?? true,
      userId: map['userId'] ?? '',
      emoji: map['emoji'] ?? '⏰',
      repeatDays: List<String>.from(map['repeatDays'] ?? []),
      soundPath: map['soundPath'] ?? '',
      isCustomSound: map['isCustomSound'] ?? false,
      soundName: map['soundName'] ?? 'Default Sound',
      customSoundPath: map['customSoundPath'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      lastTriggered: map['lastTriggered'] != null 
          ? DateTime.parse(map['lastTriggered']) 
          : null,
    );
  }

  Alarm copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    bool? isEnabled,
    String? userId,
    String? emoji,
    List<String>? repeatDays,
    String? soundPath,
    bool? isCustomSound,
    String? soundName,
    String? customSoundPath,
    DateTime? createdAt,
    DateTime? lastTriggered,
  }) {
    return Alarm(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      isEnabled: isEnabled ?? this.isEnabled,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      repeatDays: repeatDays ?? this.repeatDays,
      soundPath: soundPath ?? this.soundPath,
      isCustomSound: isCustomSound ?? this.isCustomSound,
      soundName: soundName ?? this.soundName,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }
  
  // Helper methods for alarm functionality
  
  // Get formatted time as a string (e.g., "8:30 AM")
  String get formattedTime {
    final hourIn12Format = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour < 12 ? 'AM' : 'PM';
    final minuteString = minute < 10 ? '0$minute' : '$minute';
    return '$hourIn12Format:$minuteString $period';
  }
  
  // Get the next time this alarm should trigger
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    final todayAlarmTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // If no repeat days are set, this is a one-time alarm
    if (repeatDays.isEmpty) {
      // If the alarm time is in the past, schedule it for tomorrow
      if (todayAlarmTime.isBefore(now)) {
        return todayAlarmTime.add(const Duration(days: 1));
      }
      return todayAlarmTime;
    }
    
    // For repeating alarms, find the next occurrence
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentWeekday = weekdays[now.weekday - 1]; // weekday is 1-based, we need 0-based
    
    // If today is a repeat day and the alarm time hasn't passed yet
    if (repeatDays.contains(currentWeekday) && todayAlarmTime.isAfter(now)) {
      return todayAlarmTime;
    }
    
    // Find the next day in the repeat schedule
    int daysToAdd = 1;
    while (daysToAdd <= 7) {
      final nextDay = now.add(Duration(days: daysToAdd));
      final nextDayName = weekdays[nextDay.weekday - 1];
      
      if (repeatDays.contains(nextDayName)) {
        return DateTime(
          nextDay.year, 
          nextDay.month, 
          nextDay.day, 
          hour, 
          minute,
        );
      }
      
      daysToAdd++;
    }
    
    // Fallback to tomorrow if something went wrong
    return todayAlarmTime.add(const Duration(days: 1));
  }
  
  // Check if this alarm should trigger today
  bool shouldTriggerToday() {
    if (repeatDays.isEmpty) return true;
    
    final now = DateTime.now();
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final currentWeekday = weekdays[now.weekday - 1];
    
    return repeatDays.contains(currentWeekday);
  }
  
  // Get a TimeOfDay object for this alarm
  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
  
  // Get a readable string of repeat days
  String get repeatDaysText {
    if (repeatDays.isEmpty) return 'Once';
    
    if (repeatDays.length == 7) return 'Every day';
    
    if (repeatDays.length == 5 && 
        repeatDays.contains('monday') &&
        repeatDays.contains('tuesday') &&
        repeatDays.contains('wednesday') &&
        repeatDays.contains('thursday') &&
        repeatDays.contains('friday')) {
      return 'Weekdays';
    }
    
    if (repeatDays.length == 2 &&
        repeatDays.contains('saturday') &&
        repeatDays.contains('sunday')) {
      return 'Weekends';
    }
    
    // Just show the first letter of each day
    return repeatDays.map((day) => day.substring(0, 1).toUpperCase()).join(', ');
  }
}