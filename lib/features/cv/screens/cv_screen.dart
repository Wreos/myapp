import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:next_you/services/ai_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CVScreen extends ConsumerStatefulWidget {
  const CVScreen({super.key});

  @override
  ConsumerState<CVScreen> createState() => _CVScreenState();
}

class _CVScreenState extends ConsumerState<CVScreen> {
  bool _isAnalyzing = false;
  Map<String, List<Map<String, dynamic>>>? _analysisResult;
  String? _error;

  Future<String> _extractTextFromFile(Uint8List bytes, String extension) async {
    try {
      extension = extension.toLowerCase();
      String text = '';

      if (extension == 'pdf') {
        // Handle PDF files with Syncfusion
        print('Processing PDF file...');
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        text = PdfTextExtractor(document).extractText();
        document.dispose();
        print('PDF text extracted, length: ${text.length}');
      } else {
        // Handle other file types with text encoding
        print('Processing text file...');
        List<Encoding> encodings = [utf8, latin1, ascii];

        for (var encoding in encodings) {
          try {
            text = encoding.decode(bytes);
            if (text.trim().isNotEmpty) {
              print('Successfully decoded with ${encoding.name}');
              break;
            }
          } catch (e) {
            print('Failed to decode with ${encoding.name}: $e');
            continue;
          }
        }
      }

      if (text.trim().isEmpty) {
        throw Exception('No text could be extracted from the file');
      }

      // Clean up the text
      text = text
          .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]'),
              ' ') // Remove control characters
          .replaceAll(
              RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
          .trim();

      print('Text cleanup completed, final length: ${text.length}');
      return text;
    } catch (e) {
      print('Error extracting text from file: $e');
      throw Exception(
          'Could not extract text from the file. This might happen if:\n'
          '1. The file is password protected\n'
          '2. The file contains scanned images instead of text\n'
          '3. The file is corrupted\n\n'
          'Please make sure your file contains selectable text and try again.');
    }
  }

  Future<void> _analyzeCVFile() async {
    try {
      print('Starting file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withReadStream: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        print('No file selected');
        return;
      }

      setState(() {
        _isAnalyzing = true;
        _error = null;
        _analysisResult = null;
      });

      final file = result.files.first;
      print(
          'Selected file: ${file.name}, size: ${file.size} bytes, type: ${file.extension}');

      if (file.readStream == null) {
        throw Exception(
            'Could not read file content. Please try selecting the file again.');
      }

      final List<int> bytes = [];
      await for (var chunk in file.readStream!) {
        bytes.addAll(chunk);
      }

      final content = await _extractTextFromFile(
          Uint8List.fromList(bytes), file.extension ?? '');
      if (content.isEmpty) {
        throw Exception(
            'No text could be extracted from the file. Please ensure the file contains readable text.');
      }

      print(
          'Content extracted successfully, length: ${content.length} characters');
      if (content.length > 100) {
        print('First 100 characters: ${content.substring(0, 100)}');
      }

      print('Starting AI analysis...');
      final aiService = ref.read(aiServiceProvider);
      final analysis = await aiService.analyzeCVContentDetailed(content);

      if (!mounted) return;

      setState(() {
        _analysisResult = analysis;
        _isAnalyzing = false;
      });
    } catch (e, stackTrace) {
      print('Error in _analyzeCVFile: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceAll('Exception: ', '').replaceAll(
            'PlatformException(unknown_path, Failed to retrieve path., null, null)',
            'Could not access the selected file. Please try selecting the file again.');
        _isAnalyzing = false;
      });
    }
  }

  Future<String> _readFileContent(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        print('File bytes are null in _readFileContent');
        throw Exception('No file content available');
      }

      print('Attempting to read with UTF-8...');
      try {
        final content = utf8.decode(file.bytes!);
        print('Successfully read with UTF-8');
        return content;
      } catch (e) {
        print('UTF-8 decode failed, trying Latin1: $e');
        final content = latin1.decode(file.bytes!);
        print('Successfully read with Latin1');
        return content;
      }
    } catch (e, stackTrace) {
      print('Error in _readFileContent: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to read file content: $e');
    }
  }

  Widget _buildAnalysisView() {
    // Получаем текущую позицию из всех возможных полей
    String position = '';
    final positionData = _analysisResult!['position'];
    if (positionData != null && positionData.isNotEmpty) {
      for (var item in positionData) {
        if (item['description'] != null &&
            item['description'].toString().isNotEmpty) {
          position = item['description'].toString();
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Position Title
        if (position.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Current Position',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  position,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        // Recruiter's Summary
        if (_analysisResult!.containsKey('summary') &&
            _analysisResult!['summary']!.isNotEmpty)
          _buildSummarySection(
              'Recruiter\'s Feedback', _analysisResult!['summary']!),

        // CV Structure
        if (_analysisResult!.containsKey('structure') &&
            _analysisResult!['structure']!.isNotEmpty)
          _buildAnalysisSection('CV Structure', _analysisResult!['structure']!),

        // Areas for Improvement
        if (_analysisResult!.containsKey('improvements') &&
            _analysisResult!['improvements']!.isNotEmpty)
          _buildAnalysisSection(
              'Recommended Improvements', _analysisResult!['improvements']!),

        // Salary Analysis
        if (_analysisResult!.containsKey('salary') &&
            _analysisResult!['salary']!.isNotEmpty)
          _buildAnalysisSection('Salary Insights', _analysisResult!['salary']!),

        const SizedBox(height: 32),
        Center(
          child: ElevatedButton.icon(
            onPressed: _analyzeCVFile,
            icon: const Icon(Icons.refresh),
            label: const Text('Analyze Another CV'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  IconData _getFeedbackIcon(String title, String type) {
    final lowTitle = title.toLowerCase();
    if (lowTitle.contains('impression')) return Icons.remove_red_eye;
    if (lowTitle.contains('cv strength')) return Icons.description;
    if (lowTitle.contains('candidate strength')) return Icons.person;
    if (lowTitle.contains('quick win')) return Icons.flash_on;
    if (lowTitle.contains('missing')) return Icons.add_circle_outline;
    if (lowTitle.contains('market')) return Icons.trending_up;
    if (lowTitle.contains('negotiation')) return Icons.handshake;
    if (type == 'warning') return Icons.warning_amber;
    if (type == 'improvement') return Icons.build;
    if (type == 'suggestion') return Icons.lightbulb_outline;
    if (type == 'success') return Icons.check_circle_outline;
    return Icons.info_outline;
  }

  String _determineFeedbackType(String title, String description) {
    final lowerTitle = title.toLowerCase();
    final lowerDesc = description.toLowerCase();

    // Всегда помечаем сильные стороны как success
    if (lowerTitle.contains('strength') ||
        (lowerTitle.contains('impression') && !lowerDesc.contains('concern')) ||
        lowerTitle.contains('market range') ||
        lowerTitle.contains('negotiation')) {
      return 'success';
    }

    // Проверяем на предупреждения и улучшения (красный цвет)
    if (lowerTitle.contains('missing') ||
        lowerTitle.contains('concern') ||
        lowerTitle.contains('improvement') ||
        lowerTitle.contains('quick win') ||
        lowerDesc.contains('missing') ||
        lowerDesc.contains('lack') ||
        lowerDesc.contains('need to') ||
        lowerDesc.contains('should') ||
        lowerDesc.contains('must') ||
        lowerDesc.contains('require') ||
        lowerDesc.contains('improve') ||
        lowerDesc.contains('add more') ||
        lowerDesc.contains('not enough') ||
        lowerDesc.contains('too ') ||
        lowerDesc.contains('weak')) {
      return 'warning';
    }

    // Проверяем содержимое на позитивные индикаторы
    if (lowerDesc.contains('good') ||
        lowerDesc.contains('great') ||
        lowerDesc.contains('strong') ||
        lowerDesc.contains('solid') ||
        lowerDesc.contains('excellent') ||
        lowerDesc.contains('valuable') ||
        lowerDesc.contains('effective') ||
        lowerDesc.contains('impressive') ||
        lowerDesc.contains('well') ||
        lowerDesc.contains('clear') ||
        lowerDesc.contains('professional')) {
      return 'success';
    }

    // Предложения по улучшению (фиолетовый цвет)
    if (lowerDesc.contains('consider') ||
        lowerDesc.contains('could') ||
        lowerDesc.contains('suggest') ||
        lowerDesc.contains('try') ||
        lowerDesc.contains('might') ||
        lowerDesc.contains('would be') ||
        lowerDesc.contains('can ') ||
        lowerDesc.contains('recommendation')) {
      return 'suggestion';
    }

    return 'info';
  }

  Widget _buildSummarySection(String title, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            final itemTitle = item['title'] as String? ?? '';
            final description = item['description'] as String? ?? '';
            String feedbackType =
                _determineFeedbackType(itemTitle, description);

            final formattedDescription = description
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .map((line) => line.startsWith('•') ? line : '• $line')
                .join('\n\n');

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: _getIconBackgroundColor(feedbackType),
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getFeedbackIcon(itemTitle, feedbackType),
                          color: _getIconBackgroundColor(feedbackType),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            itemTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getIconBackgroundColor(feedbackType),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(String title, List<Map<String, dynamic>> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSectionIcon(title),
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) {
            final itemTitle = item['title'] as String? ?? '';
            final description = item['description'] as String? ?? '';
            String feedbackType =
                _determineFeedbackType(itemTitle, description);

            final formattedDescription = description
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .map((line) => line.startsWith('•') ? line : '• $line')
                .join('\n\n');

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: _getIconBackgroundColor(feedbackType),
                    width: 3,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getFeedbackIcon(itemTitle, feedbackType),
                          color: _getIconBackgroundColor(feedbackType),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            itemTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getIconBackgroundColor(feedbackType),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDescription,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.4,
                            leadingDistribution: TextLeadingDistribution.even,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    final lowTitle = title.toLowerCase();
    if (lowTitle.contains('structure')) return Icons.architecture;
    if (lowTitle.contains('improvement')) return Icons.trending_up;
    if (lowTitle.contains('salary')) return Icons.payments;
    if (lowTitle.contains('feedback')) return Icons.rate_review;
    return Icons.article;
  }

  Color _getIconBackgroundColor(String type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.green; // Используем стандартный зеленый
      case 'warning':
        return Colors.red; // Используем стандартный красный
      case 'improvement':
        return Colors.red; // Улучшения тоже красным
      case 'suggestion':
        return Colors.purple; // Предложения фиолетовым
      case 'info':
        return Colors.blue; // Информация синим
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _analysisResult?.containsKey('position') == true
        ? _analysisResult!['position']!.firstWhere(
                (item) =>
                    item['title']?.toLowerCase().contains('role') ?? false,
                orElse: () => {'description': ''})['description'] as String? ??
            ''
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('CV Analysis'),
            if (position.isNotEmpty)
              Text(
                position,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Analyzing your CV...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _analysisResult == null
                  ? _buildInitialView()
                  : _buildAnalysisView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error analyzing CV',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyzeCVFile,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.upload_file,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Upload your CV for analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Get detailed feedback and insights',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _analyzeCVFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CV'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
