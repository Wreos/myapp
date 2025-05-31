import 'package:flutter/foundation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

enum MessageType { text, suggestion, weeklyCheckIn, goalUpdate }

enum MessageStatus { sending, sent, error }

class ChatMessage {
  final String id;
  final String userId;
  final String content;
  final bool isUser;
  final MessageType type;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.userId,
    required this.content,
    required this.isUser,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.metadata,
    required this.timestamp,
  });

  bool get isMarkdown =>
      content.contains('```') ||
      content.contains('*') ||
      content.contains('_') ||
      content.contains('#') ||
      content.contains('- ');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'isUser': isUser,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  static ChatMessage fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage.fromJson({
      ...data,
      'id': id,
    });
  }

  ChatMessage copyWith({
    String? id,
    String? userId,
    String? content,
    bool? isUser,
    MessageType? type,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          content == other.content &&
          isUser == other.isUser &&
          type == other.type &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      content.hashCode ^
      isUser.hashCode ^
      type.hashCode ^
      status.hashCode;
}
