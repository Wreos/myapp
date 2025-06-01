import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum FeedbackType {
  success(
    icon: Icons.check_circle_outline,
  ),
  warning(
    icon: Icons.warning_amber_rounded,
  ),
  improvement(
    icon: Icons.trending_up,
  ),
  suggestion(
    icon: Icons.lightbulb_outline,
  ),
  info(
    icon: Icons.info_outline,
  );

  final IconData icon;

  const FeedbackType({
    required this.icon,
  });

  Color get color =>
      AppTheme.feedbackColors[name] ?? AppTheme.feedbackColors['info']!;
}

class FeedbackItem {
  final String title;
  final String description;
  final FeedbackType type;

  FeedbackItem({
    required this.title,
    required this.description,
    required this.type,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: FeedbackType.values.firstWhere(
        (type) => type.name == (json['type'] as String? ?? 'info'),
        orElse: () => FeedbackType.info,
      ),
    );
  }
}

class CVScore {
  final double value;
  final String message;
  final Map<String, double> details;

  CVScore({
    required this.value,
    required this.message,
    required this.details,
  });

  factory CVScore.fromJson(Map<String, dynamic> json) {
    return CVScore(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String? ?? '',
      details: Map<String, double>.from(
        (json['details'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ),
      ),
    );
  }
}

class ExpertOpinion {
  final String summary;
  final String marketPosition;
  final String uniqueValue;
  final String nextSteps;

  ExpertOpinion({
    required this.summary,
    required this.marketPosition,
    required this.uniqueValue,
    required this.nextSteps,
  });

  factory ExpertOpinion.fromJson(Map<String, dynamic> json) {
    return ExpertOpinion(
      summary: json['summary'] as String? ?? '',
      marketPosition: json['market_position'] as String? ?? '',
      uniqueValue: json['unique_value'] as String? ?? '',
      nextSteps: json['next_steps'] as String? ?? '',
    );
  }
}

class CVFeedback {
  final CVScore score;
  final String cvType;
  final List<FeedbackItem> position;
  final List<FeedbackItem> summary;
  final List<FeedbackItem> structure;
  final List<FeedbackItem> improvements;
  final List<FeedbackItem> marketInsights;
  final List<FeedbackItem> salary;
  final ExpertOpinion expertOpinion;

  CVFeedback({
    required this.score,
    required this.cvType,
    required this.position,
    required this.summary,
    required this.structure,
    required this.improvements,
    required this.marketInsights,
    required this.salary,
    required this.expertOpinion,
  });

  factory CVFeedback.fromJson(Map<String, dynamic> json) {
    return CVFeedback(
      score: CVScore.fromJson(json['score'] as Map<String, dynamic>? ?? {}),
      cvType: json['cv_type'] as String? ?? 'unknown',
      position: (json['position'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      summary: (json['summary'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      structure: (json['structure'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      improvements: (json['improvements'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      marketInsights: (json['market_insights'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      salary: (json['salary'] as List<dynamic>? ?? [])
          .map((item) => FeedbackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      expertOpinion: ExpertOpinion.fromJson(
          json['expert_opinion'] as Map<String, dynamic>? ?? {}),
    );
  }

  List<FeedbackItem> get criticalImprovements {
    return improvements
        .where((item) => item.type == FeedbackType.warning)
        .take(3)
        .toList();
  }

  List<FeedbackItem> get quickWins {
    return improvements
        .where((item) => item.type == FeedbackType.improvement)
        .take(3)
        .toList();
  }

  bool get isTechnical => cvType == 'technical';
}
