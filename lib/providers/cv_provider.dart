import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:next_you/features/cv/models/cv_feedback_model.dart';

class CVAnalysisState {
  final bool isAnalyzing;
  final String? error;
  final Map<String, dynamic>? feedback;

  CVAnalysisState({
    this.isAnalyzing = false,
    this.error,
    this.feedback,
  });

  CVAnalysisState copyWith({
    bool? isAnalyzing,
    String? error,
    Map<String, dynamic>? feedback,
  }) {
    return CVAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error ?? this.error,
      feedback: feedback ?? this.feedback,
    );
  }
}

class CVAnalysisNotifier extends StateNotifier<CVAnalysisState> {
  final Ref ref;

  CVAnalysisNotifier(this.ref) : super(CVAnalysisState());

  Future<void> analyzeCVContent(String content) async {
    if (content.isEmpty) {
      debugPrint('No CV content to analyze');
      return;
    }

    try {
      debugPrint('Setting analyzing state...');
      state = state.copyWith(isAnalyzing: true);

      debugPrint('Calling AI service...');
      final aiService = ref.read(aiServiceProvider);
      final analysis = await aiService.analyzeCVContentDetailed(content);

      debugPrint('Received analysis result');
      if (analysis == null) {
        debugPrint('Analysis returned error');
        state = state.copyWith(
          isAnalyzing: false,
          error: 'Failed to analyze CV. Please try again.',
        );
        return;
      }

      debugPrint('Updating state with analysis...');
      state = state.copyWith(
        isAnalyzing: false,
        feedback: analysis,
        error: null,
      );

      debugPrint(
          'State updated. Feedback sections: ${analysis.keys.join(', ')}');
    } catch (e) {
      debugPrint('Error during analysis: $e');
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }
}

final cvAnalysisProvider =
    StateNotifierProvider<CVAnalysisNotifier, CVAnalysisState>((ref) {
  return CVAnalysisNotifier(ref);
});
