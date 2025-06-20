import 'dart:io'; // For SocketException
import 'dart:async'; // For TimeoutException

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import '../env.dart'; // Import the Env class
import 'package:uuid/uuid.dart';

enum AIModel {
  mistral, // Default model
  gemini,
  custom
}

class AICompanionService extends ChangeNotifier {
  static const String _customApiKeyKey = 'custom_api_key';
  static const String _customModelEndpointKey = 'custom_model_endpoint';
  static const String _selectedModelKey = 'selected_ai_model';
  static const String _conversationsKey = 'chat_conversations';
  
  // API endpoints
  static const String _mistralApiEndpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const String _geminiApiEndpoint = 'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent';
  
  AIModel _selectedModel = AIModel.mistral;
  String? _customApiKey;
  String? _customModelEndpoint;
  List<ChatConversation> _conversations = [];
  bool _isInitialized = false;

  AIModel get selectedModel => _selectedModel;
  String? get customApiKey => _customApiKey;
  String? get customModelEndpoint => _customModelEndpoint;
  List<ChatConversation> get conversations => [..._conversations];

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load selected model
    final selectedModelIndex = prefs.getInt(_selectedModelKey);
    if (selectedModelIndex != null) {
      _selectedModel = AIModel.values[selectedModelIndex];
    }
    
    // Load custom model settings
    _customApiKey = prefs.getString(_customApiKeyKey);
    _customModelEndpoint = prefs.getString(_customModelEndpointKey);
    
    // Load conversations
    final conversationsJson = prefs.getStringList(_conversationsKey);
    if (conversationsJson != null) {
      try {
        _conversations = conversationsJson
            .map((json) => ChatConversation.fromJson(json))
            .toList();
      } catch (e) {
        debugPrint('Error parsing conversations: $e');
        _conversations = [];
      }
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setSelectedModel(AIModel model) async {
    _selectedModel = model;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedModelKey, model.index);
    
    notifyListeners();
  }

  Future<void> setCustomApiKey(String apiKey) async {
    _customApiKey = apiKey;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customApiKeyKey, apiKey);
    
    notifyListeners();
  }

  Future<void> setCustomModelEndpoint(String endpoint) async {
    _customModelEndpoint = endpoint;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customModelEndpointKey, endpoint);
    
    notifyListeners();
  }

  Future<List<ChatConversation>> getConversations() async {
    await initialize();
    return [..._conversations];
  }

  Future<ChatConversation?> getConversationById(String id) async {
    await initialize();
    try {
      return _conversations.firstWhere((conv) => conv.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<ChatConversation> createConversation() async {
    await initialize();
    
    final uuid = const Uuid().v4();
    final conversation = ChatConversation(
      id: uuid,
      title: 'New Conversation',
      createdAt: DateTime.now(),
      messages: [],
    );
    
    _conversations.add(conversation);
    await _saveConversations();
    
    return conversation;
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await initialize();
    
    final index = _conversations.indexWhere((conv) => conv.id == id);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(title: title);
      await _saveConversations();
    }
  }

  Future<void> deleteConversation(String id) async {
    await initialize();
    
    try {
      // Find the conversation first to make sure it exists
      final index = _conversations.indexWhere((conv) => conv.id == id);
      if (index != -1) {
        // Remove it from the list
        _conversations.removeAt(index);
        
        // Save the updated list to storage
    await _saveConversations();
    
        // Notify listeners about the change
    notifyListeners();
        debugPrint('✅ Conversation $id deleted successfully');
      } else {
        debugPrint('⚠️ Conversation $id not found for deletion');
      }
    } catch (e) {
      debugPrint('❌ Error deleting conversation $id: $e');
      rethrow;
    }
  }
  
  Future<void> clearAllConversations() async {
    await initialize();
    
    try {
      // Clear all conversations
    _conversations.clear();
      
      // Save the empty list to storage
    await _saveConversations();
    
      // Notify listeners about the change
    notifyListeners();
      debugPrint('✅ All conversations cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing all conversations: $e');
      rethrow;
    }
  }

  Future<void> sendMessageToAI(String conversationId, String message) async {
    await initialize();
    
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index == -1) {
      throw Exception('Conversation not found');
    }
    
    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    
    _conversations[index].messages.add(userMessage);
    await _saveConversations();
    
    // Generate AI response
    try {
      final aiResponse = await _generateAIResponse(conversationId, message);
      
      // Add AI message
      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        text: aiResponse,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      
      _conversations[index].messages.add(aiMessage);
      
      // If this is a new conversation with few messages, update the title based on the content
      if (_conversations[index].messages.length <= 3) {
        final title = aiResponse.split('.').first;
        // Limit title length
        final shortTitle = title.length > 30 
            ? "${title.substring(0, 30)}..." 
            : title;
        
        _conversations[index] = _conversations[index].copyWith(title: shortTitle);
      }
      
      await _saveConversations();
      
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        text: 'Sorry, I encountered an error: $e',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isError: true,
      );
      
      _conversations[index].messages.add(errorMessage);
      await _saveConversations();
      
      rethrow;
    }
  }

  Future<String> _generateAIResponse(String conversationId, String message) async {
    final conversation = await getConversationById(conversationId);
    if (conversation == null) {
      throw Exception('Conversation not found');
    }
    
    // Get the previous messages to maintain context
    final previousMessages = conversation.messages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      };
    }).toList();
    
    switch (_selectedModel) {
      case AIModel.mistral:
        return _generateMistralResponse(previousMessages, message);
      case AIModel.gemini:
        return _generateGeminiResponse(previousMessages, message);
      case AIModel.custom:
        return _generateCustomModelResponse(previousMessages, message);
    }
  }

  Future<String> _generateMistralResponse(List<Map<String, dynamic>> previousMessages, String message) async {
    try {
      final apiKey = Env.mistralApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Mistral API key not found. Please add it to your .env file.');
      }
      
      // Create chat context for Mistral format
      final messages = [...previousMessages];
      
      // Add the new user message
      messages.add({
        'role': 'user',
        'content': message,
      });
      
      // Add timeout and retry logic to handle network issues
      final client = http.Client();
      try {
        final response = await client.post(
          Uri.parse(_mistralApiEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': 'mistral-small-latest', // Using the free model
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 800,
          }),
        ).timeout(Duration(seconds: 20)); // Add 20 second timeout
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'] as String;
        } else {
          // Check if we have a connection issue
          if (response.statusCode >= 500 || (response.reasonPhrase?.contains('time') ?? false)) {
            throw Exception('Server connection issue. Please check your internet connection and try again later.');
          } else {
            throw Exception('Failed to generate response: ${response.statusCode} ${response.body}');
          }
        }
      } catch (e) {
        if (e is SocketException || e is TimeoutException) {
          throw Exception('Network connection error. Please check your internet connection and try again.');
        }
        rethrow;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error generating Mistral response: $e');
      rethrow;
    }
  }

  Future<String> _generateGeminiResponse(List<Map<String, dynamic>> previousMessages, String message) async {
    try {
      final apiKey = Env.geminiApiKey;
      if (apiKey.isEmpty) {
        throw Exception('Gemini API key not found. Please add it to your .env file.');
      }
      
      // Format prompt with context from previous messages
      final promptContext = previousMessages.map((msg) {
        final role = msg['role'] == 'user' ? 'User' : 'Assistant';
        return '$role: ${msg['content']}';
      }).join('\n');
      
      final promptWithContext = promptContext.isEmpty 
          ? message 
          : '$promptContext\nUser: $message\nAssistant:';
      
      final response = await http.post(
        Uri.parse('$_geminiApiEndpoint?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': promptWithContext,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
            'topK': 40,
            'topP': 0.95,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        throw Exception('Failed to generate response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating Gemini response: $e');
      rethrow;
    }
  }

  Future<String> _generateCustomModelResponse(List<Map<String, dynamic>> previousMessages, String message) async {
    try {
      if (_customApiKey == null || _customApiKey!.isEmpty) {
        throw Exception('Custom API key not set');
      }
      
      if (_customModelEndpoint == null || _customModelEndpoint!.isEmpty) {
        throw Exception('Custom model endpoint not set');
      }
      
      // For custom models, we'll assume a similar format to Mistral/OpenAI
      final messages = [...previousMessages];
      
      // Add the new user message
      messages.add({
        'role': 'user',
        'content': message,
      });
      
      final response = await http.post(
        Uri.parse(_customModelEndpoint!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_customApiKey',
        },
        body: jsonEncode({
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Try to extract response based on common API formats
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          if (data['choices'][0]['message'] != null) {
            return data['choices'][0]['message']['content'] as String;
          } else if (data['choices'][0]['text'] != null) {
            return data['choices'][0]['text'] as String;
          }
        } else if (data['response'] != null) {
          return data['response'] as String;
        } else if (data['output'] != null) {
          return data['output'] as String;
        } else if (data['result'] != null) {
          return data['result'] as String;
        }
        
        throw Exception('Could not parse response format: ${response.body}');
      } else {
        throw Exception('Failed to generate response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating custom model response: $e');
      rethrow;
    }
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    
    final conversationsJson = _conversations
        .map((conv) => conv.toJson())
        .toList();
    
    await prefs.setStringList(_conversationsKey, conversationsJson);
    notifyListeners();
  }
  
  // Add method to reload conversations from storage
  Future<void> loadConversations() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    
    // Load conversations
    final conversationsJson = prefs.getStringList(_conversationsKey);
    if (conversationsJson != null) {
      try {
        _conversations = conversationsJson
            .map((json) => ChatConversation.fromJson(json))
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing conversations: $e');
        _conversations = [];
      }
    }
  }
} 