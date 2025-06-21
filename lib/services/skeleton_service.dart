import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// A service that manages the global skeleton loading state across the app.
/// This ensures consistent loading behavior and prevents unnecessary
/// individual loading states in each screen.
class SkeletonService extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isQuickToggle = false;
  bool _isEnabled = false;
  bool _disposed = false;
  DateTime? _lastLoadingTime;
  Timer? _debounceTimer;
  
  // Debounce mechanism to prevent rapid loading state changes
  static const Duration _debounceThreshold = Duration(milliseconds: 100);
  
  /// Gets the current loading state
  bool get isLoading => _isLoading;
  
  /// Gets the current refreshing state
  bool get isRefreshing => _isRefreshing;
  
  /// Gets whether the current operation is a quick toggle
  bool get isQuickToggle => _isQuickToggle;

  /// Gets whether the skeleton UI is enabled
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('skeleton_enabled') ?? true; // Default to enabled
    return _isEnabled;
  }
  
  /// Sets the skeleton UI enabled state
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skeleton_enabled', value);
    notifyListeners();
  }
  
  /// Sets the loading state with debouncing to prevent flickering
  set isLoading(bool value) {
    if (_disposed) return;
    
    final now = DateTime.now();
    
    // Debounce rapid state changes
    if (_lastLoadingTime != null && 
        now.difference(_lastLoadingTime!) < _debounceThreshold &&
        _isLoading == value) {
      return;
    }
    
    if (_isLoading != value) {
      _isLoading = value;
      _lastLoadingTime = now;
      
      if (value == false) {
        _isQuickToggle = false; // Reset quick toggle state when loading ends
      }
      
      // Debounce notifications to prevent excessive rebuilds
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 16), () {
        if (!_disposed) {
          notifyListeners();
        }
      });
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
  
  /// Shows the skeleton loader with debouncing
  void showLoader() {
    isLoading = true;
  }
  
  /// Hides the skeleton loader
  void hideLoader() {
    isLoading = false;
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
      return await operation();
    } finally {
      _isQuickToggle = false;
    }
  }
  
  /// Executes an async operation with automatic skeleton loading
  /// Only shows skeleton for operations that take longer than threshold
  Future<T> withLoading<T>(Future<T> Function() operation, {
    Duration minimumLoadingTime = const Duration(milliseconds: 200),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      showLoader();
      final result = await operation();
      
      // Ensure minimum loading time to prevent flickering
      final elapsed = stopwatch.elapsed;
      if (elapsed < minimumLoadingTime) {
        await Future.delayed(minimumLoadingTime - elapsed);
      }
      
      return result;
    } finally {
      hideLoader();
      stopwatch.stop();
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
  
  /// Reset all loading states - useful for navigation or app state changes
  void reset() {
    if (_disposed) return;
    
    _debounceTimer?.cancel();
    _isLoading = false;
    _isRefreshing = false;
    _isQuickToggle = false;
    _lastLoadingTime = null;
    
    // Use Future.microtask to avoid calling notifyListeners during a build
    Future.microtask(() {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }
  
  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }
}