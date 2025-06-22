import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message_model.dart';
import '../services/ai_companion_service.dart';
import '../services/theme_service.dart';
import '../services/skeleton_service.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/app_header.dart';
import '../widgets/main_layout.dart';
import 'conversation_list_screen.dart';
import '../widgets/m3_button.dart';
import '../widgets/chat_message_bubble.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import '../models/user_model.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_gradient_background.dart';

class AICompanionScreen extends StatefulWidget {
  final String? conversationId;
  
  // Static properties to maintain conversation state across tab switches
  static ChatConversation? _savedConversation;
  static String? _savedConversationId;

  const AICompanionScreen({
    Key? key,
    this.conversationId,
  }) : super(key: key);

  @override
  State<AICompanionScreen> createState() => _AICompanionScreenState();
}

class _AICompanionScreenState extends State<AICompanionScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AICompanionService _aiService;
  ChatConversation? _currentConversation;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentConversationId;
  bool _isSendingMessage = false;
  final FocusNode _messageFocusNode = FocusNode();
  
  // Keep this widget alive when switching tabs
  @override
  bool get wantKeepAlive => true;
  
  final List<String> _suggestedPrompts = [
    "Tell me an interesting fact",
    "Write a short poem about flowers",
    "How can I improve my productivity?",
    "Tell me about a good book to read",
  ];

  // Typing indicator state
  bool _isAITyping = false;
  // Track keyboard visibility manually
  bool _isKeyboardVisible = false;
  double _keyboardHeight = 0.0;
  double _inputContainerHeight = 56.0; // Increased container height

  @override
  void initState() {
    super.initState();
    _aiService = Provider.of<AICompanionService>(context, listen: false);
    
    // Use the saved conversation if available, otherwise initialize a new one
    if (AICompanionScreen._savedConversation != null) {
      _currentConversation = AICompanionScreen._savedConversation;
      _currentConversationId = AICompanionScreen._savedConversationId;
      _isLoading = false;
    } else {
      _initializeConversation();
    }
    
    // Add listener to scroll messages into view when keyboard appears
    _messageFocusNode.addListener(_onFocusChange);

    // Initialize keyboard visibility tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addKeyboardVisibilityListener();
    });
  }

  void _onFocusChange() {
    if (_messageFocusNode.hasFocus) {
      // When the text field gets focus, scroll to bottom
      _scrollToBottom();
    }
  }

  void _addKeyboardVisibilityListener() {
    // Use MediaQuery for keyboard detection
    WidgetsBinding.instance.addObserver(_KeyboardVisibilityObserver(this));
  }
  
  void updateKeyboardVisibility(bool visible, double height) {
    if (mounted && (_isKeyboardVisible != visible || _keyboardHeight != height)) {
      setState(() {
        _isKeyboardVisible = visible;
        _keyboardHeight = height;
      });
      
      if (visible) {
        _scrollToBottom();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(_KeyboardVisibilityObserver(this));
    super.dispose();
  }

  Future<void> _initializeConversation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If there's a specific conversation ID in the widget's parameters, use that
      if (widget.conversationId != null && widget.conversationId != _currentConversationId) {
        // Load specific conversation by ID
        final conversation = await _aiService.getConversationById(widget.conversationId!);
        
        if (conversation != null) {
          setState(() {
            _currentConversation = conversation;
            _currentConversationId = widget.conversationId;
            
            // Save the conversation to the static property
            AICompanionScreen._savedConversation = conversation;
            AICompanionScreen._savedConversationId = widget.conversationId;
          });
        } else {
          // If conversation not found, check if we already have one
          if (_currentConversation == null) {
            // Only create a new one if we don't have any
            final newConversation = await _aiService.createConversation();
            setState(() {
              _currentConversation = newConversation;
              _currentConversationId = newConversation.id;
              
              // Save the conversation to the static property
              AICompanionScreen._savedConversation = newConversation;
              AICompanionScreen._savedConversationId = newConversation.id;
            });
          }
        }
      } 
      // If no specific conversation ID and we don't have one yet, create new
      else if (_currentConversation == null) {
        // Check if there are any existing conversations we could load
        final conversations = await _aiService.getConversations();
        if (conversations.isNotEmpty) {
          // Use the most recent conversation
          final mostRecent = conversations.reduce((a, b) => 
            a.updatedAt.isAfter(b.updatedAt) ? a : b);
          
          setState(() {
            _currentConversation = mostRecent;
            _currentConversationId = mostRecent.id;
            
            // Save the conversation to the static property
            AICompanionScreen._savedConversation = mostRecent;
            AICompanionScreen._savedConversationId = mostRecent.id;
          });
        } else {
          // Create a new conversation if no existing ones
          final newConversation = await _aiService.createConversation();
          setState(() {
            _currentConversation = newConversation;
            _currentConversationId = newConversation.id;
            
            // Save the conversation to the static property
            AICompanionScreen._savedConversation = newConversation;
            AICompanionScreen._savedConversationId = newConversation.id;
          });
        }
      }
      
      // Ensure we have the latest conversations list 
      // But don't update our current conversation to avoid recreating
      await _aiService.loadConversations();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading conversation: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // If conversation is loaded, scroll to bottom
        if (_currentConversation != null && _currentConversation!.messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentConversationId == null) return;
    
    // Clear the input field
    _messageController.clear();
    
    // Create a local copy of the current conversation to avoid full rebuilds
    final currentConversation = _currentConversation;
    if (currentConversation == null) return;
    
    // Add the user message with animation
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    // Create an updated conversation with the new message
    final updatedConversation = currentConversation.addMessage(userMessage);
    
    // Update UI in a single setState call to prevent flickering
    setState(() {
      _currentConversation = updatedConversation;
      _isAITyping = true;
      
      // Update the static saved conversation
      AICompanionScreen._savedConversation = updatedConversation;
    });
    
    // Scroll to bottom after adding user message
    _scrollToBottom();
    
    try {
      // Send message to AI
      await _aiService.sendMessageToAI(
        _currentConversationId!,
        message,
      );
      
      // Only fetch the updated conversation once to minimize rebuilds
      final latestConversation = await _aiService.getConversationById(_currentConversationId!);
      
      // Only update if we have a valid response and component is still mounted
      if (latestConversation != null && mounted) {
        // Single setState call for updating conversation and removing typing indicator
        setState(() {
          _currentConversation = latestConversation;
          _isAITyping = false;
          
          // Update the static saved conversation
          AICompanionScreen._savedConversation = latestConversation;
        });
        
        // Scroll to bottom after receiving AI message
        _scrollToBottom();
      }
    } catch (e) {
      // Only remove typing indicator on error if component is still mounted
      if (mounted) {
        setState(() {
          _isAITyping = false;
        });
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    // Use a shorter delay when keyboard is visible for better responsiveness
    final delay = _isKeyboardVisible ? 50 : 100;
    
    Future.delayed(Duration(milliseconds: delay), () {
      if (_scrollController.hasClients) {
        // Calculate if we're already at the bottom to determine animation duration
        final position = _scrollController.position;
        final isNearBottom = position.pixels > (position.maxScrollExtent - 150);
        final isVeryNearBottom = position.pixels > (position.maxScrollExtent - 50);

        // Use different animation durations based on how close we are to the bottom
        // This makes keyboard appearance feel more responsive
        final duration = isVeryNearBottom 
            ? 100
            : isNearBottom 
                ? 200 
                : 300;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: duration),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<void> _showConversationsDialog() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDarkMode = themeService.isDarkMode;
    final userModel = Provider.of<UserModel>(context, listen: false);
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ConversationsDialog(
        aiService: _aiService,
        currentConversationId: _currentConversationId,
        isDarkMode: isDarkMode,
        userModel: userModel,
      ),
    );
    
    if (result != null) {
      final action = result['action'];
      
      if (action == 'select_conversation') {
        final conversationId = result['conversation_id'];
        if (conversationId != null && conversationId != _currentConversationId) {
          setState(() {
            _isLoading = true;
            _currentConversationId = conversationId;
          });
          
          try {
            // Get the full conversation content first
            final selectedConversation = await _aiService.getConversationById(conversationId);
            if (selectedConversation != null && mounted) {
              setState(() {
                _currentConversation = selectedConversation;
                _isLoading = false;
                
                // Update the static saved conversation only after successfully loading the content
                AICompanionScreen._savedConversation = selectedConversation;
                AICompanionScreen._savedConversationId = conversationId;
              });
              
              // Scroll to bottom after loading conversation
              _scrollToBottom();
            } else if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Unable to load selected conversation';
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error loading conversation: $e';
              });
            }
          }
        }
      } else if (action == 'new_conversation') {
        setState(() {
          _isLoading = true;
        });
        
        try {
          final newConversation = await _aiService.createConversation();
          
          if (mounted) {
            setState(() {
              _currentConversation = newConversation;
              _currentConversationId = newConversation.id;
              _isLoading = false;
              
              // Update the static saved conversation
              AICompanionScreen._savedConversation = newConversation;
              AICompanionScreen._savedConversationId = newConversation.id;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error creating new conversation: $e';
            });
          }
        }
      } else if (action == 'clear_conversation') {
        _handleClearConversation();
      } else if (action == 'clear_all_conversations') {
        _handleClearAllConversations();
      } else if (action == 'delete_conversation') {
        final conversationId = result['conversation_id'];
        if (conversationId != null) {
          await _handleDeleteConversation(conversationId);
        }
      }
    }
  }
  
  Future<void> _handleClearConversation() async {
    if (_currentConversationId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Store the ID to delete
      final String idToDelete = _currentConversationId!;
      
      // Create a new conversation first before deleting
      final newConversation = await _aiService.createConversation();
      
      // Update the UI with the new conversation
      setState(() {
        _currentConversation = newConversation;
        _currentConversationId = newConversation.id;
        
        // Update the static saved conversation
        AICompanionScreen._savedConversation = newConversation;
        AICompanionScreen._savedConversationId = newConversation.id;
      });
      
      // Now delete the old conversation
      await _aiService.deleteConversation(idToDelete);
      
      // Reload conversations list
      await _aiService.loadConversations();
      
      // Show confirmation
      if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Conversation cleared'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error clearing conversation: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _handleClearAllConversations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create a new conversation first 
      final newConversation = await _aiService.createConversation();
      
      // Update the UI with the new conversation
      setState(() {
        _currentConversation = newConversation;
        _currentConversationId = newConversation.id;
        
        // Update the static saved conversation
        AICompanionScreen._savedConversation = newConversation;
        AICompanionScreen._savedConversationId = newConversation.id;
      });
      
      // Clear all conversations
      await _aiService.clearAllConversations();
      
      // Show confirmation
      if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('All conversations cleared'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error clearing conversations: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDeleteConversation(String conversationId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // If we're deleting the current conversation, create a new one first
      if (conversationId == _currentConversationId) {
        final newConversation = await _aiService.createConversation();
        
        // Update the UI with the new conversation
        setState(() {
          _currentConversation = newConversation;
          _currentConversationId = newConversation.id;
          
          // Update the static saved conversation
          AICompanionScreen._savedConversation = newConversation;
          AICompanionScreen._savedConversationId = newConversation.id;
        });
      }

      // Delete the conversation from the service
      await _aiService.deleteConversation(conversationId);
      
      // Force refresh the conversations list
      await _aiService.loadConversations();
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conversation deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonService = Provider.of<SkeletonService>(context);
    final userModel = Provider.of<UserModel>(context);
    
    // Get keyboard height to adjust positioning
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    
    // Update the keyboard state
    if (isKeyboardVisible != _isKeyboardVisible || keyboardHeight != _keyboardHeight) {
      // Schedule a microtask to avoid setState during build
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _isKeyboardVisible = isKeyboardVisible;
            _keyboardHeight = keyboardHeight;
          });
        }
      });
    }
    
    return Stack(
            children: [
        // WaveDotGrid animated background that extends behind navigation bars
        const Positioned.fill(
          child: ChatAnimatedBackground(),
        ),
        // Main content with padding for navigation bars
        SafeArea(
          bottom: false, // Don't apply bottom safe area to allow keyboard overlay
                              child: Column(
                                children: [
              // Main content area - fills all available space
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!))
                          : _buildChatBody(colorScheme, isDarkMode, userModel),
                ),
              ),
              
              // Input field area with minimal spacing
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom), // Add bottom margin for safe area
                padding: EdgeInsets.only(
                  left: 8.0, 
                  right: 8.0, 
                  bottom: isKeyboardVisible ? 8.0 : 16.0, // Ensure some bottom padding
                  top: 8.0, // Increased top padding for better spacing
                ),
                child: Row(
                  children: [
                    // Expanded text input with rounded corners
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor.withOpacity(0.8),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24.0),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    
                    // Send button next to text field
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _isAITyping ? null : _sendMessage,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0.0, 0.0),
                                radius: 0.8,
                                colors: isDarkMode 
                                  ? themeService.darkGradient
                                  : themeService.lightGradient,
                                stops: const [0.0, 1.0],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
                ],
          ),
              ),
              
        // Hamburger menu button positioned in top-left corner
              Positioned(
                top: 16,
                left: 16,
          child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.0),
                      radius: 0.8,
                      colors: isDarkMode 
                    ? themeService.darkGradient
                    : themeService.lightGradient,
                      stops: const [0.0, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                  onTap: () => _showConversationsDialog(),
                      child: Container(
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ),
      ],
    );
  }

  Widget _buildChatBody(ColorScheme colorScheme, bool isDarkMode, UserModel userModel) {
    return Consumer<AICompanionService>(
      builder: (context, aiService, child) {
        // If we already have a conversation loaded, use it directly
        // This prevents unnecessary loading states when switching tabs
        if (_currentConversation != null) {
          final conversation = _currentConversation!;
          final messages = conversation.messages;
          
          // If no messages, show welcome message
          if (messages.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    color: isDarkMode 
                        ? const Color(0xFF2A2A3C).withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                  child: Column(
                        mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                        Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: colorScheme.primary,
                      ),
                          ),
                          const SizedBox(height: 24),
                      Text(
                        'Welcome to your AI Companion!',
                        style: TextStyle(
                              fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                          const SizedBox(height: 12),
                      Text(
                        'Start a conversation by typing a message below.',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                          const SizedBox(height: 16),
                      Text(
                        'You can ask me anything, and I\'ll do my best to help! 💖',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 12.0,
              bottom: _isKeyboardVisible ? 16.0 : 6.0, // Add more bottom padding when keyboard is visible
            ),
            itemCount: messages.length + (_isAITyping ? 1 : 0),
            itemBuilder: (context, index) {
              // Show typing indicator as the last item if AI is typing
              if (_isAITyping && index == messages.length) {
                return _buildTypingIndicator(colorScheme, isDarkMode);
              }
              
              final message = messages[index];
              // Stagger animation for smoother appearance
              return AnimatedMessage(
                message: message,
                isLastMessage: index == messages.length - 1 && !_isAITyping,
                colorScheme: colorScheme,
                isDarkMode: isDarkMode,
                userModel: userModel,
                isKeyboardVisible: _isKeyboardVisible
              );
            },
          );
        }
        
        // If we don't have a conversation yet, fall back to the FutureBuilder approach
        return FutureBuilder<ChatConversation?>(
          future: aiService.getConversationById(_currentConversationId ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            final conversation = snapshot.data;
            if (conversation == null) {
              return const Center(
                child: Text('Conversation not found'),
              );
            }
            
            // Store the conversation for future use
            _currentConversation = conversation;
            _currentConversationId = conversation.id;
            
            // Recursively call this method to use the optimized path
            return _buildChatBody(colorScheme, isDarkMode, userModel);
          },
        );
      },
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _isKeyboardVisible ? 4.0 : 6.0, // Reduce padding when keyboard is visible
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, // Slightly smaller
            height: 32, // Slightly smaller
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15), // Elegant opacity with primary color
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '🌸',
                style: TextStyle(
                  fontSize: 14, // Smaller font
                ),
              ),
            ),
          ),
          
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4.0),
              topRight: Radius.circular(20.0),
              bottomLeft: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: _isKeyboardVisible ? 8.0 : 12.0, // Reduce padding when keyboard is visible
              ),
            decoration: BoxDecoration(
                color: isDarkMode 
                    ? const Color(0xFF2C2C2E)  // Match AI bubble color in dark mode
                    : const Color(0xFFF5F5F7), // Match AI bubble color in light mode
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4.0),
                topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF3C3C3C)  // Dark border for dark mode
                    : const Color(0xFFE1E1E6), // Light border for light mode
                width: 1.0
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => AnimatedDot(delay: i * 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Conversation dialog that will replace the drawer
class ConversationsDialog extends StatelessWidget {
  final AICompanionService aiService;
  final String? currentConversationId;
  final bool isDarkMode;
  final UserModel userModel;
  
  const ConversationsDialog({
    Key? key,
    required this.aiService,
    required this.currentConversationId,
    required this.isDarkMode,
    required this.userModel,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dialogBackgroundColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    
    return AlertDialog(
      backgroundColor: dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(0),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.5),
                  radius: 1.5,
                  colors: themeService.lightGradient,
                  stops: const [0.0, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                    backgroundImage: userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty
                        ? FileImage(File(userModel.profileImagePath!))
                        : null,
                    child: (userModel.profileImagePath == null || userModel.profileImagePath!.isEmpty)
                        ? Icon(Icons.person, size: 24, color: themeService.primary)
                        : null,
                      ),
                      const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conversations',
                          style: const TextStyle(
                            fontSize: 20,
                          fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                        Text(
                          '${userModel.name}\'s chat history',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Recent conversations list
            Flexible(
              child: Consumer<AICompanionService>(
                builder: (context, aiCompanionService, child) {
                  return FutureBuilder<List<ChatConversation>>(
                    future: aiCompanionService.getConversations(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final conversations = snapshot.data ?? [];
                      
                      if (conversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: themeService.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No conversations yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a new conversation with your AI companion',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // Sort conversations by update time (newest first)
                      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
                      
                      // Get unique conversations only to prevent duplication
                      final uniqueConversations = <String, ChatConversation>{};
                      for (var conversation in conversations) {
                        uniqueConversations[conversation.id] = conversation;
                      }
                      
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: uniqueConversations.length,
                        itemBuilder: (context, index) {
                          final conversation = uniqueConversations.values.elementAt(index);
                          final isSelected = conversation.id == currentConversationId;
                          
                          // Format the date
                          final date = conversation.updatedAt;
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final conversationDate = DateTime(date.year, date.month, date.day);
                          
                          String formattedDate;
                          if (conversationDate == today) {
                            // Today, just show time
                            formattedDate = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                          } else {
                            // Other days, show date
                            formattedDate = '${date.month}/${date.day}';
                          }
                          
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: themeService.primary.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: themeService.primary.withOpacity(0.2),
                              child: const Text('🌸', style: TextStyle(fontSize: 16)),
                            ),
                            title: Text(
                              conversation.title.isEmpty ? 'Conversation ${index + 1}' : conversation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            subtitle: Text(
                              conversation.lastMessagePreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryTextColor,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: secondaryTextColor,
                                  ),
                                  onPressed: () {
                                    showDialog(
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
                                          'Are you sure you want to delete this conversation? This action cannot be undone.',
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'CANCEL',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context); // Close confirmation dialog
                                              Navigator.pop(context, { // Close main dialog
                                                'action': 'delete_conversation',
                                                'conversation_id': conversation.id,
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.red.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              'DELETE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context, {
                                'action': 'select_conversation',
                                'conversation_id': conversation.id,
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            
            // Action buttons at the bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF8F8F8),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  M3Button(
                    text: 'New Conversation',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.pop(context, {
                        'action': 'new_conversation',
                      });
                    },
                    isFullWidth: true,
                    buttonType: M3ButtonType.primary,
                  ),
                  const SizedBox(height: 12),
                  M3Button(
                    text: 'Clear Current Conversation',
                    icon: Icons.delete_outline,
                    onPressed: () {
                      Navigator.pop(context, {
                        'action': 'clear_conversation',
                      });
                    },
                    isFullWidth: true,
                    buttonType: M3ButtonType.secondary,
                  ),
                  const SizedBox(height: 12),
                  M3Button(
                    text: 'Clear All Conversations',
                    icon: Icons.delete_sweep_outlined,
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode ? const Color(0xFF383844) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Clear All Conversations',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete all conversations? This action cannot be undone.',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                    actions: [
                      TextButton(
                              onPressed: () => Navigator.pop(context),
                        child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                      ),
                      TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close confirmation dialog
                                Navigator.pop(context, { // Close main dialog
                                  'action': 'clear_all_conversations',
                                });
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'CLEAR ALL',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                  );
                },
                isFullWidth: true,
                    buttonType: M3ButtonType.tertiary,
              ),
                ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}

// Now add the AnimatedMessage classes at the top level, after the main class definition
class AnimatedMessage extends StatefulWidget {
  final ChatMessage message;
  final bool isLastMessage;
  final ColorScheme colorScheme;
  final bool isDarkMode;
  final UserModel userModel;
  final bool isKeyboardVisible;

  const AnimatedMessage({
    Key? key,
    required this.message,
    required this.isLastMessage,
    required this.colorScheme,
    required this.isDarkMode,
    required this.userModel,
    required this.isKeyboardVisible
  }) : super(key: key);

  @override
  State<AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<AnimatedMessage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 450), // Make animation slightly longer
      vsync: this,
    );

    // Create different animations based on sender
    final isUserMessage = widget.message.sender == MessageSender.user;
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuint,
      ),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Different slide animations for user vs AI messages
    _slideAnimation = Tween<Offset>(
      begin: isUserMessage ? const Offset(0.3, 0.0) : const Offset(-0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Only animate the last message for a better experience
    if (widget.isLastMessage) {
      // Add a very slight delay for AI messages to make the typing indicator visible first
      if (!isUserMessage) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      } else {
        _animationController.forward();
      }
    } else {
      _animationController.value = 1.0;  // Skip animation for older messages
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacityAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildMessageBubble(
                widget.message,
                widget.colorScheme,
                widget.isDarkMode,
                widget.userModel
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, ColorScheme colorScheme, bool isDarkMode, UserModel userModel) {
    final isUserMessage = message.sender == MessageSender.user;
    
    // Use completely solid colors with aesthetic colors for AI
    final bubbleColor = isUserMessage
        ? colorScheme.primary // User bubble uses primary color (solid)
        : isDarkMode 
            ? const Color(0xFF2C2C2E)  // Lighter gray for AI bubbles in dark mode
            : const Color(0xFFF5F5F7); // Light soft grey for AI bubbles in light mode
    
    final textColor = isUserMessage
        ? Colors.white
        : isDarkMode
            ? const Color(0xFFFFFFFF)  // White text for dark AI bubbles
            : const Color(0xFF2C2C2E); // Dark text for light AI bubbles
    
    // Time stamp formatting
    final timestamp = message.timestamp;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    String formattedTime;
    if (messageDate == today) {
      // Today, just show time
      formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days, show date and time
      formattedTime = '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
    
    // Adjust sizing based on keyboard visibility
    final avatarSize = widget.isKeyboardVisible ? 30.0 : 36.0;
    final bubblePadding = widget.isKeyboardVisible 
        ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: widget.isKeyboardVisible ? 4.0 : 6.0, // Less vertical padding when keyboard is visible
      ),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage)
            Container(
              width: avatarSize,
              height: avatarSize,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15), // Elegant opacity with primary color
                borderRadius: BorderRadius.circular(avatarSize / 2),
              ),
              child: Center(
                child: Text(
                  '🌸',
                  style: TextStyle(
                    fontSize: widget.isKeyboardVisible ? 14.0 : 16.0,
                  ),
                ),
              ),
            ),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: isUserMessage
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(4.0),
                          bottomLeft: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(4.0),
                          topRight: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                        ),
                  child: Container(
                    padding: bubblePadding,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      // Different border radius for user vs AI messages for modern look
                      borderRadius: isUserMessage
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(4.0),
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(4.0),
                              topRight: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            ),
                      border: !isUserMessage
                          ? Border.all(
                              color: isDarkMode 
                                  ? const Color(0xFF3C3C3C)  // Dark border for dark mode AI bubbles
                                  : const Color(0xFFE1E1E6), // Light border for light mode AI bubbles
                              width: 1.0
                            ) 
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.2)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: message.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: textColor,
                            ),
                          )
                        : isUserMessage
                            ? SelectableText(
                                message.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: widget.isKeyboardVisible ? 14.0 : 16.0,
                                ),
                              )
                            : SelectableText(
                                message.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: widget.isKeyboardVisible ? 14.0 : 16.0,
                                  height: 1.4,
                                ),
                              ),
                  ),
                ),
                
                // Timestamp below message - hide when keyboard is visible to save space
                if (!widget.isKeyboardVisible)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color ?? (widget.isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  ),
                )
              ],
            ),
          ),
          
          if (isUserMessage)
            Container(
              width: avatarSize,
              height: avatarSize,
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15), // Elegant opacity with primary color
                borderRadius: BorderRadius.circular(avatarSize / 2),
              ),
              child: userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: FileImage(File(userModel.profileImagePath!)),
                    radius: avatarSize / 2,
                  )
                : Center(
                    child: Text(
                      '👤',
                      style: TextStyle(
                        fontSize: widget.isKeyboardVisible ? 14.0 : 16.0,
                      ),
                    ),
                  ),
            ),
        ],
      ),
    );
  }
}

// Animated dot for the typing indicator
class AnimatedDot extends StatefulWidget {
  final double delay;
  
  const AnimatedDot({Key? key, required this.delay}) : super(key: key);
  
  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    // Add delay before starting
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
            child: Container(
              width: 8,
              height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.white  // White dots in dark mode for visibility
                    : const Color(0xFFD1D1D6), // Gray dots in light mode
                shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

// Add KeyboardVisibilityObserver class to detect keyboard changes
class _KeyboardVisibilityObserver extends WidgetsBindingObserver {
  final _AICompanionScreenState _state;
  
  _KeyboardVisibilityObserver(this._state);
  
  @override
  void didChangeMetrics() {
    final bottomInset = View.of(_state.context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0.0;
    _state.updateKeyboardVisibility(isKeyboardVisible, bottomInset);
  }
}