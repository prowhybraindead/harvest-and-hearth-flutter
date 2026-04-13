import 'recipe.dart';

enum ChatRole { user, assistant, system }

/// A single message in the AI chat conversation.
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// Whether this message is currently being streamed (shows typing indicator).
  final bool isLoading;

  /// Optional recipe extracted from AI response.
  final Recipe? recipe;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.recipe,
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    bool? isLoading,
    Recipe? recipe,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      recipe: recipe ?? this.recipe,
    );
  }

  /// Convert to Groq API message format.
  Map<String, String> toApiMap() => {
        'role': role.name,
        'content': content,
      };
}
