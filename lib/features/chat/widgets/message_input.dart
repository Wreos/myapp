import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/providers/chat_provider.dart';
import 'package:next_you/features/auth/services/auth_utils.dart';

class MessageInput extends ConsumerStatefulWidget {
  final Function(String) onSendMessage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendMessage(text.trim());
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            isKeyboardVisible ? 12 : 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                onChanged: (text) {
                                  setState(() {
                                    _isComposing = text.trim().isNotEmpty;
                                  });
                                },
                                onSubmitted: _handleSubmitted,
                                decoration: InputDecoration(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 16,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.fromLTRB(16, 12, 8, 12),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  isDense: true,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                maxLines: 4,
                                minLines: 1,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 4, bottom: 4),
                            child: IconButton(
                              icon: Icon(
                                Icons.send_rounded,
                                size: 24,
                                color: _isComposing
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                              ),
                              onPressed: _isComposing
                                  ? () => _handleSubmitted(_controller.text)
                                  : null,
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
