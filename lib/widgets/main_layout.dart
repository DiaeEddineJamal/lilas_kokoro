import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../screens/dashboard_tab.dart';
import '../screens/reminders_screen.dart';
import '../screens/love_counter_screen.dart';
import '../screens/ai_companion_screen.dart';
import '../screens/settings_screen.dart';
import '../models/user_model.dart';
import 'gradient_app_bar.dart';
import 'gradient_bottom_nav.dart';

/// Main layout widget with gradient navigation
class MainLayout extends StatefulWidget {
  final int? initialTab;
  
  const MainLayout({Key? key, this.initialTab}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<String> _titles = [
    '🏠 Dashboard',
    '⏰ Reminders', 
    '💕 Love Counter',
    '🤖 AI Companion',
    '⚙️ Settings',
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Reminders',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite_outline),
      activeIcon: Icon(Icons.favorite),
      label: 'Love Counter',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'AI Companion',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set initial tab if provided (e.g., from notification navigation)
    if (widget.initialTab != null) {
      _currentIndex = widget.initialTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeService, UserModel>(
      builder: (context, themeService, userModel, child) {
        final isDarkMode = themeService.isDarkMode;
        
        final List<Widget> _screens = [
          DashboardTab(onTabChange: _onItemTapped),
          const RemindersScreen(),
          const LoveCounterScreen(),
          const AICompanionScreen(),
          const SettingsScreen(),
        ];
        
        // Check if we're on the AI companion screen
        final isAICompanionScreen = _currentIndex == 3;
        
        return Scaffold(
          // Extend body behind app bar only for AI companion screen
          extendBodyBehindAppBar: isAICompanionScreen,
          extendBody: isAICompanionScreen, // This extends behind bottom nav bar
          appBar: GradientAppBar(
            title: _titles[_currentIndex],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                ],
              ),
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          bottomNavigationBar: GradientBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onItemTapped,
            items: _bottomNavItems,
          ),
        );
      },
    );
  }
} 