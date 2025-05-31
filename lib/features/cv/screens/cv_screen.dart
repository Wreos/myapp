import 'package:flutter/material.dart';
import 'package:next_you/constants/sizes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:next_you/features/cv/widgets/analysis_card.dart';

class CVScreen extends ConsumerStatefulWidget {
  const CVScreen({super.key});

  @override
  ConsumerState<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends ConsumerState<CVScreen> {
  bool _isAnalyzing = false;
  String? _uploadedFile;
  String? _cvContent;
  Map<String, List<Map<String, dynamic>>> _feedback = {};

  Future<String> _extractTextFromPDF(List<int> bytes) async {
    // Load the PDF document
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = '';

    // Extract text from all pages
    for (int i = 0; i < document.pages.count; i++) {
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      text += await extractor.extractText(startPageIndex: i);
      text += '\n';
    }

    // Dispose the document
    document.dispose();
    return text;
  }

  Future<void> _uploadCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes == null) {
          throw Exception('Could not read file content');
        }

        setState(() {
          _uploadedFile = file.name;
          _isAnalyzing = true;
          _feedback.clear();
        });

        // Extract text from PDF
        _cvContent = await _extractTextFromPDF(bytes);

        if (_cvContent?.isEmpty ?? true) {
          throw Exception('Could not extract text from PDF');
        }

        // Get AI analysis using the provider
        final aiService = ref.read(aiServiceProvider);
        await _analyzeCVContent();
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing CV: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeCVContent() async {
    if (_cvContent == null) return;

    setState(() {
      _isAnalyzing = true;
      _feedback.clear();
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      await for (final analysis
          in aiService.analyzeCVContentDetailedStream(_cvContent!)) {
        if (mounted) {
          setState(() {
            // Convert the analysis map to the correct type with proper casting of dynamic lists
            _feedback = {
              'summary': (analysis['summary'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
              'content': (analysis['content'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
              'seniority': (analysis['seniority'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
              'structure': (analysis['structure'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
              'improvements': (analysis['improvements'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
              'salary': (analysis['salary'] as List<dynamic>?)
                      ?.map((item) => item as Map<String, dynamic>)
                      .toList() ??
                  [],
            };
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing CV: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  List<String> _extractPoints(List<Map<String, dynamic>> feedback) {
    return feedback
        .map((item) =>
            '${item['title'].isNotEmpty ? '${item['title']}: ' : ''}${item['description']}')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Analysis'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(Sizes.paddingL),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _uploadCV,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_isAnalyzing ? 'Analyzing...' : 'Upload CV'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (_uploadedFile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Analyzing: $_uploadedFile',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (_isAnalyzing)
            const Center(child: CircularProgressIndicator())
          else if (_feedback.isNotEmpty)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: Sizes.paddingM),
                children: [
                  if (_feedback['summary']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Quick Summary',
                      points: _extractPoints(_feedback['summary']!),
                      color: Colors.blue,
                    ),
                  if (_feedback['content']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Content Review',
                      points: _extractPoints(_feedback['content']!),
                      color: Colors.green,
                    ),
                  if (_feedback['seniority']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Career Level',
                      points: _extractPoints(_feedback['seniority']!),
                      color: Colors.purple,
                    ),
                  if (_feedback['structure']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Layout & Format',
                      points: _extractPoints(_feedback['structure']!),
                      color: Colors.orange,
                    ),
                  if (_feedback['improvements']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Top Improvements',
                      points: _extractPoints(_feedback['improvements']!),
                      color: Colors.red,
                    ),
                  if (_feedback['salary']?.isNotEmpty ?? false)
                    AnalysisCard(
                      title: 'Market Value',
                      points: _extractPoints(_feedback['salary']!),
                      color: Colors.teal,
                    ),
                ].where((widget) => widget != null).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
