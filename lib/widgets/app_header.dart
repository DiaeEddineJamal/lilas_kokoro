import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

/// A beautiful app header with radial gradient and rounded corners
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;
  final Widget? leading;
  final bool enableBackButton;
  final bool enableActionButton;
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  
  // Map of cute emojis for different titles
  static const Map<String, String> _titleEmojis = {
    'Dashboard': '🏠',
    'Reminders': '✨',
    'AI Companion': '🌸',
    'Journal': '📔',
    'Create Reminder': '📝',
    'Edit Reminder': '✏️',
    'Settings': '⚙️',
    'Profile': '👤',
    'Notifications': '🔔',
  };
  
  const AppHeader({
    super.key,
    required this.title,
    this.titleIcon,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.height = 80,
    this.leading,
    this.enableBackButton = false,
    this.enableActionButton = true,
    this.actionIcon,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    // Get cute emoji for title or use a default
    final titleEmoji = _titleEmojis[title] ?? '💖';
    
    // Debug print to check if emoji is being set
    debugPrint('App Header Title: $title, Emoji: $titleEmoji');
    
    // Use consistent gradient colors regardless of theme
    List<Color> gradientColors = [
      const Color(0xFFFF85A2), // Light pink
      const Color(0xFFFF6B94), // Slightly darker pink
    ];
    
    return Container(
      height: height,
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              else if (leading != null)
                leading!
              else
                const SizedBox(width: 40),
                
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$titleEmoji $title",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              
              if (actions != null && actions!.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                )
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(height);
} 