import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

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
                        : _buildFormattedAIMessage(message.text, textColor),
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

  Widget _buildFormattedAIMessage(String text, Color textColor) {
    // Clean up HTML-like content that might come from AI responses
    String cleanedText = text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    
    final parts = _parseMessage(cleanedText);
    
    // If no parts were parsed correctly, fall back to simple text
    if (parts.isEmpty) {
      return SelectableText(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16.0,
          height: 1.4,
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) {
        switch (part.type) {
          case MessagePartType.title:
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                part.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            );
          case MessagePartType.subtitle:
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                part.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            );
          case MessagePartType.code:
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isDarkMode 
                        ? const Color(0xFF3C3C3C)
                        : const Color(0xFFE1E4E8),
                    width: 1.0,
                  ),
                ),
                child: HighlightView(
                  part.content,
                  language: part.language ?? 'dart',
                  theme: isDarkMode ? vs2015Theme : githubTheme,
                  padding: EdgeInsets.zero,
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14.0,
                    height: 1.4,
                  ),
                ),
              ),
            );
          case MessagePartType.inlineCode:
            return Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: part.content,
                    style: TextStyle(
                      color: isDarkMode ? const Color(0xFFE06C75) : const Color(0xFFD73A49),
                      fontFamily: 'monospace',
                      fontSize: 15.0,
                      backgroundColor: isDarkMode 
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF3F4F6),
                    ),
                  ),
                ],
              ),
            );
          case MessagePartType.bulletPoint:
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      part.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          case MessagePartType.numberedPoint:
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${part.number}. ',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      part.content,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.0,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          case MessagePartType.text:
          default:
            return part.content.trim().isEmpty 
                ? const SizedBox(height: 8.0)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: _buildRichText(part.content, textColor),
                  );
        }
      }).toList(),
    );
  }

  List<MessagePart> _parseMessage(String text) {
    final parts = <MessagePart>[];
    final lines = text.split('\n');
    
    String? currentCodeBlock;
    String? currentLanguage;
    bool inCodeBlock = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Handle code blocks - check for both ``` and ``` with language
      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block
          if (currentCodeBlock != null && currentCodeBlock.isNotEmpty) {
            parts.add(MessagePart(
              type: MessagePartType.code,
              content: currentCodeBlock.trim(),
              language: currentLanguage,
            ));
          }
          currentCodeBlock = null;
          currentLanguage = null;
          inCodeBlock = false;
        } else {
          // Start of code block
          final trimmedLine = line.trim();
          currentLanguage = trimmedLine.length > 3 ? trimmedLine.substring(3).trim() : 'dart';
          if (currentLanguage!.isEmpty) currentLanguage = 'dart';
          currentCodeBlock = '';
          inCodeBlock = true;
        }
        continue;
      }
      
      if (inCodeBlock) {
        currentCodeBlock = (currentCodeBlock ?? '') + line + '\n';
        continue;
      }
      
      // Handle titles and subtitles - check for exact patterns
      if (line.trim().startsWith('### ')) {
        parts.add(MessagePart(
          type: MessagePartType.subtitle,
          content: line.trim().substring(4).trim(),
        ));
      } else if (line.trim().startsWith('## ')) {
        parts.add(MessagePart(
          type: MessagePartType.subtitle,
          content: line.trim().substring(3).trim(),
        ));
      } else if (line.trim().startsWith('# ')) {
        parts.add(MessagePart(
          type: MessagePartType.title,
          content: line.trim().substring(2).trim(),
        ));
      }
      // Handle bullet points
      else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        final cleanLine = line.trim();
        parts.add(MessagePart(
          type: MessagePartType.bulletPoint,
          content: cleanLine.substring(2).trim(),
        ));
      }
      // Handle numbered lists
      else if (RegExp(r'^\s*\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\s*(\d+)\.\s(.*)').firstMatch(line);
        if (match != null) {
          parts.add(MessagePart(
            type: MessagePartType.numberedPoint,
            content: match.group(2)!,
            number: int.parse(match.group(1)!),
          ));
        }
      }
      // Handle regular text - process for inline formatting
      else if (line.trim().isNotEmpty) {
        final processedContent = _processInlineFormatting(line);
        parts.add(MessagePart(
          type: MessagePartType.text,
          content: processedContent,
        ));
      }
      // Handle empty lines as spacing
      else {
        parts.add(MessagePart(
          type: MessagePartType.text,
          content: '',
        ));
      }
    }
    
    // Handle any remaining code block
    if (inCodeBlock && currentCodeBlock != null && currentCodeBlock.isNotEmpty) {
      parts.add(MessagePart(
        type: MessagePartType.code,
        content: currentCodeBlock.trim(),
        language: currentLanguage,
      ));
    }
    
    return parts;
  }

  String _processInlineFormatting(String text) {
    // Keep the original text for rich text processing
    return text;
  }

  Widget _buildRichText(String text, Color textColor) {
    final spans = <TextSpan>[];
    final buffer = StringBuffer();
    int i = 0;
    
    while (i < text.length) {
      // Check for inline code `code`
      if (text[i] == '`') {
        // Add any buffered text first
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 16.0,
              height: 1.4,
            ),
          ));
          buffer.clear();
        }
        
        // Find the closing backtick
        int endIndex = text.indexOf('`', i + 1);
        if (endIndex != -1) {
          final codeText = text.substring(i + 1, endIndex);
          spans.add(TextSpan(
            text: codeText,
            style: TextStyle(
              color: isDarkMode ? const Color(0xFFE06C75) : const Color(0xFFD73A49),
              fontFamily: 'monospace',
              fontSize: 15.0,
              backgroundColor: isDarkMode 
                  ? const Color(0xFF2D2D2D)
                  : const Color(0xFFF3F4F6),
              height: 1.4,
            ),
          ));
          i = endIndex + 1;
          continue;
        }
      }
      
      // Check for bold **text**
      else if (i < text.length - 1 && text.substring(i, i + 2) == '**') {
        // Add any buffered text first
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: TextStyle(
              color: textColor,
              fontSize: 16.0,
              height: 1.4,
            ),
          ));
          buffer.clear();
        }
        
        // Find the closing **
        int endIndex = text.indexOf('**', i + 2);
        if (endIndex != -1) {
          final boldText = text.substring(i + 2, endIndex);
          spans.add(TextSpan(
            text: boldText,
            style: TextStyle(
              color: textColor,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ));
          i = endIndex + 2;
          continue;
        }
      }
      
      // Regular character
      buffer.write(text[i]);
      i++;
    }
    
    // Add any remaining buffered text
    if (buffer.isNotEmpty) {
      spans.add(TextSpan(
        text: buffer.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 16.0,
          height: 1.4,
        ),
      ));
    }
    
    return SelectableText.rich(
      TextSpan(children: spans),
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

enum MessagePartType {
  text,
  title,
  subtitle,
  code,
  inlineCode,
  bulletPoint,
  numberedPoint,
}

class MessagePart {
  final MessagePartType type;
  final String content;
  final String? language;
  final int? number;

  MessagePart({
    required this.type,
    required this.content,
    this.language,
    this.number,
  });
}