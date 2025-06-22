import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/chat_message_model.dart';
import '../services/theme_service.dart';
import '../models/user_model.dart';
import 'dart:io';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDarkMode;
  final Color primaryColor;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == MessageSender.user;
    final userModel = Provider.of<UserModel>(context);
    final theme = Theme.of(context);
    
    // Use completely solid colors with aesthetic soft grey for AI
    final bubbleColor = isUserMessage
        ? primaryColor
        : isDarkMode 
            ? const Color(0xFF2C2C2E)  // Lighter gray for AI bubbles in dark mode
            : const Color(0xFFF5F5F7); // Light soft grey for AI bubbles in light mode
    
    final textColor = isUserMessage
        ? Colors.white
        : isDarkMode
            ? const Color(0xFFFFFFFF)  // White text for dark AI bubbles
            : const Color(0xFF2C2C2E); // Dark text for light AI bubbles
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15), // Elegant opacity with primary color
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  '🌸',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showCopyMenu(context, message.text),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(20.0),
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
                              fontSize: 16.0,
                            ),
                          )
                        : SelectableText(
                            message.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16.0,
                              height: 1.4,
                            ),
                          ),
              ),
            ),
          ),
          
          if (isUserMessage)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 8.0),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15), // Elegant opacity with primary color
                borderRadius: BorderRadius.circular(18),
              ),
              child: ClipOval(
                child: userModel.profileImagePath != null && userModel.profileImagePath!.isNotEmpty
                    ? Image.file(
                        File(userModel.profileImagePath!),
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : '👤',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          userModel.name.isNotEmpty ? userModel.name[0].toUpperCase() : '👤',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _showCopyMenu(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Message'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Message copied to clipboard'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}