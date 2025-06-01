import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:next_you/providers/chat_provider.dart';
import 'package:next_you/models/chat_message.dart';
import 'package:next_you/features/chat/widgets/message_bubble.dart';
import 'package:next_you/features/chat/widgets/message_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:next_you/features/auth/screens/auth_modal.dart';
import 'package:next_you/features/profile/screens/profile_screen.dart';
import 'package:next_you/features/chat/widgets/typing_indicator.dart';
import 'package:next_you/services/ai_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  void _showAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AuthModal(),
    );
  }

  void _handleMessage(String message) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAuthDialog();
      return;
    }

    setState(() => _isTyping = true);
    ref.read(chatProvider.notifier).sendMessage(user.uid, message).then((_) {
      setState(() => _isTyping = false);
    });
  }

  void _sendSuggestedMessage(String message) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAuthDialog();
      return;
    }

    setState(() => _isTyping = true);
    ref.read(chatProvider.notifier).sendMessage(user.uid, message).then((_) {
      setState(() => _isTyping = false);
    });
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 160,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your AI Career Coach',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Get personalized career guidance and professional development advice',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.work_outline,
                    title: 'Career Path',
                    description: 'Analyze your career options based on skills',
                    onTap: () => _sendSuggestedMessage(
                        'Help me analyze my career path options based on my skills.'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.trending_up,
                    title: 'Skills Plan',
                    description: 'Create your professional growth roadmap',
                    onTap: () => _sendSuggestedMessage(
                        'Create a skill development plan for my career growth.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.psychology,
                    title: 'Interviews',
                    description: 'Master job interview techniques',
                    onTap: () => _sendSuggestedMessage(
                        'What are the key strategies for job interviews?'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.rate_review_outlined,
                    title: 'CV Review',
                    description: 'Get tips to improve your resume',
                    onTap: () => _sendSuggestedMessage(
                        'Can you give me tips to improve my CV/resume?'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.handshake_outlined,
                    title: 'Networking',
                    description: 'Build professional relationships',
                    onTap: () => _sendSuggestedMessage(
                        'How can I improve my professional networking?'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSuggestionCard(
                    icon: Icons.monetization_on_outlined,
                    title: 'Salary Talk',
                    description: 'Navigate salary negotiations',
                    onTap: () => _sendSuggestedMessage(
                        'How should I approach salary negotiations?'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Career Coach',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: messages.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded),
                  tooltip: 'Start New Chat',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Start New Chat'),
                        content: const Text(
                          'This will clear your current conversation and return to the main menu. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              ref.read(chatProvider.notifier).clearChat();
                              ref.read(aiServiceProvider).clearCVContext();
                              Navigator.pop(context);
                            },
                            child: const Text('Clear Chat'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(Sizes.paddingL),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isTyping) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: Sizes.paddingM),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingIndicator(),
                          ),
                        );
                      }
                      final message = messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Sizes.paddingM),
                        child: MessageBubble(message: message),
                      );
                    },
                  ),
          ),
          MessageInput(
            onSendMessage: _handleMessage,
          ),
        ],
      ),
    );
  }
}
