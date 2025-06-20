import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/reminder_model.dart';
import '../models/alarm_model.dart';
import '../models/love_counter_model.dart';
import '../models/sound_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // Storage keys
  static const String _userKey = 'user_data';
  static const String _remindersKey = 'reminders_data';
  static const String _alarmsKey = 'alarms_data';
  static const String _loveCounterKey = 'love_counter_data';
  static const String _soundsKey = 'sounds_data';
  
  // USER METHODS
  
  Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        return UserModel.fromMap(json.decode(userJson));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user: $e');
      return null;
    }
  }
  
  Future<bool> saveUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toMap()));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
      return false;
    }
  }
  
  // REMINDER METHODS
  
  Future<List<Reminder>> getReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString(_remindersKey);
      
      if (remindersJson != null) {
        final List<dynamic> remindersList = json.decode(remindersJson);
        return remindersList.map((e) => Reminder.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting reminders: $e');
      return [];
    }
  }
  
  Future<bool> saveReminders(List<Reminder> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_remindersKey, json.encode(reminders.map((r) => r.toMap()).toList()));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving reminders: $e');
      return false;
    }
  }
  
  // ALARM METHODS
  
  Future<List<Alarm>> getAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(_alarmsKey);
      
      if (alarmsJson != null) {
        final List<dynamic> alarmsList = json.decode(alarmsJson);
        return alarmsList.map((e) => Alarm.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting alarms: $e');
      return [];
    }
  }
  
  Future<bool> saveAlarms(List<Alarm> alarms) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alarmsKey, json.encode(alarms.map((a) => a.toMap()).toList()));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving alarms: $e');
      return false;
    }
  }
  
  // LOVE COUNTER METHODS
  
  Future<LoveCounter?> getLoveCounter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loveCounterJson = prefs.getString(_loveCounterKey);
      
      if (loveCounterJson != null) {
        return LoveCounter.fromMap(json.decode(loveCounterJson));
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting love counter: $e');
      return null;
    }
  }
  
  Future<bool> saveLoveCounter(LoveCounter loveCounter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loveCounterKey, json.encode(loveCounter.toMap()));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving love counter: $e');
      return false;
    }
  }
  
  // SOUND METHODS
  
  Future<List<Sound>> getSounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundsJson = prefs.getString(_soundsKey);
      
      if (soundsJson != null) {
        final List<dynamic> soundsList = json.decode(soundsJson);
        return soundsList.map((e) => Sound.fromMap(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting sounds: $e');
      return [];
    }
  }
  
  Future<bool> saveSounds(List<Sound> sounds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_soundsKey, json.encode(sounds.map((s) => s.toMap()).toList()));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving sounds: $e');
      return false;
    }
  }
  
  // UTILITY METHODS
  
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      return false;
    }
  }
}