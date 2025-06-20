import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:markdown/markdown.dart' as md;
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
                              fontSize: 16,
                            ),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            builders: {
                              'code': SyntaxHighlightBuilder(isDarkMode: isDarkMode),
                            },
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                              a: TextStyle(
                                color: textColor, // Link color
                                fontSize: 16,
                              ),
                              tableHead: TextStyle(
                                color: textColor, // Table header color
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              tableBody: TextStyle(
                                color: textColor, // Table body color
                                fontSize: 16,
                              ),
                              strong: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              em: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                              code: TextStyle(
                                color: isDarkMode 
                                    ? const Color(0xFF9CDCFE)  // VS Code blue for variables
                                    : const Color(0xFF0451A5), // VS Code dark blue
                                fontSize: 14,
                                fontFamily: 'monospace',
                                backgroundColor: isDarkMode 
                                    ? const Color(0xFF1E1E1E)  // VS Code dark background
                                    : const Color(0xFFF8F8F8), // VS Code light background
                              ),
                              codeblockDecoration: const BoxDecoration(
                                color: Colors.transparent, // Remove background to prevent double containers
                                borderRadius: BorderRadius.zero, // Remove border radius
                              ),
                              listBullet: TextStyle(
                                color: textColor,
                                fontSize: 16,
                              ),
                              h1: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              h2: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              h3: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              h4: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              h5: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              h6: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
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
                    const SnackBar(content: Text('Message copied to clipboard')),
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

// Custom syntax highlight builder for code blocks with VS Code colors
class SyntaxHighlightBuilder extends MarkdownElementBuilder {
  final bool isDarkMode;
  
  SyntaxHighlightBuilder({required this.isDarkMode});
  
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String language = element.attributes['class']?.replaceFirst('language-', '') ?? 'text';
    final String code = element.textContent;
    
    if (element.tag == 'code') {
      // Check if it's likely a multi-line code block (longer text or contains newlines)
      bool isCodeBlock = code.contains('\n') || code.length > 30;
      
      if (isCodeBlock) {
        // Multi-line code block with colorful VS Code syntax highlighting
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode 
                      ? const Color(0xFF1C1C1E)  // Darker background for dark mode
                      : const Color(0xFFF8F8F8), // Light background for light mode
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode 
                        ? const Color(0xFF3C3C3C)  // Dark border for dark mode
                        : const Color(0xFFE1E4E8), // Light border for light mode
                    width: 1,
                  ),
                ),
                child: HighlightView(
                  code,
                  language: _getLanguage(language),
                  theme: isDarkMode ? _getDarkCodeTheme() : vsTheme, // Use custom dark theme
                  padding: EdgeInsets.zero,
                  textStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87, // Ensure text is visible
                  ),
                ),
              ),
              // Copy button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _copyToClipboard(code),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Inline code with VS Code styling
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF1C1C1E)  // Darker background for dark mode
                : const Color(0xFFF0F0F0), // Light background for light mode
            borderRadius: BorderRadius.circular(4),
          ),
          child: HighlightView(
            code,
            language: _getLanguage(language),
            theme: isDarkMode ? _getDarkCodeTheme() : vsTheme, // Use custom dark theme
            padding: EdgeInsets.zero,
            textStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87, // Ensure text is visible
            ),
          ),
        );
      }
    }
    
    return null;
  }
  
  String _getLanguage(String lang) {
    // Map common language names to highlight.js supported names
    final languageMap = {
      'js': 'javascript',
      'ts': 'typescript',
      'py': 'python',
      'rb': 'ruby',
      'sh': 'bash',
      'yml': 'yaml',
      'md': 'markdown',
    };
    
    return languageMap[lang.toLowerCase()] ?? lang.toLowerCase();
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
  
  Map<String, TextStyle> _getDarkCodeTheme() {
    // Custom dark theme with white text for all elements
    return {
      'root': const TextStyle(
        backgroundColor: Color(0x00000000),
        color: Colors.white, // Force white text
      ),
      'comment': const TextStyle(color: Color(0xFF6A9955)), // Green comments
      'keyword': const TextStyle(color: Color(0xFF569CD6)), // Blue keywords
      'string': const TextStyle(color: Color(0xFFCE9178)), // Orange strings
      'number': const TextStyle(color: Color(0xFFB5CEA8)), // Light green numbers
      'function': const TextStyle(color: Color(0xFFDCDCAA)), // Yellow functions
      'class': const TextStyle(color: Color(0xFF4EC9B0)), // Teal classes
      'variable': const TextStyle(color: Color(0xFF9CDCFE)), // Light blue variables
      'property': const TextStyle(color: Color(0xFF9CDCFE)), // Light blue properties
      'operator': const TextStyle(color: Colors.white), // White operators
      'punctuation': const TextStyle(color: Colors.white), // White punctuation
      'tag': const TextStyle(color: Color(0xFF569CD6)), // Blue tags
      'attribute': const TextStyle(color: Color(0xFF92C5F8)), // Light blue attributes
      'selector': const TextStyle(color: Color(0xFFD7BA7D)), // Yellow selectors
      'title': const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White titles
      'type': const TextStyle(color: Color(0xFF4EC9B0)), // Teal types
      'literal': const TextStyle(color: Color(0xFFB5CEA8)), // Light green literals
      'built_in': const TextStyle(color: Color(0xFF569CD6)), // Blue built-ins
      'bullet': const TextStyle(color: Colors.white), // White bullets
      'code': const TextStyle(color: Colors.white), // White default code
      'emphasis': const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
      'strong': const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      'formula': const TextStyle(color: Colors.white),
      'link': const TextStyle(color: Color(0xFF569CD6)),
      'quote': const TextStyle(color: Color(0xFF6A9955)),
      'doctag': const TextStyle(color: Color(0xFF569CD6)),
      'meta': const TextStyle(color: Color(0xFF569CD6)),
      'name': const TextStyle(color: Colors.white),
      'symbol': const TextStyle(color: Colors.white),
      'section': const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      'addition': const TextStyle(color: Color(0xFF4EC9B0)),
      'deletion': const TextStyle(color: Color(0xFFF44747)),
    };
  }
}