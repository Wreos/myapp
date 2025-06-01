import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cv_feedback_model.dart';
import '../widgets/feedback_card.dart';
import '../../../theme/app_theme.dart';
import '../widgets/cv_upload_dialog.dart';
import 'package:next_you/features/auth/services/auth_utils.dart';
import 'package:next_you/features/chat/screens/chat_screen.dart';
import 'package:next_you/features/more/screens/more_screen.dart';
import 'package:next_you/features/navigation/screens/main_screen.dart';
import 'package:go_router/go_router.dart';

class CVFeedbackView extends ConsumerWidget {
  final CVFeedback feedback;
  final VoidCallback onChatPressed;

  const CVFeedbackView({
    super.key,
    required this.feedback,
    required this.onChatPressed,
  });

  String _getSeniorityLevel(CVFeedback feedback) {
    // First check if position info contains explicit seniority level
    for (var item in feedback.position) {
      if (item.title.toLowerCase().contains('seniority')) {
        return item.description;
      }
    }

    // Extract years of experience from position description
    final yearsPattern = RegExp(r'(\d+)(?:\+|\s*(?:years?|yrs?))');
    int maxYears = 0;

    for (var item in feedback.position) {
      final matches = yearsPattern.allMatches(item.description.toLowerCase());
      for (var match in matches) {
        final years = int.parse(match.group(1)!);
        if (years > maxYears) maxYears = years;
      }
    }

    // More granular seniority levels based on years of experience
    if (maxYears >= 8) return 'Senior Level';
    if (maxYears >= 5) return 'Senior Level';
    if (maxYears >= 3) return 'Mid-Senior Level';
    if (maxYears >= 1) return 'Mid Level';
    return 'Junior Level';
  }

  String _getCurrentPosition(CVFeedback feedback) {
    if (feedback.position.isEmpty) return 'CV Analysis';

    final positionItem = feedback.position.firstWhere(
      (item) =>
          item.title.toLowerCase().contains('current') ||
          item.title.toLowerCase().contains('position') ||
          item.title.toLowerCase().contains('role'),
      orElse: () => feedback.position.first,
    );

    return positionItem.description;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    Color _getScoreColor(double score) {
      if (score >= 80)
        return AppTheme
            .feedbackColors['success']!; // Use success color from theme
      if (score >= 70) return colorScheme.secondary;
      if (score >= 60) return colorScheme.tertiary;
      return colorScheme.error;
    }

    Color _getScoreBackgroundColor(double score) {
      if (score >= 80)
        return AppTheme.feedbackColors['success']!
            .withOpacity(0.15); // Use success color from theme
      if (score >= 70) return colorScheme.secondary.withOpacity(0.15);
      if (score >= 60) return colorScheme.tertiary.withOpacity(0.15);
      return colorScheme.error.withOpacity(0.15);
    }

    Color _getScoreTextColor(double score) {
      return _getScoreColor(score);
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'CV Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surface.withOpacity(0.95)
            : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
        shadowColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.transparent
            : colorScheme.shadow.withOpacity(0.1),
        toolbarHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.outline.withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Title Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentPosition(feedback),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Overview Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getScoreBackgroundColor(
                                      feedback.score.value),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getScoreColor(feedback.score.value),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Score: ${feedback.score.value.round()}%',
                                  style: TextStyle(
                                    color: _getScoreColor(feedback.score.value),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: feedback.score.value >= 80
                                      ? AppTheme.feedbackColors['success']!
                                          .withOpacity(0.15)
                                      : colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: feedback.score.value >= 80
                                        ? AppTheme.feedbackColors['success']!
                                        : colorScheme.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getSeniorityLevel(feedback),
                                  style: TextStyle(
                                    color: feedback.score.value >= 80
                                        ? AppTheme.feedbackColors['success']!
                                        : colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (feedback.expertOpinion.summary.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.psychology,
                                        size: 20,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expert Opinion',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.primary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    feedback.expertOpinion.summary,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colorScheme.onSurface,
                                      height: 1.5,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Score Breakdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...feedback.score.details.entries.map((entry) {
                        final score = entry.value;
                        final label = entry.key
                            .split('_')
                            .map((word) =>
                                word[0].toUpperCase() + word.substring(1))
                            .join(' ');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getScoreBackgroundColor(score),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${score.round()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _getScoreColor(score),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: score / 100,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getScoreColor(score)
                                              .withOpacity(0.8),
                                          _getScoreColor(score),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),

            // Critical Fixes
            if (feedback.criticalImprovements.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FeedbackType.warning.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: FeedbackType.warning.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Critical Fixes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...feedback.criticalImprovements.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: FeedbackType.warning.color
                                          .withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ),

            // Current Position
            if (feedback.position.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FeedbackCard(
                    title: 'Current Position',
                    items: feedback.position,
                    defaultType: FeedbackType.info,
                    showIcon: true,
                  ),
                ),
              ),

            // Key Strengths
            if (feedback.summary
                .where((item) => item.type == FeedbackType.success)
                .isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FeedbackCard(
                    title: 'Key Strengths',
                    items: feedback.summary
                        .where((item) => item.type == FeedbackType.success)
                        .toList(),
                    defaultType: FeedbackType.success,
                    showIcon: true,
                  ),
                ),
              ),

            // Structure
            if (feedback.structure.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FeedbackCard(
                    title: 'CV Structure',
                    items: feedback.structure,
                    defaultType: FeedbackType.info,
                    showIcon: true,
                  ),
                ),
              ),

            // Market & Salary Insights
            if (feedback.marketInsights.isNotEmpty ||
                feedback.salary.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (feedback.marketInsights.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    size: 24,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Market Insights',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...feedback.marketInsights.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      if (feedback.marketInsights.isNotEmpty &&
                          feedback.salary.isNotEmpty)
                        const SizedBox(height: 16),
                      if (feedback.salary.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.euro_rounded,
                                    size: 24,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Salary Insights',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...feedback.salary.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description
                                              .replaceAll('€', '€ '),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Expert Opinion
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 24,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Full Action Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildExpertOpinionSection(
                        context,
                        'Summary',
                        feedback.expertOpinion.summary,
                      ),
                      _buildExpertOpinionSection(
                        context,
                        'Market Position',
                        feedback.expertOpinion.marketPosition,
                      ),
                      _buildExpertOpinionSection(
                        context,
                        'Unique Value',
                        feedback.expertOpinion.uniqueValue,
                      ),
                      _buildExpertOpinionSection(
                        context,
                        'Next Steps',
                        feedback.expertOpinion.nextSteps,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CTA
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        // Check authentication before navigating to chat
                        final isAuthorized =
                            await AuthUtils.requireAuth(context);
                        if (!isAuthorized) {
                          return;
                        }
                        onChatPressed();
                      },
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Continue in Chat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => CVUploadDialog.show(context),
                      icon: Icon(
                        Icons.upload_file,
                        color: colorScheme.primary.withOpacity(0.8),
                      ),
                      label: Text(
                        'Upload Another CV',
                        style: TextStyle(
                          color: colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertOpinionSection(
    BuildContext context,
    String title,
    String content, {
    bool showDivider = true,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 16),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
