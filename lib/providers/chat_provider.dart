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

  Stream<void> streamMessage(String userId, String content) async* {
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
      var buffer = '';

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

      await for (final chunk in _aiService.streamMessage(content)) {
        buffer = chunk;
        // Update AI message with new content
        state = [
          for (final msg in state)
            if (msg.id == aiMessageId)
              msg.copyWith(
                content: buffer,
                status: MessageStatus.sent,
              )
            else
              msg
        ];
        yield buffer;
      }
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

  void clearChat() {
    state = [];
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
    streamMessage(message.userId, message.content);
  }
}
