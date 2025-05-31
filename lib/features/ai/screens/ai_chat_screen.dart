import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:next_you/providers/chat_provider.dart';
import 'package:next_you/widgets/chat/chat_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:next_you/models/chat_message.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();
    setState(() => _isComposing = false);

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    ref.read(chatProvider.notifier).streamMessage(userId, message).listen(
      (_) {
        // Scroll to bottom after each chunk
        Future.delayed(
          const Duration(milliseconds: 50),
          _scrollToBottom,
        );
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with your AI career coach',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(Sizes.paddingL),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatBubble(
                        key: ValueKey(message.id),
                        message: message,
                        onRetry: message.status == MessageStatus.error
                            ? () {
                                ref
                                    .read(chatProvider.notifier)
                                    .retryMessage(message.id);
                              }
                            : null,
                        onDelete: message.isUser
                            ? () {
                                ref
                                    .read(chatProvider.notifier)
                                    .removeMessage(message.id);
                              }
                            : null,
                      );
                    },
                  ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: Sizes.blurRadius,
                  spreadRadius: Sizes.spreadRadius,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(Sizes.paddingM),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (text) {
                          setState(() => _isComposing = text.isNotEmpty);
                        },
                        onSubmitted: (text) {
                          if (_isComposing) _sendMessage();
                        },
                        decoration: InputDecoration(
                          hintText: 'Ask about your career...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    SizedBox(width: Sizes.paddingM),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isComposing
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: _isComposing
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _isComposing ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
