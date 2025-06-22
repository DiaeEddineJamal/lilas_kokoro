import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/theme_service.dart';
import '../services/data_service.dart';
import '../models/user_model.dart';
import '../widgets/skeleton_loader.dart';
import '../services/skeleton_service.dart';


import 'ai_companion_screen.dart';
import 'reminders_screen.dart';
import 'love_counter_screen.dart';
import 'profile_edit_screen.dart';
import 'reminder_editor_screen.dart';
import '../models/chat_message_model.dart';
import '../services/ai_companion_service.dart';
import '../routes.dart';
import 'dart:io';

class DashboardTab extends StatefulWidget {
  final Function(int)? onTabChange;
  
  const DashboardTab({Key? key, this.onTabChange}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with AutomaticKeepAliveClientMixin {
  // Store DataService instance
  late DataService _dataService;
  late AICompanionService _aiService;
  
  // Cache data to prevent flickering with better state management
  List<dynamic>? _cachedReminders;
  List<ChatConversation>? _cachedConversations;
  bool _isInitialLoad = true;
  bool _hasLoadedOnce = false;
  
  // Keep alive to prevent rebuilds when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Get DataService instance here
    _dataService = Provider.of<DataService>(context, listen: false);
    _aiService = Provider.of<AICompanionService>(context, listen: false);
    
    // Load data immediately without skeleton for initial load
    _loadDataQuietly();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Load data without showing skeleton - for initial loads and background updates
  Future<void> _loadDataQuietly() async {
    if (!mounted) return;
    
    try {
      final results = await Future.wait([
        _dataService.getReminders(),
        _aiService.getConversations(),
      ]);
      
      if (mounted) {
        setState(() {
          _cachedReminders = results[0] as List<dynamic>?;
          _cachedConversations = results[1] as List<ChatConversation>?;
          _hasLoadedOnce = true;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _hasLoadedOnce = true;
          _isInitialLoad = false;
        });
      }
    }
  }

  /// Load data with skeleton - only for explicit user-triggered refreshes
  Future<void> _loadDataWithSkeleton() async {
    final skeletonService = Provider.of<SkeletonService>(context, listen: false);
    
    await skeletonService.withLoading(() async {
      await _loadDataQuietly();
    });
  }

  Future<void> _onRefresh() async {
    // Use skeleton loading for pull-to-refresh
    await _loadDataWithSkeleton();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final userId = Provider.of<UserModel>(context).id;
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final userModel = Provider.of<UserModel>(context);
    final skeletonService = Provider.of<SkeletonService>(context);

    // Only show skeleton on initial load or explicit loading
    final shouldShowSkeleton = _isInitialLoad || skeletonService.isLoading;

    return SkeletonLoaderFixed(
      isLoading: shouldShowSkeleton,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: themeService.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${userModel.name}! 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Welcome to your kawaii companion',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profile avatar with optimized image loading
                    GestureDetector(
                      onTap: () async {
                        // Navigate to ProfileEditScreen using consistent app navigation
                        await context.push('/profile-edit');
                        
                        // Refresh data quietly after profile update
                        _loadDataQuietly();
                      },
                      child: CircleAvatar(
                        backgroundColor: themeService.primary,
                        radius: 24,
                        backgroundImage: userModel.profileImagePath != null && 
                                        userModel.profileImagePath!.isNotEmpty &&
                                        File(userModel.profileImagePath!).existsSync()
                          ? FileImage(File(userModel.profileImagePath!))
                          : null,
                        child: userModel.profileImagePath == null || 
                               userModel.profileImagePath!.isEmpty ||
                               !File(userModel.profileImagePath!).existsSync()
                          ? Text(
                              userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : 'G',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Quick actions
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      context,
                      'Add Reminder',
                      Icons.notifications_active_rounded,
                      themeService.primary,
                      () {
                        // Navigate to Reminders tab (index 1)
                        widget.onTabChange?.call(1);
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      'AI Chat',
                      Icons.chat_bubble_rounded,
                      themeService.selectedPalette.secondary,
                      () {
                        // Navigate to AI Companion tab (index 3)
                        widget.onTabChange?.call(3);
                      },
                    ),
                    _buildQuickActionButton(
                      context,
                      'Love Counter',
                      Icons.favorite_rounded,
                      themeService.selectedPalette.accent,
                      () {
                        // Navigate to Love Counter tab (index 2)
                        widget.onTabChange?.call(2);
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Reminders
                Text(
                  'Recent Reminders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRemindersSection(),
                
                const SizedBox(height: 32),
                
                // Recent AI Conversations
                Text(
                  'Recent AI Conversations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildConversationsSection(),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonReminderCards() {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isDarkMode ? const Color(0xFF383844) : Colors.white,
          ),
        )
      ),
    );
  }

  Widget _buildSkeletonConversationCard() {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isDarkMode ? themeService.darkGradient : themeService.lightGradient,
                radius: 1.0,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: themeService.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: themeService.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    if (_cachedReminders == null) {
      return _buildSkeletonReminderCards();
    }
    
    // Filter for active reminders only, sort by date (latest first), and take 3
    final activeReminders = _cachedReminders!
        .where((reminder) => !reminder.isCompleted)
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    final recentReminders = activeReminders.take(3).toList();
    
    if (recentReminders.isEmpty) {
      return _buildEmptyState(
        context,
        'No active reminders',
        'Create your first reminder to get started',
        Icons.notifications_off_rounded,
      );
    }
    
    return Column(
      children: recentReminders.map((reminder) => 
        _buildReminderCard(context, reminder)
      ).toList(),
    );
  }

  Widget _buildReminderCard(BuildContext context, dynamic reminder) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Navigate to reminder editor screen with the existing reminder
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReminderEditorScreen(
                  existingReminder: reminder,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                                         color: themeService.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      reminder.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.formattedDateTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add a small edit icon to indicate it's clickable
                Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsSection() {
    if (_cachedConversations == null || _cachedConversations!.isEmpty) {
      return _buildEmptyState(
        context,
        'No conversations yet',
        'Start chatting with your AI companion',
        Icons.chat_bubble_outline_rounded,
      );
    }
    
    final recentConversations = _cachedConversations!.take(3).toList();
    
    return Column(
      children: recentConversations
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final conversation = entry.value;
            final isLast = index == recentConversations.length - 1;
            
            return Column(
              children: [
                _buildConversationCard(context, conversation),
                if (!isLast) const SizedBox(height: 12), // Add spacing between cards
              ],
            );
          })
          .toList(),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatConversation conversation) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    // Get last message and format time
    final lastMessage = conversation.lastMessage;
    final lastUpdateTime = _formatLastUpdateTime(conversation.updatedAt);
    
    return GestureDetector(
      onTap: () {
        // Navigate to AI Companion tab (index 3)
        widget.onTabChange?.call(3);
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF383844) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                             color: themeService.selectedPalette.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                  Icons.chat_bubble_outline_rounded,
                color: Color(0xFF9C89FF),
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          conversation.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                      ),
                Text(
                        lastUpdateTime,
                        style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessagePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ),
        ],
        ),
      ),
    );
  }
  
  // Helper to format the last update time
  String _formatLastUpdateTime(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.month}/${updatedAt.day}';
    }
  }
}