import 'package:flutter/material.dart';
import 'package:lilas_kokoro/models/user_model.dart';
import 'package:lilas_kokoro/services/data_service.dart';
import 'package:lilas_kokoro/services/skeleton_service.dart';
import 'package:lilas_kokoro/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'dashboard_tab.dart';
import 'reminders_screen.dart';
import 'ai_companion_screen.dart';
import 'love_counter_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Static method to navigate to AI Companion tab
  static void navigateToAICompanionTab(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    if (homeState != null) {
      homeState._onTabChanged(2); // 2 is the index for AI Companion tab
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardTab(key: ValueKey('dashboard')),
    const RemindersScreen(key: ValueKey('reminders')),
    const AICompanionScreen(key: ValueKey('ai_companion')),
    const LoveCounterScreen(key: ValueKey('love_counter')),
    const SettingsScreen(key: ValueKey('settings')),
  ];
  
  // This keeps track of all tabs that have been viewed at least once
  final Set<int> _visitedTabs = {0}; // Start with dashboard as visited
  
  // Animation controller for tab transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Slightly longer for smoother effect
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // More elegant curve
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Start animation
    _animationController.forward();
    
    // Listen for data refresh events
    final dataService = Provider.of<DataService>(context, listen: false);
    dataService.addListener(_onDataRefresh);
  }

  @override
  void dispose() {
    // Dispose animation controller
    _animationController.dispose();
    
    // Remove listener to prevent memory leaks
    final dataService = Provider.of<DataService>(context, listen: false);
    dataService.removeListener(_onDataRefresh);
    super.dispose();
  }

  void _onDataRefresh() {
    // When data is refreshed, use the refresh state instead of regular loading
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    // Don't show skeleton for quick toggles
    if (skeletonService.isQuickToggle) return;
    
    skeletonService.showRefresh();
    
    // Hide refresh state after delay
    Future.delayed(const Duration(milliseconds: 1000), () {
    if (mounted) {
      skeletonService.hideRefresh();
      }
    });
  }
  
  void _onTabChanged(int index) {
    // Reset and play animation when tab changes
    _animationController.reset();
    
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index); // Mark this tab as visited
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserModel>(context).id;
    final themeService = Provider.of<ThemeService>(context);
    final skeletonService = Provider.of<SkeletonService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeService.isDarkMode;

    // Create gradient for bottom nav bar based on theme
    final navBarGradient = isDarkMode
        ? [
            Color.alphaBlend(colorScheme.primary.withOpacity(0.05), const Color(0xFF252535)),
            Color.alphaBlend(colorScheme.primary.withOpacity(0.02), const Color(0xFF1F1F2C)),
          ]
        : [
            Colors.white,
            Color.alphaBlend(colorScheme.primary.withOpacity(0.03), Colors.white),
          ];
    
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? colorScheme.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -2),
              spreadRadius: -3,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: navBarGradient,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabChanged,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: isDarkMode 
                ? Colors.white60 
                : colorScheme.onSurfaceVariant,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
            ),
            items: [
              _buildNavItem(Icons.home_rounded, 'Home'),
              _buildNavItem(Icons.notifications_rounded, 'Reminders'),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'AI Chat'),
              _buildNavItem(Icons.favorite_rounded, 'Love'),
              _buildNavItem(Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
  
  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = colorScheme.brightness == Brightness.dark;
    
    // Create more dynamic, glowing effect
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Icon(
          icon,
          size: 24,
          shadows: _selectedIndex == getIndexForLabel(label) && !isDarkMode
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode 
                  ? [
                      HSLColor.fromColor(colorScheme.primary).withLightness(0.7).toColor(),
                      colorScheme.primary,
                    ]
                  : [
                      colorScheme.primary,
                      HSLColor.fromColor(colorScheme.primary).withLightness(0.65).toColor(),
                    ],
            ).createShader(bounds);
          },
          child: Icon(
            icon,
            size: 26,
            shadows: isDarkMode 
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
          ),
        ),
      ),
      label: label,
    );
  }
  
  int getIndexForLabel(String label) {
    switch (label) {
      case 'Home': return 0;
      case 'Reminders': return 1;
      case 'AI Chat': return 2;
      case 'Love': return 3;
      case 'Settings': return 4;
      default: return 0;
    }
  }
}