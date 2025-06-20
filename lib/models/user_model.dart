import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserModel extends ChangeNotifier {
  // Keep existing fields
  String _id = '';
  String _name = '';
  String _email = '';
  String _photoUrl = '';
  String _profileImagePath = '';
  DateTime? _createdAt;
  DateTime? _lastLogin;
  bool _onboardingCompleted = false;
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  int _colorSeed = 0;
  String _theme = 'default';
  String _themeColor = 'pink';
  
  // Add a flag to prevent unnecessary notifications
  bool _isBatchUpdating = false;
  
  // Constructor remains the same
  UserModel({
    String id = '',
    String name = '',
    String email = '',
    String photoUrl = '',
    String profileImagePath = '',
    DateTime? createdAt,
    DateTime? lastLogin,
    bool onboardingCompleted = false,
    bool isDarkMode = false,
    bool notificationsEnabled = true,
    int colorSeed = 0,
    String theme = 'default',
    String themeColor = 'pink',
  }) {
    _id = id;
    _name = name;
    _email = email;
    _photoUrl = photoUrl;
    _profileImagePath = profileImagePath;
    _createdAt = createdAt;
    _lastLogin = lastLogin;
    _onboardingCompleted = onboardingCompleted;
    _isDarkMode = isDarkMode;
    _notificationsEnabled = notificationsEnabled;
    _colorSeed = colorSeed;
    _theme = theme;
    _themeColor = themeColor;
  }
  
  // Add initialize method
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      
      if (userJson != null) {
        _isBatchUpdating = true; // Prevent multiple notifications
        final userData = json.decode(userJson);
        _id = userData['id'] ?? '';
        _name = userData['name'] ?? '';
        _email = userData['email'] ?? '';
        _photoUrl = userData['photoUrl'] ?? '';
        _profileImagePath = userData['profileImagePath'] ?? '';
        _createdAt = userData['createdAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(userData['createdAt']) 
            : null;
        _lastLogin = userData['lastLogin'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(userData['lastLogin']) 
            : null;
        _onboardingCompleted = userData['onboardingCompleted'] ?? false;
        _isDarkMode = userData['isDarkMode'] ?? false;
        _notificationsEnabled = userData['notificationsEnabled'] ?? true;
        _colorSeed = userData['colorSeed'] ?? 0;
        _theme = userData['theme'] ?? 'default';
        _themeColor = userData['themeColor'] ?? 'pink';
        _isBatchUpdating = false;
        notifyListeners(); // Only notify once after all updates
      }
      debugPrint('✅ UserModel initialized successfully');
    } catch (e) {
      _isBatchUpdating = false;
      debugPrint('❌ Error initializing UserModel: $e');
    }
  }
  
  // Getters
  String get id => _id;
  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get profileImagePath => _profileImagePath;
  DateTime? get createdAt => _createdAt;
  DateTime? get lastLogin => _lastLogin;
  bool get onboardingCompleted => _onboardingCompleted;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  int get colorSeed => _colorSeed;
  String get theme => _theme;
  String get themeColor => _themeColor;
  
  // Update copyWith method to make colorSeed optional
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? profileImagePath,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? onboardingCompleted,
    bool? isDarkMode,
    bool? notificationsEnabled,
    int? colorSeed,
    String? theme,
    String? themeColor,
  }) {
    _id = id ?? _id;
    _name = name ?? _name;
    _email = email ?? _email;
    _photoUrl = photoUrl ?? _photoUrl;
    _profileImagePath = profileImagePath ?? _profileImagePath;
    _createdAt = createdAt ?? _createdAt;
    _lastLogin = lastLogin ?? _lastLogin;
    _onboardingCompleted = onboardingCompleted ?? _onboardingCompleted;
    _isDarkMode = isDarkMode ?? _isDarkMode;
    _notificationsEnabled = notificationsEnabled ?? _notificationsEnabled;
    _colorSeed = colorSeed ?? _colorSeed;
    _theme = theme ?? _theme;
    _themeColor = themeColor ?? _themeColor;
    
    notifyListeners();
    return this;
  }
  
  // Update toMap and fromMap methods
  Map<String, dynamic> toMap() {
    return {
      'id': _id,
      'name': _name,
      'email': _email,
      'photoUrl': _photoUrl,
      'profileImagePath': _profileImagePath,
      'createdAt': _createdAt?.millisecondsSinceEpoch,
      'lastLogin': _lastLogin?.millisecondsSinceEpoch,
      'onboardingCompleted': _onboardingCompleted,
      'isDarkMode': _isDarkMode,
      'notificationsEnabled': _notificationsEnabled,
      'colorSeed': _colorSeed,
      'theme': _theme,
      'themeColor': _themeColor,
    };
  }
  
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      profileImagePath: map['profileImagePath'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
          : null,
      lastLogin: map['lastLogin'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLogin']) 
          : null,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      isDarkMode: map['isDarkMode'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      colorSeed: map['colorSeed'] ?? 0,
      theme: map['theme'] ?? 'default',
      themeColor: map['themeColor'] ?? 'pink',
    );
  }

  // Add method to sync with another UserModel instance (for DataService integration)
  void syncWith(UserModel other) {
    if (_isBatchUpdating) return; // Prevent recursive updates
    
    _isBatchUpdating = true;
    _id = other._id;
    _name = other._name;
    _email = other._email;
    _photoUrl = other._photoUrl;
    _profileImagePath = other._profileImagePath;
    _createdAt = other._createdAt;
    _lastLogin = other._lastLogin;
    _onboardingCompleted = other._onboardingCompleted;
    _isDarkMode = other._isDarkMode;
    _notificationsEnabled = other._notificationsEnabled;
    _colorSeed = other._colorSeed;
    _theme = other._theme;
    _themeColor = other._themeColor;
    _isBatchUpdating = false;
    
    notifyListeners();
    debugPrint('🔄 UserModel synced with external data: ${_name}');
  }

  // Add method to refresh from SharedPreferences (for real-time updates)
  Future<void> refresh() async {
    await initialize();
  }
}