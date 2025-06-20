import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/chat_message_model.dart';
import '../models/user_model.dart';

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
    final bubbleColor = isUserMessage
        ? primaryColor
        : isDarkMode
            ? const Color(0xFF383844)
            : Colors.white;
    
    final textColor = isUserMessage
        ? Colors.white
        : isDarkMode
            ? Colors.white
            : Colors.black87;
    
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
                color: primaryColor.withOpacity(0.2),
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
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(20.0),
                border: !isUserMessage && !isDarkMode 
                    ? Border.all(color: Colors.grey.shade200, width: 1) 
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
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
                  : SelectableText(
                      message.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
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
                color: primaryColor.withOpacity(0.2),
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
} 