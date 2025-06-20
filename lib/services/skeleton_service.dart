import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that manages the global skeleton loading state across the app.
/// This ensures consistent loading behavior and prevents unnecessary
/// individual loading states in each screen.
class SkeletonService extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isQuickToggle = false;
  bool _isEnabled = false;
  
  /// Gets the current loading state
  bool get isLoading => _isLoading;
  
  /// Gets the current refreshing state
  bool get isRefreshing => _isRefreshing;
  
  /// Gets whether the current operation is a quick toggle
  bool get isQuickToggle => _isQuickToggle;

  /// Gets whether the skeleton UI is enabled
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('skeleton_enabled') ?? false;
    return _isEnabled;
  }
  
  /// Sets the skeleton UI enabled state
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skeleton_enabled', value);
    notifyListeners();
  }
  
  /// Sets the loading state and notifies listeners
  set isLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      if (value == false) {
        _isQuickToggle = false; // Reset quick toggle state when loading ends
      }
      notifyListeners();
    }
  }
  
  /// Sets the refreshing state and notifies listeners
  set isRefreshing(bool value) {
    if (_isRefreshing != value) {
      _isRefreshing = value;
      notifyListeners();
    }
  }
  
  /// Sets the quick toggle state (for operations like toggling reminders/alarms)
  set isQuickToggle(bool value) {
    if (_isQuickToggle != value) {
      _isQuickToggle = value;
      notifyListeners();
    }
  }
  
  /// Shows the skeleton loader
  void showLoader() {
    _isLoading = true;
    notifyListeners();
  }
  
  /// Hides the skeleton loader
  void hideLoader() {
    _isLoading = false;
    notifyListeners();
  }
  
  /// Shows the refresh loader
  void showRefresh() {
    _isRefreshing = true;
    notifyListeners();
  }
  
  /// Hides the refresh loader
  void hideRefresh() {
    _isRefreshing = false;
    notifyListeners();
  }
  
  /// Marks the current operation as a quick toggle (will not show skeleton)
  void markAsQuickToggle() {
    _isQuickToggle = true;
  }
  
  /// Executes an async operation as a quick toggle operation
  /// This is used for operations like toggling reminders/alarms
  /// that should not show the skeleton loader
  Future<T> withQuickToggle<T>(Future<T> Function() operation) async {
    try {
      _isQuickToggle = true;
      showLoader();
      return await operation();
    } finally {
      hideLoader();
    }
  }
  
  /// Executes an async operation with automatic skeleton loading
  /// 
  /// Shows the skeleton loader before the operation starts and
  /// hides it when the operation completes (whether successfully or with an error)
  Future<T> withLoading<T>(Future<T> Function() operation) async {
    try {
      showLoader();
      return await operation();
    } finally {
      hideLoader();
    }
  }

  /// Executes an async operation with automatic refresh loading
  Future<T> withRefresh<T>(Future<T> Function() operation) async {
    try {
      showRefresh();
      return await operation();
    } finally {
      hideRefresh();
    }
  }
}