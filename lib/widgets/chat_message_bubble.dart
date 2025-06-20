import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';

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
    final bubbleColor = isUserMessage
        ? primaryColor.withOpacity(0.8)
        : isDarkMode
            ? const Color(0xFF2A2A3C)
            : const Color(0xFFF5F5F5);
    
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
              child: const Center(
                child: Text(
                  '👤',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 