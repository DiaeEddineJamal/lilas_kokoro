import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

enum MessageSender {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;
  
  // Utility getter for isUser
  bool get isUser => sender == MessageSender.user;

  ChatMessage({
    String? id,
    required this.text,
    required this.sender,
    DateTime? timestamp,
    this.isLoading = false,
    this.isError = false,
  }) : 
    id = id ?? const Uuid().v4(),
    timestamp = timestamp ?? DateTime.now();
    
  // Alternate constructor with isUser parameter
  ChatMessage.withUserFlag({
    String? id,
    required this.text,
    required bool isUser,
    DateTime? timestamp,
    this.isLoading = false,
    this.isError = false,
  }) : 
    id = id ?? const Uuid().v4(),
    sender = isUser ? MessageSender.user : MessageSender.ai,
    timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sender': sender.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'isError': isError,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      text: map['text'] ?? '',
      sender: map['sender'] == 'MessageSender.ai' 
        ? MessageSender.ai 
        : MessageSender.user,
      timestamp: DateTime.parse(map['timestamp']),
      isLoading: map['isLoading'] ?? false,
      isError: map['isError'] ?? false,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    bool? isLoading,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}

class ChatConversation {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    title = title ?? 'New Conversation',
    messages = messages ?? [],
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'],
      title: map['title'] ?? 'New Conversation',
      messages: List<ChatMessage>.from(
        (map['messages'] ?? []).map((m) => ChatMessage.fromMap(m))
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
  
  // Convert to JSON string
  String toJson() {
    return json.encode(toMap());
  }
  
  // Create from JSON string
  factory ChatConversation.fromJson(String source) {
    return ChatConversation.fromMap(json.decode(source));
  }

  ChatConversation copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add a new message to the conversation
  ChatConversation addMessage(ChatMessage message) {
    final newMessages = List<ChatMessage>.from(messages);
    newMessages.add(message);
    return copyWith(
      messages: newMessages,
      updatedAt: DateTime.now(),
    );
  }

  // Get the last message in the conversation
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  // Get a snippet of the last message for preview
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages yet';
    final lastMsg = messages.last;
    final text = lastMsg.text;
    if (text.length > 40) {
      return '${text.substring(0, 40)}...';
    }
    return text;
  }
} 