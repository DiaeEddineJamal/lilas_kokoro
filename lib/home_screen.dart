import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'models/user_model.dart';
import 'services/data_service.dart';
import 'services/skeleton_service.dart';
import 'screens/dashboard_tab.dart';
import 'screens/reminders_screen.dart';
import 'screens/ai_companion_screen.dart';
import 'screens/love_counter_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/gradient_app_bar.dart';
import 'widgets/gradient_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialConversationId;

  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialConversationId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _targetConversationId;

  List<Widget> get _screens => [
        const DashboardTab(key: PageStorageKey('dashboard')),
        const RemindersScreen(key: PageStorageKey('reminders')),
        AICompanionScreen(
          key: PageStorageKey('ai_companion_$_targetConversationId'),
          conversationId: _targetConversationId,
        ),
        const LoveCounterScreen(key: PageStorageKey('love_counter')),
        const SettingsScreen(key: PageStorageKey('settings')),
      ];

  final PageStorageBucket _bucket = PageStorageBucket();
  final Set<int> _visitedTabs = {0};

  final List<String> _screenTitles = [
    '🏠 Dashboard',
    '⏰ Reminders',
    '🤖 AI Companion',
    '💕 Love Counter',
    '⚙️ Settings'
  ];

  late DataService _dataService;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _targetConversationId = widget.initialConversationId;
    _visitedTabs.add(_selectedIndex);
    
    _dataService = Provider.of<DataService>(context, listen: false);
    _dataService.addListener(_onDataRefresh);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataRefresh);
    super.dispose();
  }

  void _onDataRefresh() {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    skeletonService.showRefresh();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        skeletonService.hideRefresh();
      }
    });
  }

  void navigateToAiChat(String? conversationId) {
    setState(() {
      _targetConversationId = conversationId;
      _selectedIndex = 2;
      _visitedTabs.add(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final skeletonService = Provider.of<SkeletonService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;

    final screenTitle = _screenTitles[_selectedIndex];

    List<Widget>? actions;
    if (_selectedIndex == 0) {
      actions = [
        IconButton(
          onPressed: _onDataRefresh,
          icon: const Icon(
            Icons.refresh,
            size: 20,
            color: Colors.white,
          ),
        ),
      ];
    } else if (_selectedIndex == 2) {
      // AI Companion screen - add conversations menu
      actions = [
        IconButton(
          onPressed: () {
            // You can add conversation management functionality here
            // For now, just show a placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conversations menu')),
            );
          },
          icon: const Icon(
            Icons.menu,
            size: 20,
            color: Colors.white,
          ),
        ),
      ];
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: screenTitle,
        actions: actions,
      ),
      bottomNavigationBar: GradientBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            if (index != 2) {
              _targetConversationId = null;
            }
            _selectedIndex = index;
            _visitedTabs.add(index);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Love',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
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
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
      ),
    );
  }

  Widget? _getFloatingActionButton(int index) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;

    final fabColor = isDarkMode ? themeService.selectedPalette.deep : themeService.primary;

    switch (index) {
      case 1: // Reminders
        return FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/reminder_editor');
          },
          backgroundColor: fabColor,
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
      case 3: // Love Counter
        return FloatingActionButton(
          onPressed: () {
            // Handle love counter specific action
          },
          backgroundColor: fabColor,
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 28,
          ),
        );
      default:
        return null;
    }
  }
} 