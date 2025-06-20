import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'dart:ui' as ui;

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int? currentIndex;
  final Function(int)? onTabSelected;
  final PreferredSizeWidget? customAppBar;
  final bool showAppBar;
  final bool showBottomNav;
  final Widget? leadingIcon;
  final Color? appBarColor;
  final Color? bottomNavColor;
  
  const AppScaffold({
    Key? key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.currentIndex,
    this.onTabSelected,
    this.customAppBar,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.leadingIcon,
    this.appBarColor,
    this.bottomNavColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    // Use provided colors or defaults
    final appBarBgColor = appBarColor ?? Colors.transparent;
    final bottomNavBgColor = bottomNavColor ?? Colors.transparent;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Space for app bar if showing
              if (showAppBar)
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
              
              // Main body content
              Expanded(child: body),
              
              // Space for bottom nav if showing
              if (showBottomNav)
                const SizedBox(height: 64),
            ],
          ),
          
          // Custom gradient app bar with rounded corners
          if (showAppBar)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildGradientAppBar(
                context, 
                isDarkMode, 
                appBarBgColor,
                themeService,
              ),
            ),
          
          // Custom gradient bottom nav with rounded corners
          if (showBottomNav && currentIndex != null && onTabSelected != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildGradientBottomNav(
                context, 
                isDarkMode, 
                bottomNavBgColor,
                currentIndex!,
                onTabSelected!,
                themeService,
              ),
            ),
          
          // FAB if provided
          if (floatingActionButton != null)
            Positioned(
              right: 16,
              bottom: showBottomNav ? 80 : 16,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }
  
  Widget _buildGradientAppBar(
    BuildContext context, 
    bool isDarkMode,
    Color baseColor,
    ThemeService themeService,
  ) {
    // Use consistent gradient colors for app header regardless of theme mode
    List<Color> gradientColors = [
      const Color(0xFFFF85A2), // Light pink
      const Color(0xFFFF6B94), // Slightly darker pink
    ];
    
    return Container(
      height: MediaQuery.of(context).padding.top + 56,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.5),
          radius: 1.5,
          colors: gradientColors,
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: customAppBar ?? SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Leading widget
                leadingIcon ?? const SizedBox.shrink(),
                
                // Title
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                // Actions
                if (actions != null)
                  ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGradientBottomNav(
    BuildContext context, 
    bool isDarkMode,
    Color baseColor,
    int currentIndex,
    Function(int) onTabSelected,
    ThemeService themeService,
  ) {
    final Size size = MediaQuery.of(context).size;
    
    // Use the SAME gradient colors as the app bar for consistency regardless of theme
    List<Color> gradientColors = [
      const Color(0xFFFF85A2), // Light pink
      const Color(0xFFFF6B94), // Slightly darker pink
    ];
    
    return Container(
      height: 64,
      width: size.width,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, 1.0),
          radius: 1.5,
          colors: gradientColors,
          stops: const [0.0, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
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
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home', currentIndex, onTabSelected),
              _buildNavItem(1, Icons.notifications_rounded, 'Reminders', currentIndex, onTabSelected),
              _buildNavItem(2, Icons.chat, 'AI Chat', currentIndex, onTabSelected),
              _buildNavItem(3, Icons.favorite_rounded, 'Love', currentIndex, onTabSelected),
              _buildNavItem(4, Icons.settings_rounded, 'Settings', currentIndex, onTabSelected),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(
    int index, 
    IconData icon, 
    String label, 
    int currentIndex,
    Function(int) onTabSelected
  ) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => onTabSelected(index),
      child: Container(
        width: 64,
        height: 50,
        decoration: isSelected ? BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ) : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: isSelected ? 24 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
  }
} 