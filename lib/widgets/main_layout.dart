import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../services/theme_service.dart';
import '../screens/dashboard_tab.dart';
import '../screens/reminders_screen.dart';
import '../screens/ai_companion_screen.dart';
import '../screens/love_counter_screen.dart';
import '../screens/settings_screen.dart';
import '../services/skeleton_service.dart';
import '../routes.dart';
import 'app_scaffold.dart';
import 'app_header.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  final String? initialConversationId;
  
  const MainLayout({
    Key? key,
    this.initialIndex = 0,
    this.initialConversationId,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  late PersistentTabController _controller;
  String? _targetConversationId;
  
  // Use PageStorageBucket to preserve state
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

  // Animation controller for tab transitions
  late AnimationController _animationController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.initialIndex);
    _targetConversationId = widget.initialConversationId;
    _visitedTabs.add(widget.initialIndex);
    _previousIndex = widget.initialIndex;
    
    // Initialize animation controller for tab transitions
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Method to allow navigation to AI chat with specific conversation
  void navigateToAiChat(String? conversationId) {
    setState(() {
      _targetConversationId = conversationId;
      _previousIndex = _controller.index;
      _controller.index = 2; // Index for AI Chat
      _visitedTabs.add(2);
      _animateTabTransition();
    });
  }

  // Method to animate tab transitions
  void _animateTabTransition() {
    // Reset animation controller
    _animationController.reset();
    
    // Start animation
    _animationController.forward();
  }

  // Get transition direction based on indices
  Offset _getSlideDirection() {
    if (_previousIndex < _controller.index) {
      return const Offset(0.2, 0.0); // Right to left (new page comes from right)
    } else if (_previousIndex > _controller.index) {
      return const Offset(-0.2, 0.0); // Left to right (new page comes from left)
    }
    return Offset.zero;
  }

  // Build a specific screen with index
  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardTab(key: PageStorageKey('dashboard'));
      case 1:
        return const RemindersScreen(key: PageStorageKey('reminders'));
      case 2:
        return AICompanionScreen(
        key: PageStorageKey('ai_companion_$_targetConversationId'),
        conversationId: _targetConversationId,
        );
      case 3:
        return const LoveCounterScreen(key: PageStorageKey('love_counter'));
      case 4:
        return const SettingsScreen(key: PageStorageKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  // Build the animated content for the current tab
  Widget _buildAnimatedContent() {
    final currentIndex = _controller.index;
    final currentScreen = _buildScreen(currentIndex);
    
    // If we're not changing tabs, just return the current screen
    if (currentIndex == _previousIndex) {
      return currentScreen;
    }
    
    // Apply animations for tab transitions
    return FadeTransition(
      opacity: _animationController.drive(CurveTween(curve: Curves.easeOutCubic)),
      child: SlideTransition(
        position: _animationController.drive(
          Tween<Offset>(
            begin: _getSlideDirection(),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: currentScreen,
      ),
    );
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    // Define pink gradient colors for active items
    const Color activeColor = Color(0xFFFF6B94);
    const Color inactiveColor = Colors.white70;
    
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_rounded),
        title: 'Home',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.notifications_rounded),
        title: 'Reminders',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat),
        title: 'AI Chat',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.favorite_rounded),
        title: 'Love',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings_rounded),
        title: 'Settings',
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }
  
  // Helper to get the appropriate FAB for each screen
  Widget? _getFloatingActionButton(int index) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;

    // Select FAB color based on theme
    final fabColor = isDarkMode ? const Color(0xFF9E1A5A) : const Color(0xFFFF85A2);

    switch (index) {
      case 1: // Reminders - Now handled in the Reminders screen directly
        return null; // Don't create duplicate FAB
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    // Get screen-specific app bar actions
    List<Widget>? actions;
    if (_controller.index == 0) { // Dashboard
      actions = [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Refresh functionality
            final skeletonService = Provider.of<SkeletonService>(context, listen: false);
            skeletonService.showRefresh();
            
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                skeletonService.hideRefresh();
              }
            });
          },
        ),
      ];
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main animated content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 70), // Leave space for nav bar
              child: _buildAnimatedContent(),
            ),
          ),
          
          // Custom bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(0.0, 1.0),
                  radius: 1.5,
                  colors: [Color(0xFFFF85A2), Color(0xFFFF6B94)],
                  stops: [0.0, 1.0],
                ),
                // Remove box shadow entirely
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  final isSelected = _controller.index == index;
                  
                  // Get nav bar item details
                  final items = _navBarsItems();
                  final item = items[index];
                  
                  return InkWell(
                    onTap: () {
                      // Don't animate if tapping the same tab
                      if (_controller.index == index) {
                      // If on AI Chat tab and tapping again, reset conversation
                        if (index == 2) {
                        setState(() {
                          _targetConversationId = null;
                        });
                        }
                        return;
                      }
                      
                      // Store previous index for animation
                      final prevIndex = _controller.index;
                      
                      setState(() {
                        _previousIndex = prevIndex;
                        _controller.index = index;
                        _visitedTabs.add(index);
                        // Animate transition
                        _animateTabTransition();
                      });
                    },
                    child: Container(
                      width: 64,
                      height: 50,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon with badge indicator
                          Stack(
                            alignment: Alignment.center,
                        children: [
                          IconTheme(
                            data: IconThemeData(
                                  color: isSelected 
                                      ? Colors.white 
                                      : Colors.white.withOpacity(0.7),
                              size: isSelected ? 24 : 22,
                            ),
                            child: item.icon,
                              ),
                              // Bottom dot indicator for selected tab
                              if (isSelected)
                                Positioned(
                                  bottom: -8,
                                  child: Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Tab label
                          Text(
                            item.title ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          // App header at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGradientAppBar(
              context,
              themeService.isDarkMode,
              _screenTitles[_controller.index],
              actions,
            ),
          ),
          
          // FAB if needed
          if (_getFloatingActionButton(_controller.index) != null)
            Positioned(
              right: 16,
              bottom: 90, // Increased bottom padding to ensure it's above the navigation bar
              child: _getFloatingActionButton(_controller.index)!,
            ),
        ],
      ),
    );
  }
  
  Widget _buildGradientAppBar(
    BuildContext context, 
    bool isDarkMode,
    String title,
    List<Widget>? actions,
  ) {
    return AppHeader(
      title: title,
      actions: actions,
      height: MediaQuery.of(context).padding.top + 56,
    );
  }
} 