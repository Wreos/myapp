import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static final AIService _instance = AIService._internal();
  late final GenerativeModel _model;
  late final ChatSession _chat;

  factory AIService() {
    return _instance;
  }

  AIService._internal() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
    _chat = _model.startChat();
  }

  Stream<String> streamMessage(String message) async* {
    try {
      final response = await _chat.sendMessageStream(Content.text(message));
      String buffer = '';

      await for (final chunk in response) {
        if (chunk.text != null) {
          buffer += chunk.text!;
          yield buffer.replaceAll('**', '').replaceAll('*', '').trim();
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(Content.text(message));
      return (response.text ?? 'No response from AI')
          .replaceAll('**', '')
          .replaceAll('*', '')
          .trim();
    } catch (e) {
      return 'Error: $e';
    }
  }

  Stream<Map<String, dynamic>> analyzeCVContentDetailedStream(
      String cvContent) async* {
    try {
      const basePrompt = '''
You are an experienced technical recruiter specializing in software engineering roles. Provide a detailed, professional analysis of this CV.

For each section, format your response with clear headings and bullet points. Be specific and actionable in your feedback.

Guidelines:
- Focus on technical and professional growth opportunities
- Highlight both strengths and areas for improvement
- Provide concrete, actionable recommendations
- Consider market trends and industry standards
- Be direct but constructive in feedback

Please analyze and respond in detail for each section.
''';

      // Initialize result map
      Map<String, dynamic> result = {
        'summary': [],
        'content': [],
        'seniority': [],
        'structure': [],
        'improvements': [],
        'salary': [],
      };

      // Summary Assessment
      final summaryPrompt = '''$basePrompt
Provide a comprehensive overview of the candidate's profile:

1. Current Position & Level
   - Current role and responsibilities
   - Seniority assessment
   - Industry focus

2. Core Technical Competencies
   - Primary technical skills
   - Technical specializations
   - Tool proficiency

3. Professional Capabilities
   - Leadership experience
   - Project management skills
   - Team collaboration

4. Overall Assessment
   - Key strengths
   - Notable achievements
   - Career trajectory

CV Content:
$cvContent
''';

      final summaryStream =
          _model.generateContentStream([Content.text(summaryPrompt)]);
      await for (final chunk in summaryStream) {
        if (chunk.text != null) {
          result['summary'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }

      // Content Quality
      final contentPrompt = '''$basePrompt
Analyze the quality and impact of the experience section:

1. Technical Projects
   - Complexity and scope
   - Technologies utilized
   - Problem-solving approaches

2. Professional Impact
   - Quantifiable achievements
   - Project outcomes
   - Team contributions

3. Technical Growth
   - Skill progression
   - Learning trajectory
   - Technical challenges tackled

CV Content:
$cvContent
''';

      final contentStream =
          _model.generateContentStream([Content.text(contentPrompt)]);
      await for (final chunk in contentStream) {
        if (chunk.text != null) {
          result['content'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }

      // Seniority Assessment
      final seniorityPrompt = '''$basePrompt
Evaluate career level and progression:

1. Current Level Assessment
   - Technical seniority
   - Leadership capability
   - Domain expertise

2. Career Progression
   - Growth trajectory
   - Role transitions
   - Skill advancement

3. Next Career Steps
   - Potential roles
   - Required capabilities
   - Growth opportunities

CV Content:
$cvContent
''';

      final seniorityStream =
          _model.generateContentStream([Content.text(seniorityPrompt)]);
      await for (final chunk in seniorityStream) {
        if (chunk.text != null) {
          result['seniority'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }

      // Structure Analysis
      final structurePrompt = '''$basePrompt
Review CV structure and presentation:

1. Document Organization
   - Section flow
   - Information hierarchy
   - Content completeness

2. Technical Presentation
   - Skills presentation
   - Project descriptions
   - Technical achievements

3. Professional Format
   - Layout effectiveness
   - Readability
   - Professional standards

CV Content:
$cvContent
''';

      final structureStream =
          _model.generateContentStream([Content.text(structurePrompt)]);
      await for (final chunk in structureStream) {
        if (chunk.text != null) {
          result['structure'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }

      // Improvement Suggestions
      final improvementPrompt = '''$basePrompt
Provide specific improvement recommendations:

1. Technical Enhancements
   - Skill gaps to address
   - Technical certifications
   - Learning priorities

2. Professional Development
   - Leadership opportunities
   - Industry involvement
   - Career positioning

3. CV Optimization
   - Content improvements
   - Format refinements
   - Impact enhancement

Provide specific, actionable steps for each area.

CV Content:
$cvContent
''';

      final improvementStream =
          _model.generateContentStream([Content.text(improvementPrompt)]);
      await for (final chunk in improvementStream) {
        if (chunk.text != null) {
          result['improvements'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }

      // Market Position
      final salaryPrompt = '''$basePrompt
As a senior technical recruitment consultant specializing in Berlin's tech market for 20+ years, I'll provide a detailed compensation analysis for your QA/Development profile.

• Role Level: Analyze current position and market alignment
  - Assess current role classification
  - Review years of relevant QA/Dev experience
  - Evaluate technical leadership scope

• Current Market Range (Berlin, Gross Annual)
  - Junior QA Automation: €45,000 - €65,000
  - Mid-Level QA Automation: €60,000 - €85,000
  - Senior QA Automation: €75,000 - €95,000
  - Lead QA Automation: €85,000 - €120,000

• Premium Value Factors
  - Cloud automation expertise: +10-15%
  - Test framework architecture: +5-10%
  - CI/CD pipeline mastery: +5-10%
  - German language skills: +5-15%

• Growth Potential
  - Next role target range
  - Key certifications impact
  - Leadership track premium
  - Timeline to next level

• Market Insights
  - Current Berlin tech demand
  - Industry sector premiums
  - Remote work impact
  - Q1 2024 trends

Note: All figures represent base salary in EUR, excluding benefits, bonus, and equity components. Data based on active Berlin tech market placements in Q1 2024.

CV Content:
$cvContent
''';

      final salaryStream =
          _model.generateContentStream([Content.text(salaryPrompt)]);
      await for (final chunk in salaryStream) {
        if (chunk.text != null) {
          result['salary'] = _parseFeedbackSection(chunk.text!);
          yield result;
        }
      }
    } catch (e) {
      yield {
        'error': 'Error analyzing CV: $e',
      };
    }
  }

  List<Map<String, dynamic>> _parseFeedbackSection(String feedback) {
    final List<Map<String, dynamic>> feedbackList = [];

    // Clean up the text first
    feedback = feedback.replaceAll('**', '').replaceAll('*', '').trim();

    // Split into sections by numbers or bullet points
    final sections = feedback.split(RegExp(r'\n(?=\d+\.|[-•])'));

    for (var section in sections) {
      if (section.trim().isEmpty) continue;

      // Parse section title and content
      var match = RegExp(r'^(?:\d+\.|[-•])\s*([^:]+):\s*(.+)$', dotAll: true)
          .firstMatch(section.trim());

      if (match != null) {
        feedbackList.add({
          'type': _determineFeedbackType(match.group(2)!),
          'title': match.group(1)!.trim(),
          'description': match.group(2)!.trim(),
        });
      } else {
        // Handle bullet points without explicit titles
        var cleanSection =
            section.replaceAll(RegExp(r'^[-•\d.]\s*'), '').trim();
        if (cleanSection.isNotEmpty) {
          feedbackList.add({
            'type': _determineFeedbackType(cleanSection),
            'title': '',
            'description': cleanSection,
          });
        }
      }
    }

    return feedbackList;
  }

  String _determineFeedbackType(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('missing') ||
        lowerText.contains('weak') ||
        lowerText.contains('lack') ||
        lowerText.contains('need') ||
        lowerText.contains('should') ||
        lowerText.contains('improve')) {
      return 'improvement';
    } else if (lowerText.contains('consider') ||
        lowerText.contains('could') ||
        lowerText.contains('suggest') ||
        lowerText.contains('recommend')) {
      return 'suggestion';
    } else if (lowerText.contains('strong') ||
        lowerText.contains('excellent') ||
        lowerText.contains('good') ||
        lowerText.contains('well')) {
      return 'strength';
    }

    return 'info';
  }

  Future<String> analyzeCVContent(String cvContent) async {
    try {
      final prompt = '''
Analyze this CV/resume and provide detailed feedback in the following areas:
1. Overall Structure and Format
2. Content Quality and Impact
3. Skills Presentation
4. Experience Descriptions
5. Areas for Improvement

CV Content:
$cvContent
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'No analysis available';
    } catch (e) {
      return 'Error analyzing CV: $e';
    }
  }

  Future<List<Map<String, String>>> suggestCareerGoals(
      String userProfile) async {
    try {
      final prompt = '''
Based on this user profile, suggest 3 specific, achievable career goals with timeframes:

User Profile:
$userProfile

Format each goal as:
- Title
- Description
- Suggested Timeline
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final suggestions = response.text?.split('\n\n') ?? [];

      return suggestions.map((suggestion) {
        final parts = suggestion.split('\n');
        return {
          'title': parts[0].replaceAll('- ', ''),
          'description': parts[1].replaceAll('- ', ''),
          'timeline': parts[2].replaceAll('- ', ''),
        };
      }).toList();
    } catch (e) {
      return [
        {
          'title': 'Error',
          'description': 'Failed to generate goals: $e',
          'timeline': 'N/A',
        },
      ];
    }
  }

  Future<String> getWeeklyCheckInPrompt() async {
    try {
      const prompt = '''
Generate a personalized weekly check-in prompt for a career coaching session. 
Focus on progress, challenges, and next steps. Keep it encouraging and action-oriented.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ??
          'How has your week been? Let\'s discuss your progress.';
    } catch (e) {
      return 'How has your week been? Let\'s discuss your progress.';
    }
  }

  Future<String> getCareerAdvice({
    required String currentSkills,
    required String interests,
    required String experience,
  }) async {
    final prompt = [
      Content.text('''
Based on the following information, provide detailed career advice:
- Current Skills: $currentSkills
- Interests: $interests
- Years of Experience: $experience

Please provide:
1. Recommended career paths
2. Skills to develop
3. Potential job roles
4. Learning resources
5. Industry trends to watch
''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text ?? 'Unable to generate career advice at the moment.';
    } catch (e) {
      return 'Error generating career advice: $e';
    }
  }

  Future<String> getSkillsGapAnalysis({
    required String targetRole,
    required String currentSkills,
  }) async {
    final prompt = [
      Content.text('''
Analyze the skills gap for the following:
- Target Role: $targetRole
- Current Skills: $currentSkills

Please provide:
1. Missing critical skills
2. Recommended learning path
3. Estimated time to acquire these skills
4. Certification recommendations
''')
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text ??
          'Unable to generate skills gap analysis at the moment.';
    } catch (e) {
      return 'Error generating skills gap analysis: $e';
    }
  }

  bool _isCareerRelated(String prompt) {
    final careerKeywords = [
      'career',
      'job',
      'skills',
      'resume',
      'cv',
      'interview',
      'profession',
      'work',
      'salary',
      'industry',
    ];

    final lowercasePrompt = prompt.toLowerCase();
    return careerKeywords.any((keyword) => lowercasePrompt.contains(keyword));
  }

  Future<String> _handleCareerQuery(String prompt) async {
    if (prompt.contains('skills') || prompt.contains('experience')) {
      return await getCareerAdvice(
        currentSkills: _extractSkills(prompt),
        interests: _extractInterests(prompt),
        experience: _extractExperience(prompt),
      );
    }

    if (prompt.contains('gap') || prompt.contains('requirements')) {
      return await getSkillsGapAnalysis(
        targetRole: _extractTargetRole(prompt),
        currentSkills: _extractSkills(prompt),
      );
    }

    // Default career advice
    return await getCareerAdvice(
      currentSkills: prompt,
      interests: '',
      experience: '',
    );
  }

  String _extractSkills(String prompt) {
    final skillsMatch = RegExp(r'skills:?\s*([^.!?\n]+)', caseSensitive: false)
        .firstMatch(prompt);
    return skillsMatch?.group(1)?.trim() ?? prompt;
  }

  String _extractInterests(String prompt) {
    final interestsMatch =
        RegExp(r'interests?:?\s*([^.!?\n]+)', caseSensitive: false)
            .firstMatch(prompt);
    return interestsMatch?.group(1)?.trim() ?? '';
  }

  String _extractExperience(String prompt) {
    final experienceMatch =
        RegExp(r'experience:?\s*([^.!?\n]+)', caseSensitive: false)
            .firstMatch(prompt);
    return experienceMatch?.group(1)?.trim() ?? '';
  }

  String _extractTargetRole(String prompt) {
    final roleMatch = RegExp(r'role:?\s*([^.!?\n]+)', caseSensitive: false)
        .firstMatch(prompt);
    return roleMatch?.group(1)?.trim() ?? '';
  }
}
