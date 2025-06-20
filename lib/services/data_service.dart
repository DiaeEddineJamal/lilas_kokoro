import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../models/love_counter_model.dart';
import '../models/milestone_model.dart';
import '../models/sound_model.dart';
import '../models/user_model.dart';
import '../models/default_reminders.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  
  // Storage keys
  static const String _userKey = 'user_data';
  static const String _remindersKey = 'reminders_data';
  static const String _loveCounterKey = 'love_counter_data';
  static const String _soundsKey = 'sounds_data';
  static const String _conversationsKey = 'conversations';
  
  // In-memory cache
  UserModel? _currentUser;
  List<Reminder>? _reminders;
  LoveCounter? _loveCounter;
  List<Sound>? _sounds;
  List<ChatConversation>? _conversations;
  
  // Initialization flag
  bool _isInitialized = false;
  
  // Callback to notify UserModel provider when user data changes
  Function(UserModel)? _userUpdateCallback;
  
  DataService._internal();
  
  // Set callback for UserModel updates
  void setUserUpdateCallback(Function(UserModel) callback) {
    _userUpdateCallback = callback;
  }
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadData();
    _isInitialized = true;
    debugPrint('✅ DataService initialized successfully');
  }
  
  // Load all data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we should ignore existing data due to fresh install detection
    final bool isFreshInstall = prefs.getBool('app_installed') == null || prefs.getBool('app_installed') == false;
    
    // Load user data - DON'T create default user if none exists
    // Let the onboarding flow handle user creation
    final userJson = prefs.getString(_userKey);
    if (userJson != null && !isFreshInstall) {
      try {
        _currentUser = UserModel.fromMap(json.decode(userJson));
        debugPrint('📱 DataService: Loaded existing user: ${_currentUser?.name}');
      } catch (e) {
        debugPrint('❌ Error loading user data: $e');
        _currentUser = null;
      }
    } else {
      if (isFreshInstall && userJson != null) {
        debugPrint('📱 DataService: Fresh install detected - ignoring existing user data');
      } else {
        debugPrint('📱 DataService: No existing user data found - onboarding required');
      }
      _currentUser = null;
    }
    
    // Only load other data if user exists (after onboarding)
    if (_currentUser != null) {
      // Load reminders
      final remindersJson = prefs.getString(_remindersKey);
      if (remindersJson != null) {
        final List<dynamic> remindersList = json.decode(remindersJson);
        _reminders = remindersList.map((e) => Reminder.fromMap(e)).toList();
      } else {
        // Create default reminders for existing user
        _reminders = DefaultReminders.createDefaultReminders(_currentUser!.id);
        await saveReminders(_reminders!);
      }
      
      // Load conversations
      final conversationsJson = prefs.getString(_conversationsKey);
      if (conversationsJson != null) {
        final List<dynamic> conversationsList = json.decode(conversationsJson);
        _conversations = conversationsList.map((e) => ChatConversation.fromMap(e)).toList();
      } else {
        // Create default empty conversations list
        _conversations = [];
        await saveConversations(_conversations!);
      }
      
      // Load love counter
      final loveCounterJson = prefs.getString(_loveCounterKey);
      if (loveCounterJson != null) {
        _loveCounter = LoveCounter.fromMap(json.decode(loveCounterJson));
      } else {
        // Create default love counter for existing user
        _loveCounter = LoveCounter(
          id: const Uuid().v4(),
          userId: _currentUser!.id,
          userName: 'You',
          partnerName: 'Partner',
          anniversaryDate: DateTime.now(),
          emoji: '❤️',
          milestones: [],
        );
        await saveLoveCounter(_loveCounter!);
      }
      
      // Load sounds
      final soundsJson = prefs.getString(_soundsKey);
      if (soundsJson != null) {
        final List<dynamic> soundsList = json.decode(soundsJson);
        _sounds = soundsList.map((e) => Sound.fromMap(e)).toList();
      } else {
        // Create default sounds for existing user
        _sounds = [
          Sound(
            id: 'default_notification',
            name: 'Default Notification',
            storageUrl: 'assets/sounds/default_notification.mp3',
            userId: _currentUser!.id,
            type: SoundType.notification,
            isAsset: true,
            isDefault: true,
          )
        ];
        await saveSounds(_sounds!);
      }
    } else {
      // No user exists - initialize empty data
      _reminders = [];
      _conversations = [];
      _loveCounter = null;
      _sounds = [];
      debugPrint('📱 DataService: Initialized with empty data - awaiting onboarding');
    }
  }
  
  // USER METHODS
  
  // Get current user
  UserModel? getCurrentUser() {
    return _currentUser;
  }
  
  // Check if user exists (useful for onboarding flow)
  bool hasUser() {
    return _currentUser != null;
  }
  
  // Save user
  Future<void> saveUser(UserModel user) async {
    final bool isFirstTimeUser = _currentUser == null;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toMap()));
    
    // If this is the first time saving a user, initialize default data
    if (isFirstTimeUser) {
      await _initializeDefaultDataForUser(user);
    }
    
    notifyListeners();
    
    // Notify UserModel provider of the update
    if (_userUpdateCallback != null) {
      _userUpdateCallback!(user);
    }
  }
  
  // Initialize default data for a new user (called after onboarding)
  Future<void> _initializeDefaultDataForUser(UserModel user) async {
    debugPrint('📱 DataService: Initializing default data for new user: ${user.name}');
    
    // Create default reminders
    _reminders = DefaultReminders.createDefaultReminders(user.id);
    await saveReminders(_reminders!);
    
    // Create empty conversations list
    _conversations = [];
    await saveConversations(_conversations!);
    
    // Create default love counter
    _loveCounter = LoveCounter(
      id: const Uuid().v4(),
      userId: user.id,
      userName: 'You',
      partnerName: 'Partner',
      anniversaryDate: DateTime.now(),
      emoji: '❤️',
      milestones: [],
    );
    await saveLoveCounter(_loveCounter!);
    
    // Create default sounds
    _sounds = [
      Sound(
        id: 'default_notification',
        name: 'Default Notification',
        storageUrl: 'assets/sounds/default_notification.mp3',
        userId: user.id,
        type: SoundType.notification,
        isAsset: true,
        isDefault: true,
      )
    ];
    await saveSounds(_sounds!);
    
    debugPrint('✅ DataService: Default data initialized for user: ${user.name}');
  }
  
  // Update user
  Future<void> updateUser({
    String? name,
    String? email,
    String? photoUrl,
    bool? isDarkMode,
    bool? notificationsEnabled,
    int? colorSeed,  // Add this parameter
  }) async {
    if (_currentUser == null) return;
    
    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      photoUrl: photoUrl,
      isDarkMode: isDarkMode,
      notificationsEnabled: notificationsEnabled,
      lastLogin: DateTime.now(),
      colorSeed: colorSeed,  // Add this parameter
    );
    
    await saveUser(_currentUser!);
  }
  
  // REMINDER METHODS
  
  // Get all reminders
  Future<List<Reminder>> getReminders() async {
    if (_reminders == null) {
      await _loadData();
    }
    return _reminders ?? [];
  }
  
  // Get reminder by ID
  Future<Reminder?> getReminderById(String id) async {
    final reminders = await getReminders();
    return reminders.firstWhere((r) => r.id == id, orElse: () => null as Reminder);
  }
  
  // Add new method for optimistic UI updates without saving to persistent storage
  void updateLocalReminder(Reminder reminder) {
    if (_reminders == null) return;
    
    final index = _reminders!.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      _reminders![index] = reminder;
      // Notify listeners but don't save to SharedPreferences
      notifyListeners();
    }
  }
  
  // Add reminder
  Future<void> addReminder(Reminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }
  
  // Update reminder
  Future<void> updateReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    
    if (index >= 0) {
      reminders[index] = reminder;
      await saveReminders(reminders);
    }
  }
  
  // Delete reminder
  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
  }
  
  // Toggle reminder completion with optimistic updates
  Future<void> toggleReminderCompletionOptimistic(String id) async {
    if (_reminders == null) return;
    
    final index = _reminders!.indexWhere((r) => r.id == id);
    if (index < 0) return;
    
    // Create updated reminder with toggled status
    final updatedReminder = _reminders![index].copyWith(
      isCompleted: !_reminders![index].isCompleted,
      );
    
    // Update UI immediately
    updateLocalReminder(updatedReminder);
    
    // Then persist the change
    try {
      await updateReminder(updatedReminder);
    } catch (e) {
      // If update fails, revert to original state
      updateLocalReminder(_reminders![index]);
      debugPrint('Error updating reminder completion: $e');
    }
  }
  
  // Save reminders
  Future<void> saveReminders(List<Reminder> reminders) async {
    _reminders = reminders;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remindersKey, json.encode(reminders.map((r) => r.toMap()).toList()));
    notifyListeners();
  }
  
  // CONVERSATION METHODS
  
  // Get all conversations
  Future<List<ChatConversation>> getConversations() async {
    if (_conversations == null) {
      await _loadData();
    }
    return _conversations ?? [];
  }
  
  // Get conversation by ID
  Future<ChatConversation?> getConversationById(String id) async {
    final conversations = await getConversations();
    try {
      return conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Add conversation
  Future<void> addConversation(ChatConversation conversation) async {
    final conversations = await getConversations();
    conversations.add(conversation);
    await saveConversations(conversations);
  }
  
  // Update conversation
  Future<void> updateConversation(ChatConversation conversation) async {
    final conversations = await getConversations();
    final index = conversations.indexWhere((c) => c.id == conversation.id);
    
    if (index >= 0) {
      conversations[index] = conversation;
      await saveConversations(conversations);
    }
  }
  
  // Delete conversation
  Future<void> deleteConversation(String id) async {
    final conversations = await getConversations();
    conversations.removeWhere((c) => c.id == id);
    await saveConversations(conversations);
  }
  
  // Save conversations
  Future<void> saveConversations(List<ChatConversation> conversations) async {
    _conversations = conversations;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_conversationsKey, json.encode(conversations.map((c) => c.toMap()).toList()));
    notifyListeners();
  }
  
  // LOVE COUNTER METHODS
  
  // Get love counter
  Future<LoveCounter?> getLoveCounter() async {
    if (_loveCounter == null) {
      await _loadData();
    }
    return _loveCounter;
  }
  
  // Update love counter
  Future<void> updateLoveCounter(LoveCounter loveCounter) async {
    _loveCounter = loveCounter;
    await saveLoveCounter(loveCounter);
  }
  
  // Save love counter
  Future<void> saveLoveCounter(LoveCounter loveCounter) async {
    _loveCounter = loveCounter;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loveCounterKey, json.encode(loveCounter.toMap()));
    notifyListeners();
  }
  
  // Add milestone
  Future<void> addMilestone(Milestone milestone) async {
    if (_loveCounter == null) {
      await _loadData();
    }
    
    if (_loveCounter != null) {
      final milestones = List<Milestone>.from(_loveCounter!.milestones);
      milestones.add(milestone);
      
      _loveCounter = _loveCounter!.copyWith(
        milestones: milestones,
      );
      
      await saveLoveCounter(_loveCounter!);
    }
  }
  
  // Update milestone
  Future<void> updateMilestone(Milestone milestone) async {
    if (_loveCounter == null) {
      await _loadData();
    }
    
    if (_loveCounter != null) {
      final milestones = List<Milestone>.from(_loveCounter!.milestones);
      final index = milestones.indexWhere((m) => m.id == milestone.id);
      
      if (index >= 0) {
        milestones[index] = milestone;
        
        _loveCounter = _loveCounter!.copyWith(
          milestones: milestones,
        );
        
        await saveLoveCounter(_loveCounter!);
      }
    }
  }
  
  // Delete milestone
  Future<void> deleteMilestone(String id) async {
    if (_loveCounter == null) {
      await _loadData();
    }
    
    if (_loveCounter != null) {
      final milestones = List<Milestone>.from(_loveCounter!.milestones);
      milestones.removeWhere((m) => m.id == id);
      
      _loveCounter = _loveCounter!.copyWith(
        milestones: milestones,
      );
      
      await saveLoveCounter(_loveCounter!);
    }
  }
  
  // SOUND METHODS
  
  // Get all sounds
  Future<List<Sound>> getSounds() async {
    if (_sounds == null) {
      await _loadData();
    }
    return _sounds ?? [];
  }
  
  // Add sound
  Future<void> addSound(Sound sound) async {
    final sounds = await getSounds();
    sounds.add(sound);
    await saveSounds(sounds);
  }
  
  // Delete sound
  Future<void> deleteSound(String id) async {
    final sounds = await getSounds();
    sounds.removeWhere((s) => s.id == id);
    await saveSounds(sounds);
  }
  
  // Save sounds
  Future<void> saveSounds(List<Sound> sounds) async {
    _sounds = sounds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundsKey, json.encode(sounds.map((s) => s.toMap()).toList()));
    notifyListeners();
  }
  
  // UTILITY METHODS
  
  // Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _currentUser = null;
    _reminders = null;
    _loveCounter = null;
    _sounds = null;
    _conversations = null;
    
    notifyListeners();
  }
}