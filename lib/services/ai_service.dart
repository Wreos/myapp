import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static final AIService _instance = AIService._internal();
  late final GenerativeModel _model;
  late ChatSession _chat;
  String? _cvContext;

  factory AIService() {
    return _instance;
  }

  void setCVContext(String cvContent) {
    _cvContext = cvContent;
    // Restart chat session with CV context
    _chat = _model.startChat(history: [
      Content.text('''
You are a concise and focused AI career coach. Follow these guidelines:
1. Keep responses short and actionable (2-3 paragraphs max)
2. Focus on practical, specific advice
3. Use bullet points for lists
4. Avoid generic advice and corporate jargon
5. When suggesting resources or next steps, limit to top 3 most relevant
6. If you need more context, ask a specific follow-up question

${_cvContext != null ? '''
Context from user's CV:
$_cvContext

Use this CV information to provide personalized advice when relevant.
''' : ''}
'''),
    ]);
  }

  void clearCVContext() {
    _cvContext = null;
    // Restart chat session without CV context
    _chat = _model.startChat(history: [
      Content.text('''
You are a concise and focused AI career coach. Follow these guidelines:
1. Keep responses short and actionable (2-3 paragraphs max)
2. Focus on practical, specific advice
3. Use bullet points for lists
4. Avoid generic advice and corporate jargon
5. When suggesting resources or next steps, limit to top 3 most relevant
6. If you need more context, ask a specific follow-up question
'''),
    ]);
  }

  AIService._internal() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
    _chat = _model.startChat(history: [
      Content.text('''
You are a concise and focused AI career coach. Follow these guidelines:
1. Keep responses short and actionable (2-3 paragraphs max)
2. Focus on practical, specific advice
3. Use bullet points for lists
4. Avoid generic advice and corporate jargon
5. When suggesting resources or next steps, limit to top 3 most relevant
6. If you need more context, ask a specific follow-up question
'''),
    ]);
  }

  Stream<String> streamMessage(String message) async* {
    try {
      final response = _chat.sendMessageStream(Content.text(message));
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

  Future<Map<String, List<Map<String, dynamic>>>> analyzeCVContentDetailed(
      String cvContent) async {
    try {
      print('Starting CV analysis...');

      // Set CV context for future chat interactions
      setCVContext(cvContent);

      final prompt = '''
You are a senior technical recruiter at a top-tier tech company in Berlin, specializing in hiring software engineers across international markets. 
Berlin is one of Europe's most competitive and English-first tech hubs. You are known for giving sharp, honest, and practical feedback that helps candidates grow and succeed.

Your job is to assess the CV below and provide straightforward, constructive feedback — the kind you'd give if the candidate were sitting across the table from you.

--- 

🔹 Feedback Types – choose carefully for each item:
- "success" → For anything positive or advantageous:
  • Strong achievements  
  • Clear formatting or layout  
  • Relevant skills or standout experience  
  • Signs of high potential  
  • Competitive market value  
- "warning" → For serious concerns or red flags (e.g., major gaps, unclear job history)
- "improvement" → For anything that's currently weak or underdeveloped, but fixable
- "suggestion" → For optional ideas that could elevate the CV further
- "info" → Use only for neutral facts with no evaluation (e.g., job title, last role, years worked)

📌 Return a valid JSON matching the exact structure below – with no extra commentary, markdown, or code fences.

{
  "position": [
    { "title": "Current Role", "description": "Current or last position", "type": "info" },
    { "title": "Level", "description": "Seniority level assessment", "type": "info" }
  ],
  "summary": [
    { "title": "First Impression", "description": "Your immediate reaction to the CV — highlight what stands out most. If the first impression is even slightly positive, mark this as type: success", "type": "success" },
    { "title": "CV Strengths", "description": "What makes the document effective (clarity, formatting, structure)?", "type": "success" },
    { "title": "Candidate Strengths", "description": "What technical or professional strengths are clearly visible?", "type": "success" },
    { "title": "Main Concerns", "description": "What are the top issues that could prevent this candidate from progressing?", "type": "warning" }
  ],
  "structure": [
    { "title": "Document Format", "description": "Evaluate clarity, spacing, fonts, and overall layout", "type": "success" },
    { "title": "Information Flow", "description": "How well is the story of the career progression told?", "type": "success" },
    { "title": "Visual Appeal", "description": "Is the document visually readable, modern, and professional?", "type": "success" }
  ],
  "improvements": [
    { "title": "Quick Wins", "description": "Low-effort changes with high impact (e.g., rewording bullets, restructuring sections)", "type": "improvement" },
    { "title": "Missing Elements", "description": "What critical sections or details are absent?", "type": "warning" },
    { "title": "Presentation Tips", "description": "How could the candidate make their results or impact pop more?", "type": "suggestion" }
  ],
  "salary": [
    { "title": "Market Range", "description": "Estimate a fair Berlin-based salary range for this candidate based on their profile and experience", "type": "success" },
    { "title": "Negotiation Points", "description": "What strengths can the candidate leverage in salary or role negotiations?", "type": "success" }
  ]
}

---

🔍 Style Guidelines  
1. Feedback must be direct and specific — no fluff, no generic compliments  
2. Use concrete examples whenever suggesting changes  
3. Show real understanding of Berlin tech job market trends  
4. Keep the tone professional, honest, and helpful — not robotic or vague  
5. No corporate buzzwords. No passive phrasing. Be human.  
6. Use bullet points (•) where helpful — not asterisks or hyphens  
7. Avoid repeating the same feedback across multiple sections  
8. Assume the candidate is international and English-speaking (German not required)  
9. If something is a strength, always mark as "success" — never hide it  
10. Respond ONLY in valid JSON. Nothing else.

CV Content:
$cvContent
''';

      print('Sending request to AI...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        return _createFallbackResponse(
            'Sorry, we couldn\'t analyze your CV at the moment. Please try again in a few minutes.');
      }

      try {
        print('Parsing response...');
        final responseText = response.text!
            .trim()
            .replaceAll(RegExp(r'^```json\s*'), '')
            .replaceAll(RegExp(r'\s*```$'), '')
            .trim();

        final Map<String, dynamic> jsonResponse = json.decode(responseText);
        print('Response parsed successfully');

        final result = {
          'summary': _convertToList(jsonResponse['summary']),
          'structure': _convertToList(jsonResponse['structure']),
          'improvements': _convertToList(jsonResponse['improvements']),
          'salary': _convertToList(jsonResponse['salary']),
        };

        if (result.values.every((list) => list.isEmpty)) {
          return _createFallbackResponse(
            'We analyzed your CV but couldn\'t generate detailed feedback. '
            'Please try uploading a different version of your CV.',
          );
        }

        return result;
      } catch (e) {
        print('JSON parsing error: $e');
        return _createFallbackResponse(
          'We had trouble processing the CV analysis. '
          'Please try again, and if the problem persists, try uploading a different version of your CV.',
        );
      }
    } catch (e) {
      print('Error in CV analysis: $e');
      return _createFallbackResponse(
        'We encountered an issue while analyzing your CV. '
        'Please try again in a few moments.',
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _createFallbackResponse(
      String message) {
    return {
      'summary': [
        {
          'type': 'info',
          'title': 'Analysis Status',
          'description': message,
        }
      ],
      'improvements': [
        {
          'type': 'suggestion',
          'title': 'Suggestions',
          'description':
              'Make sure your CV is in a standard format and contains extractable text. '
                  'If you\'re using a PDF, ensure it\'s not scanned or image-based.',
        }
      ],
    };
  }

  List<Map<String, dynamic>> _convertToList(dynamic section) {
    if (section == null) return [];
    if (section is! List) return [];

    return section.map((item) {
      if (item is! Map) {
        return {'title': '', 'description': item.toString(), 'type': 'info'};
      }

      return {
        'title': item['title'] ?? '',
        'description': item['description'] ?? '',
        'type': _determineFeedbackType(item['description'] ?? ''),
      };
    }).toList();
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
      return 'success';
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
