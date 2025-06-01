import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/services/ai_service.dart';

class CVAnalysisState {
  final bool isAnalyzing;
  final String? uploadedFile;
  final String? cvContent;
  final Map<String, List<Map<String, dynamic>>> feedback;
  final String? error;

  const CVAnalysisState({
    this.isAnalyzing = false,
    this.uploadedFile,
    this.cvContent,
    this.feedback = const {},
    this.error,
  });

  CVAnalysisState copyWith({
    bool? isAnalyzing,
    String? uploadedFile,
    String? cvContent,
    Map<String, List<Map<String, dynamic>>>? feedback,
    String? error,
  }) {
    return CVAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      uploadedFile: uploadedFile ?? this.uploadedFile,
      cvContent: cvContent ?? this.cvContent,
      feedback: feedback ?? this.feedback,
      error: error,
    );
  }
}

class CVAnalysisNotifier extends StateNotifier<CVAnalysisState> {
  final AIService _aiService;

  CVAnalysisNotifier(this._aiService) : super(const CVAnalysisState());

  void reset() {
    state = const CVAnalysisState();
  }

  void setUploadedFile(String fileName, String content) {
    state = state.copyWith(
      uploadedFile: fileName,
      cvContent: content,
      error: null,
    );
  }

  Future<void> analyzeCVContent() async {
    if (state.cvContent == null) {
      print('No CV content to analyze');
      return;
    }

    print('Setting analyzing state...');
    state = state.copyWith(isAnalyzing: true, feedback: const {}, error: null);

    try {
      print('Calling AI service...');
      final analysis =
          await _aiService.analyzeCVContentDetailed(state.cvContent!);
      print('Received analysis result');

      if (analysis.containsKey('error')) {
        print('Analysis returned error');
        if (mounted) {
          state = state.copyWith(
            error: analysis['error']?[0]['description'] ?? 'Unknown error',
            isAnalyzing: false,
          );
        }
        return;
      }

      if (mounted) {
        print('Updating state with analysis...');
        state = state.copyWith(
          feedback: analysis,
          isAnalyzing: false,
          error: null,
        );
        print('State updated. Feedback sections: ${analysis.keys.join(', ')}');
      }
    } catch (e) {
      print('Error during analysis: $e');
      if (mounted) {
        state = state.copyWith(
          error: 'Error analyzing CV: $e',
          isAnalyzing: false,
        );
      }
    }
  }
}

final cvAnalysisProvider =
    StateNotifierProvider<CVAnalysisNotifier, CVAnalysisState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return CVAnalysisNotifier(aiService);
});
