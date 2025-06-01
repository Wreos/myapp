import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_you/features/chat/screens/chat_screen.dart';
import 'package:next_you/features/cv/models/cv_feedback_model.dart';
import 'package:next_you/features/cv/screens/cv_feedback_view.dart';
import 'package:next_you/providers/chat_provider.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:next_you/widgets/custom_app_bar.dart';
import 'package:next_you/features/auth/services/auth_utils.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/cv_feedback_model.dart';
import '../widgets/cv_upload_dialog.dart';
import '../../chat/screens/chat_screen.dart';
import '../screens/cv_feedback_view.dart';
import '../../navigation/screens/main_screen.dart';
import 'package:go_router/go_router.dart';

// CV Upload State Provider
final cvUploadStateProvider =
    StateNotifierProvider<CVUploadNotifier, CVUploadState>((ref) {
  return CVUploadNotifier();
});

class CVUploadState {
  final bool isUploaded;
  final String? cvPath;
  final DateTime? uploadDate;

  CVUploadState({
    this.isUploaded = false,
    this.cvPath,
    this.uploadDate,
  });

  CVUploadState copyWith({
    bool? isUploaded,
    String? cvPath,
    DateTime? uploadDate,
  }) {
    return CVUploadState(
      isUploaded: isUploaded ?? this.isUploaded,
      cvPath: cvPath ?? this.cvPath,
      uploadDate: uploadDate ?? this.uploadDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUploaded': isUploaded,
      'cvPath': cvPath,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  factory CVUploadState.fromJson(Map<String, dynamic> json) {
    return CVUploadState(
      isUploaded: json['isUploaded'] ?? false,
      cvPath: json['cvPath'],
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'])
          : null,
    );
  }
}

class CVUploadNotifier extends StateNotifier<CVUploadState> {
  CVUploadNotifier() : super(CVUploadState()) {
    _loadState();
  }

  static const _stateKey = 'cv_upload_state';

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      if (stateJson != null) {
        final Map<String, dynamic> json = jsonDecode(stateJson);
        state = CVUploadState.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading CV upload state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(state.toJson());
      await prefs.setString(_stateKey, stateJson);
    } catch (e) {
      debugPrint('Error saving CV upload state: $e');
    }
  }

  Future<void> uploadCV(String path) async {
    state = state.copyWith(
      isUploaded: true,
      cvPath: path,
      uploadDate: DateTime.now(),
    );
    await _saveState();
  }

  Future<void> resetCV() async {
    state = CVUploadState();
    await _saveState();
  }
}

// CV Analysis Provider
final cvAnalysisProvider =
    StateNotifierProvider<CVAnalysisNotifier, CVFeedback>((ref) {
  return CVAnalysisNotifier();
});

class CVAnalysisNotifier extends StateNotifier<CVFeedback> {
  CVAnalysisNotifier()
      : super(CVFeedback(
          score: CVScore(value: 0, message: '', details: {}),
          cvType: 'unknown',
          position: [],
          summary: [],
          structure: [],
          improvements: [],
          marketInsights: [],
          salary: [],
          expertOpinion: ExpertOpinion(
            summary: '',
            marketPosition: '',
            uniqueValue: '',
            nextSteps: '',
          ),
        ));

  void updateAnalysis(Map<String, dynamic> analysis) {
    state = CVFeedback.fromJson(analysis);
  }

  void reset() {
    state = CVFeedback(
      score: CVScore(value: 0, message: '', details: {}),
      cvType: 'unknown',
      position: [],
      summary: [],
      structure: [],
      improvements: [],
      marketInsights: [],
      salary: [],
      expertOpinion: ExpertOpinion(
        summary: '',
        marketPosition: '',
        uniqueValue: '',
        nextSteps: '',
      ),
    );
  }
}

class CVUploadScreen extends ConsumerStatefulWidget {
  const CVUploadScreen({super.key});

  @override
  ConsumerState<CVUploadScreen> createState() => _CVUploadScreenState();
}

class _CVUploadScreenState extends ConsumerState<CVUploadScreen> {
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowSavedAnalysis();
    });
  }

  Future<void> _checkAndShowSavedAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analysisJson = prefs.getString('cv_analysis');

      if (analysisJson != null) {
        final analysis = jsonDecode(analysisJson);

        // Validate that the analysis data is valid
        try {
          final cvFeedback = CVFeedback.fromJson(analysis);

          // Only proceed if we have actual analysis data
          if (cvFeedback.score.value > 0 ||
              cvFeedback.improvements.isNotEmpty) {
            // Update providers with latest data
            ref.read(cvAnalysisProvider.notifier).updateAnalysis(analysis);
            ref.read(cvUploadStateProvider.notifier).uploadCV('saved_analysis');

            // Get CV content from analysis to update AI service context
            final aiService = ref.read(aiServiceProvider);
            if (analysis['cv_content'] != null) {
              aiService.setCVContext(analysis['cv_content']);
            }

            if (!mounted) return;
            context.push('/feedback', extra: analysis);
          }
        } catch (e) {
          debugPrint('Invalid saved analysis format: $e');
          // Clear invalid data
          await prefs.remove('cv_analysis');
        }
      }
    } catch (e) {
      debugPrint('Error checking saved analysis: $e');
    }
  }

  Future<void> _loadSavedAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analysisJson = prefs.getString('cv_analysis');
      if (analysisJson != null) {
        final analysis = jsonDecode(analysisJson);
        ref.read(cvAnalysisProvider.notifier).updateAnalysis(analysis);
      }
    } catch (e) {
      debugPrint('Error loading saved analysis: $e');
    }
  }

  Future<void> _saveAnalysis(Map<String, dynamic> analysis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Add CV content to analysis data for context preservation
      final analysisWithContent = {
        ...analysis,
        'cv_content': analysis['cv_content'] ?? '',
      };
      await prefs.setString('cv_analysis', jsonEncode(analysisWithContent));
    } catch (e) {
      debugPrint('Error saving analysis: $e');
    }
  }

  Future<String> _extractTextFromFile(Uint8List bytes, String extension) async {
    try {
      extension = extension.toLowerCase();
      String text = '';

      if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        text = PdfTextExtractor(document).extractText();
        document.dispose();
      } else {
        List<Encoding> encodings = [utf8, latin1, ascii];
        for (var encoding in encodings) {
          try {
            text = encoding.decode(bytes);
            if (text.trim().isNotEmpty) break;
          } catch (e) {
            continue;
          }
        }
      }

      if (text.trim().isEmpty) {
        throw Exception('No text could be extracted from the file');
      }

      return text;
    } catch (e) {
      debugPrint('Error extracting text: $e');
      rethrow;
    }
  }

  Future<void> _analyzeCVFile() async {
    // Check authentication before proceeding
    final isAuthorized = await AuthUtils.requireAuth(context);
    if (!isAuthorized) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withReadStream: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      setState(() => _isAnalyzing = true);

      final file = result.files.first;
      final List<int> bytes = [];
      await for (var chunk in file.readStream!) {
        bytes.addAll(chunk);
      }

      final content = await _extractTextFromFile(
        Uint8List.fromList(bytes),
        file.extension ?? '',
      );

      final aiService = ref.read(aiServiceProvider);
      // Clear old data first
      await _clearSavedAnalysis();

      aiService.setCVContext(content);
      final analysis = await aiService.analyzeCVContentDetailed(content);

      // Save new analysis
      await _saveAnalysis(analysis);
      await ref.read(cvUploadStateProvider.notifier).uploadCV(file.path ?? '');
      ref.read(cvAnalysisProvider.notifier).updateAnalysis(analysis);

      if (!mounted) return;

      final cvFeedback = CVFeedback.fromJson(analysis);
      context.push('/feedback', extra: analysis);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing CV: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _clearSavedAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cv_analysis');
      ref.read(cvAnalysisProvider.notifier).reset();
    } catch (e) {
      debugPrint('Error clearing saved analysis: $e');
    }
  }

  Widget _buildConnectingArrow() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 32,
        color: colorScheme.primary.withOpacity(0.8),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required bool showUploadButton,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (showUploadButton) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _analyzeCVFile,
                icon: const Icon(Icons.upload_outlined, size: 22),
                label: const Text(
                  'Upload CV',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isAnalyzing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Analyzing CV',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 32),
              Text(
                'Analyzing your CV...',
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
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
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureCard(
                title: 'Upload your CV',
                description:
                    'Share your CV to get personalized insights and feedback',
                icon: Icons.upload_file_outlined,
                showUploadButton: true,
              ),
              _buildConnectingArrow(),
              _buildFeatureCard(
                title: 'AI Analysis',
                description:
                    'Our AI analyzes your CV for strengths, improvements, and market fit',
                icon: Icons.analytics_outlined,
                showUploadButton: false,
              ),
              _buildConnectingArrow(),
              _buildFeatureCard(
                title: 'Get Insights',
                description:
                    'Receive detailed feedback and actionable recommendations',
                icon: Icons.insights_outlined,
                showUploadButton: false,
              ),
              if (Theme.of(context).brightness == Brightness.dark)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your data is encrypted and secure',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
