import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:next_you/models/chat_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isError = message.status == MessageStatus.error;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          bottom: Sizes.paddingL,
          left: message.isUser ? Sizes.paddingXXL : 0,
          right: message.isUser ? 0 : Sizes.paddingXXL,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Card(
              color: message.isUser
                  ? isError
                      ? colorScheme.errorContainer
                      : colorScheme.primary
                  : colorScheme.secondaryContainer,
              child: Padding(
                padding: EdgeInsets.all(Sizes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isMarkdown)
                      MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: message.isUser ? Colors.white : null,
                          ),
                          code: TextStyle(
                            backgroundColor: message.isUser
                                ? colorScheme.primaryContainer
                                : colorScheme.secondary.withOpacity(0.1),
                            color: message.isUser ? Colors.white : null,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: message.isUser
                                ? colorScheme.primaryContainer
                                : colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                      )
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (message.isUser) ...[
              SizedBox(height: Sizes.paddingXS),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.status == MessageStatus.sending)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  else if (message.status == MessageStatus.sent)
                    Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.primary,
                    )
                  else if (message.status == MessageStatus.error) ...[
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    if (onRetry != null) ...[
                      SizedBox(width: Sizes.paddingXS),
                      GestureDetector(
                        onTap: onRetry,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (onDelete != null) ...[
                    SizedBox(width: Sizes.paddingS),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
