import 'package:flutter/material.dart';
import '../models/cv_feedback_model.dart';
import '../../../theme/app_theme.dart';

class FeedbackCard extends StatelessWidget {
  final String title;
  final List<FeedbackItem> items;
  final FeedbackType defaultType;
  final bool showIcon;
  final bool showBorder;
  final VoidCallback? onTap;

  const FeedbackCard({
    super.key,
    required this.title,
    required this.items,
    this.defaultType = FeedbackType.info,
    this.showIcon = true,
    this.showBorder = true,
    this.onTap,
  });

  String _highlightKeyPhrases(String text) {
    final patterns = [
      RegExp(r'(\d+[–-]\d+[KkMm]?)'), // e.g. 25-35K
      RegExp(r'(€\d+[–-]\d+[KkMm]?)'), // e.g. €25-35K
      RegExp(r'(\d+\+? years?)'), // e.g. 5+ years
      RegExp(r'(\d+%?)'), // e.g. 50%
    ];

    String result = text;
    for (final pattern in patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        return '**${match.group(0)}**';
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final feedbackColor =
        AppTheme.feedbackColors[defaultType.name] ?? colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: showBorder
                  ? Border.all(
                      color: colorScheme.outline,
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showIcon) ...[
                      Icon(
                        defaultType.icon,
                        size: 24,
                        color: feedbackColor,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: feedbackColor.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.title.isNotEmpty)
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  if (item.title.isNotEmpty)
                                    const SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      children: _buildHighlightedText(
                                        _highlightKeyPhrases(item.description),
                                        colorScheme.onSurface,
                                      ),
                                    ),
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
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String text, Color defaultColor) {
    final parts = text.split('**');
    return List.generate(parts.length, (index) {
      final isHighlighted = index.isOdd;
      return TextSpan(
        text: parts[index],
        style: isHighlighted
            ? TextStyle(
                fontWeight: FontWeight.w600,
                color: defaultColor,
              )
            : null,
      );
    });
  }
}
