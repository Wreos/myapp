import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/models/chat_message.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(AIService());
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AIService _aiService;

  ChatNotifier(this._aiService) : super([]);

  Future<void> sendMessage(String userId, String content) async {
    final messageId = _uuid.v4();
    final userMessage = ChatMessage(
      id: messageId,
      userId: userId,
      content: content,
      isUser: true,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    state = [...state, userMessage];

    try {
      // Update user message status to sent
      state = [
        for (final msg in state)
          if (msg.id == messageId)
            msg.copyWith(status: MessageStatus.sent)
          else
            msg
      ];

      final aiMessageId = _uuid.v4();

      // Add initial AI message
      state = [
        ...state,
        ChatMessage(
          id: aiMessageId,
          userId: 'ai',
          content: '',
          isUser: false,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
        ),
      ];

      // Get AI response
      final response = await _aiService.sendMessage(content);

      // Update AI message with response
      state = [
        for (final msg in state)
          if (msg.id == aiMessageId)
            msg.copyWith(
              content: response,
              status: MessageStatus.sent,
            )
          else
            msg
      ];
    } catch (e) {
      state = [
        for (final msg in state)
          if (msg.id == messageId)
            msg.copyWith(status: MessageStatus.error)
          else
            msg
      ];
    }
  }

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clearChat() {
    state = [];
  }

  void deleteMessage(int index) {
    if (index >= 0 && index < state.length) {
      final newState = List<ChatMessage>.from(state);
      newState.removeAt(index);
      state = newState;
      if (state.isEmpty) {
        clearChat();
      }
    }
  }

  void removeMessage(String messageId) {
    state = state.where((message) => message.id != messageId).toList();
  }

  Future<void> retryMessage(String messageId) async {
    final message = state.firstWhere((msg) => msg.id == messageId);
    if (!message.isUser) return;

    // Remove the failed message and its response (if any)
    state = state.where((msg) => msg.id != messageId).toList();

    // Resend the message
    sendMessage(message.userId, message.content);
  }
}
