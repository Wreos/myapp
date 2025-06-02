import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:next_you/features/cv/screens/cv_feedback_view.dart';
import 'package:next_you/features/cv/models/cv_feedback_model.dart';
import 'package:next_you/providers/chat_provider.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:next_you/features/auth/services/auth_utils.dart';
import 'package:next_you/features/cv/screens/cv_upload_screen.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../../navigation/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CVUploadDialog extends ConsumerStatefulWidget {
  const CVUploadDialog({super.key});

  static Future<void> show(BuildContext context) async {
    // Check authentication before showing dialog
    final isAuthorized = await AuthUtils.requireAuth(context);
    if (!isAuthorized) {
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CVUploadDialog(),
    );
  }

  @override
  ConsumerState<CVUploadDialog> createState() => _CVUploadDialogState();
}

class _CVUploadDialogState extends ConsumerState<CVUploadDialog> {
  bool _isAnalyzing = false;
  String? _error;

  Future<String> _extractTextFromFile(Uint8List bytes, String extension) async {
    try {
      extension = extension.toLowerCase();
      String text = '';

      if (extension == 'pdf') {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        text = PdfTextExtractor(document).extractText();
        document.dispose();
      } else if (extension == 'docx') {
        text = await compute(docxToText, bytes);
      } else if (extension == 'doc') {
        // For older .doc files, we'll try to extract as plain text
        // This is a fallback and may not work perfectly for all .doc files
        List<Encoding> encodings = [utf8, latin1, ascii];
        for (var encoding in encodings) {
          try {
            text = encoding.decode(bytes);
            if (text.trim().isNotEmpty) break;
          } catch (e) {
            continue;
          }
        }
      } else {
        // For txt files or other formats, try common encodings
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
        throw Exception(
            'No text could be extracted from the file. For DOC files, please save as DOCX format for better compatibility.');
      }

      return text
          .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      throw Exception(
          'Could not extract text from the file. Please ensure it contains selectable text. For DOC files, please save as DOCX format for better compatibility.');
    }
  }

  Future<void> _analyzeCVFile() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _error = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withReadStream: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isAnalyzing = false);
        return;
      }

      final file = result.files.first;
      if (file.readStream == null) {
        throw Exception('Could not read file content');
      }

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

      if (!mounted) return;

      // Save new analysis
      await _saveAnalysis(analysis);

      // Close dialog and show feedback
      Navigator.of(context).pop();
      if (context.mounted) {
        context.push('/feedback', extra: analysis);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
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

  Future<void> _saveAnalysis(Map<String, dynamic> analysis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cv_analysis', jsonEncode(analysis));
    } catch (e) {
      debugPrint('Error saving analysis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;
    final maxHeight = size.height * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth > 400 ? 400 : maxWidth,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload CV',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Content
            if (_isAnalyzing) ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing your CV...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This may take a moment',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.upload_file,
                        size: 32,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select a CV to analyze',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get detailed feedback and insights about your CV',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _analyzeCVFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Select CV'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Supported formats: PDF, DOC, DOCX, TXT\nMaximum size: 10MB',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
