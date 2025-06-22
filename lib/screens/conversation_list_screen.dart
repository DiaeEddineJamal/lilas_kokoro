import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message_model.dart';
import '../services/ai_companion_service.dart';
import '../services/theme_service.dart';
import '../widgets/app_header.dart';
import 'ai_companion_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({Key? key}) : super(key: key);

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late AICompanionService _aiService;
  bool _isLoading = true;
  List<ChatConversation>? _conversations;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _aiService = Provider.of<AICompanionService>(context, listen: false);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await _aiService.getConversations();
      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading conversations: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewConversation() async {
    try {
      final newConversation = await _aiService.createConversation();
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AICompanionScreen(
              conversationId: newConversation.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating conversation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteConversation(String id) async {
    try {
      await _aiService.deleteConversation(id);
      _loadConversations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Conversations',
            titleIcon: Icons.forum_rounded,
            showBackButton: true,
          ),
          Expanded(
            child: SafeArea(
              top: false, // Already handled by AppHeader
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!),
                        )
                      : _buildConversationList(colorScheme, isDarkMode),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          final isDarkMode = themeService.isDarkMode;
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: isDarkMode ? themeService.darkGradient : themeService.lightGradient,
                radius: 1.0,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: themeService.primary.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _createNewConversation,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationList(ColorScheme colorScheme, bool isDarkMode) {
    if (_conversations == null || _conversations!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No conversations yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new conversation with your AI companion!',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _conversations!.length,
      itemBuilder: (context, index) {
        final conversation = _conversations![index];
        return _buildConversationCard(conversation, colorScheme, isDarkMode);
      },
    );
  }

  Widget _buildConversationCard(ChatConversation conversation, ColorScheme colorScheme, bool isDarkMode) {
    // Get last message preview
    final lastMessagePreview = conversation.lastMessagePreview;
    
    // Format the date for display
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(
      conversation.updatedAt.year,
      conversation.updatedAt.month,
      conversation.updatedAt.day,
    );
    
    String formattedDate;
    if (date == today) {
      // Today - show time
      final hour = conversation.updatedAt.hour;
      final minute = conversation.updatedAt.minute;
      final period = hour < 12 ? 'AM' : 'PM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      formattedDate = '$hour12:${minute.toString().padLeft(2, '0')} $period';
    } else if (date == today.subtract(const Duration(days: 1))) {
      // Yesterday
      formattedDate = 'Yesterday';
    } else {
      // Other days - show date
      formattedDate = '${conversation.updatedAt.month}/${conversation.updatedAt.day}/${conversation.updatedAt.year}';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AICompanionScreen(
                conversationId: conversation.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colorScheme.primary,
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
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessagePreview,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDarkMode ? const Color(0xFF383844) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        'Delete Conversation',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to delete this conversation?',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    _deleteConversation(conversation.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 