import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lilas_kokoro/models/user_model.dart';
import 'package:lilas_kokoro/services/data_service.dart';
import 'package:lilas_kokoro/services/skeleton_service.dart';
import 'package:lilas_kokoro/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'screens/dashboard_tab.dart';
import 'screens/reminders_screen.dart';
import 'screens/ai_companion_screen.dart';
import 'screens/love_counter_screen.dart';
import 'screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialConversationId;

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0, // Default to Dashboard tab
    this.initialConversationId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Remove 'global' keyword which is not valid Dart syntax
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _targetConversationId; // To hold the ID for AI chat

  // Use AutomaticKeepAliveClientMixin to ensure widget states are preserved
  List<Widget> get _screens => [
        const DashboardTab(key: PageStorageKey('dashboard')),
        const RemindersScreen(key: PageStorageKey('reminders')),
        // Pass the targetConversationId to AICompanionScreen
        AICompanionScreen(
          key: PageStorageKey('ai_companion_$_targetConversationId'), // Key changes to force rebuild if ID changes
          conversationId: _targetConversationId,
        ),
        const LoveCounterScreen(key: PageStorageKey('love_counter')),
        const SettingsScreen(key: PageStorageKey('settings')),
      ];

  // Use PageStorageBucket to preserve the state of each tab
  final PageStorageBucket _bucket = PageStorageBucket();

  // This keeps track of all tabs that have been viewed at least once
  final Set<int> _visitedTabs = {0}; // Start with dashboard as visited

  // Screen titles for the app bar
  final List<String> _screenTitles = [
    'Dashboard',
    'Reminders',
    'AI Companion',
    'Love Counter',
    'Settings'
  ];

  // Store DataService instance to avoid context issues in dispose
  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    // Set initial index and conversation ID from widget properties
    _selectedIndex = widget.initialTabIndex;
    _targetConversationId = widget.initialConversationId;
    _visitedTabs.add(_selectedIndex); // Mark initial tab as visited
    
    // Get DataService instance here
    _dataService = Provider.of<DataService>(context, listen: false);
    _dataService.addListener(_onDataRefresh);
  }

  @override
  void dispose() {
    // Remove listener using the stored instance
    _dataService.removeListener(_onDataRefresh);
    super.dispose();
  }

  void _onDataRefresh() {
    // When data is refreshed, show brief loading indication
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.showRefresh();

    // Hide refresh state after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        skeletonService.hideRefresh();
      }
    });
  }

  // Method to allow AI chat drawer to switch tab and load conversation
  void navigateToAiChat(String? conversationId) {
    setState(() {
      _targetConversationId = conversationId;
      _selectedIndex = 2; // Index for AI Chat
      _visitedTabs.add(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final skeletonService = Provider.of<SkeletonService>(context);
    final themeService = Provider.of<ThemeService>(context);

    // Determine if we should show a skeleton for this tab
    final shouldShowLoader = !_visitedTabs.contains(_selectedIndex) || skeletonService.isRefreshing;

    // Get screen title
    final screenTitle = _screenTitles[_selectedIndex];

    // Define actions for each screen
    List<Widget>? actions;

    // Add screen-specific actions here if needed
    if (_selectedIndex == 0) { // Dashboard
      actions = [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _onDataRefresh,
        ),
      ];
    }

    return AppScaffold(
      title: screenTitle,
      actions: actions,
      currentIndex: _selectedIndex,
      onTabSelected: (index) {
        setState(() {
          // Reset target conversation ID if navigating away from AI chat manually
          if (index != 2) {
             _targetConversationId = null;
          }
          _selectedIndex = index;
          _visitedTabs.add(index); // Mark this tab as visited
        });
      },
      floatingActionButton: _getFloatingActionButton(_selectedIndex),
      body: PageStorage(
        bucket: _bucket,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          // Use IndexedStack for better state preservation across tabs
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // child: KeyedSubtree(
          //   key: ValueKey<int>(_selectedIndex),
          //   child: shouldShowLoader
          //       ? _buildLoadingScreen(_screens[_selectedIndex])
          //       : _screens[_selectedIndex],
          // ),
        ),
      ),
    );
  }

  // Helper to show loading screen
  Widget _buildLoadingScreen(Widget screen) {
    // Use a SingleTickerProvider inside the screen implementation
    // to avoid the multiple tickers issue
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: screen,
    );
  }

  // Helper to get the appropriate FAB for each screen
  Widget? _getFloatingActionButton(int index) {
    final themeService = Provider.of<ThemeService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeService.isDarkMode;

    // Select FAB color based on theme
    final fabColor = isDarkMode ? const Color(0xFF9E1A5A) : const Color(0xFFFF85A2);

    switch (index) {
      case 1: // Reminders
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/reminder_editor');
          },
          backgroundColor: fabColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // AI Companion
        return FloatingActionButton(
          onPressed: () {
            // Create a new conversation by navigating to AI Chat tab without specific ID
            navigateToAiChat(null);
          },
          backgroundColor: fabColor,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.chat, color: Colors.white),
        );
      default:
        return null;
    }
  }
} 