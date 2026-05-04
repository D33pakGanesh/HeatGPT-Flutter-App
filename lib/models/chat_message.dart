enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({required this.role, required this.content, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'role': role == ChatRole.user ? 'user' : 'assistant',
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
        content: j['content'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}
