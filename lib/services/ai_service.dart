import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIService {
  static final AIService _instance = AIService._internal();
  late final GenerativeModel _model;
  late ChatSession _chat;
  String? _cvContext;

  factory AIService() {
    return _instance;
  }

  AIService._internal() {
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
      _startNewChat();
    } catch (e) {
      debugPrint('Error initializing AI model: $e');
      rethrow;
    }
  }

  void _startNewChat() {
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

  Stream<String> streamMessage(String message) async* {
    try {
      if (_model == null) {
        await _initializeModel();
      }

      final response = _chat.sendMessageStream(Content.text(message));
      String buffer = '';

      await for (final chunk in response) {
        if (chunk.text != null) {
          buffer += chunk.text!;
          yield buffer.replaceAll('**', '').replaceAll('*', '').trim();
        }
      }
    } catch (e) {
      debugPrint('Error in streamMessage: $e');
      yield 'Error: Failed to get response from AI. Please try again.';
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

  Future<Map<String, dynamic>> analyzeCVContentDetailed(
      String cvContent) async {
    try {
      debugPrint('Starting CV analysis...');

      // Set CV context for future chat interactions
      setCVContext(cvContent);

      final prompt = '''
You are a senior hiring expert with 20+ years of experience in both technical (engineering, QA, DevOps, data) and non-technical (marketing, operations, sales, HR) roles. You've reviewed thousands of CVs and helped shape hiring pipelines in the German and EU job market.

You are now providing detailed CV assessments to support an AI career coaching assistant.

Your role:
- Quickly determine whether the CV is technical or non-technical
- Apply weighted scoring rules accordingly
- Deliver honest, specific, and constructive feedback that the user can act on today
- Avoid empty praise, vague suggestions, or generic advice

--- 

🧠 First, classify the CV into one of two types:
- `"cv_type": "technical"` → if it contains engineering, QA, IT, data, DevOps, development
- `"cv_type": "non_technical"` → for roles in marketing, business, pharmacy, sales, customer service, etc.

Use the appropriate scoring logic for each.

---

📊 Scoring Categories

**If technical:**
1. Technical Skills (40%)
2. Experience Impact (30%)
3. CV Presentation (20%)
4. Market Fit (10%)

**If non-technical:**
1. Role Expertise (35%)
2. Achievement Impact (35%)
3. CV Presentation (20%)
4. Market Fit (10%)

Assign a 0–100 score to each, then calculate the weighted total. Include a one-line summary.

---

📝 Feedback Types (mandatory tagging):
- `"success"` → Clear strength / market advantage
- `"warning"` → Major issue / potential dealbreaker
- `"improvement"` → Fixable weakness / missed potential
- `"suggestion"` → Optional enhancement / polish
- `"info"` → Purely descriptive (no opinion)

---

✅ Return JSON in the exact format below, no markdown, no extra text:

{  
  "score": {
    "value": 87,
    "message": "Strong technical profile with EU market potential, needs achievement metrics",
    "details": {
      "technical_skills": 90,
      "experience_impact": 85,
      "cv_presentation": 80,
      "market_fit": 75
    }
  },
  "cv_type": "technical",
  "position": [
    {
      "title": "Current Role",
      "description": "Senior Software Engineer @ Company",
      "type": "info"
    },
    {
      "title": "Seniority",
      "description": "Senior (5+ years)",
      "type": "info"
    }
  ],
  "summary": [
    {
      "title": "First Impression",
      "description": "Modern tech stack, active GitHub, clean structure",
      "type": "success"
    },
    {
      "title": "Key Strengths",
      "description": "Strong backend focus, cloud-native, agile experience",
      "type": "success"
    }
  ],
  "structure": [
    {
      "title": "Layout",
      "description": "Clean ATS-friendly format, good section hierarchy",
      "type": "success"
    },
    {
      "title": "Content Flow",
      "description": "Clear progression, easy to scan",
      "type": "success"
    }
  ],
  "improvements": [
    {
      "title": "Missing Metrics",
      "description": "Add specific impact numbers for key projects",
      "type": "warning"
    },
    {
      "title": "Tech Details",
      "description": "Specify versions and scale for key technologies",
      "type": "improvement"
    }
  ],
  "market_insights": [
    {
      "title": "Market Demand",
      "description": "High demand for this profile in Berlin/EU tech hubs",
      "type": "success"
    },
    {
      "title": "Industry Trends",
      "description": "Growing need for cloud-native skills in German market",
      "type": "info"
    }
  ],
  "salary": [
    {
      "title": "Range",
      "description": "€65-85K base + benefits (Berlin market rate)",
      "type": "info"
    },
    {
      "title": "Negotiation Points",
      "description": "Cloud certifications could push range up 10-15%",
      "type": "suggestion"
    }
  ],
  "expert_opinion": {
    "summary": "Strong technical foundation that matches current EU market needs. Your QA automation expertise combined with mobile testing focus creates a compelling profile for growing tech companies. Consider highlighting specific test frameworks and quantifiable improvements to testing efficiency.",
    "market_position": "Competitive for senior roles in Berlin tech scene",
    "unique_value": "Combination of backend expertise and cloud-native experience",
    "next_steps": "Add metrics, get cloud cert, highlight German market relevance"
  }
}

---

🎯 Final Rules:
- Expert opinion summary must be 2-3 sentences and include:
  1. Overall assessment of the profile
  2. Specific strengths and their market relevance
  3. Key opportunity for improvement
- Be direct, not polite
- Never use passive language
- Think like a real Berlin recruiter
- Don't repeat info across fields
- Only return valid JSON — no explanations

CV Content:
$cvContent
''';

      debugPrint('Sending request to AI...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        debugPrint('No response from AI');
        return _createFallbackResponse(
            'Sorry, we couldn\'t analyze your CV at the moment. Please try again in a few minutes.');
      }

      try {
        debugPrint('Parsing response...');
        final responseText = response.text!
            .trim()
            .replaceAll(RegExp(r'^```json\s*'), '')
            .replaceAll(RegExp(r'\s*```$'), '')
            .trim();

        debugPrint('Raw response: $responseText');

        final Map<String, dynamic> jsonResponse = json.decode(responseText);
        debugPrint('JSON decoded successfully');

        // Add CV content to response
        jsonResponse['cv_content'] = cvContent;

        // Validate required sections
        final requiredSections = [
          'score',
          'cv_type',
          'position',
          'summary',
          'structure',
          'improvements',
          'market_insights',
          'salary',
          'expert_opinion'
        ];

        for (final section in requiredSections) {
          if (!jsonResponse.containsKey(section)) {
            debugPrint('Missing required section: $section');
            throw Exception(
                'Invalid response format: missing $section section');
          }
        }

        // Validate score section
        final score = jsonResponse['score'] as Map<String, dynamic>? ?? {};
        if (!score.containsKey('value') ||
            !score.containsKey('message') ||
            !score.containsKey('details')) {
          debugPrint('Invalid score section structure');
          throw Exception('Invalid score section format');
        }

        return jsonResponse;
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        return _createFallbackResponse(
          'We had trouble processing the CV analysis. '
          'Please try again, and if the problem persists, try uploading a different version of your CV.',
        );
      }
    } catch (e) {
      debugPrint('Error in CV analysis: $e');
      return _createFallbackResponse(
        'We encountered an issue while analyzing your CV. '
        'Please try again in a few moments.',
      );
    }
  }

  bool _isEmptyResult(Map<String, dynamic> result) {
    if ((result['score']['value'] as num) == 0) return true;
    if (result['score']['message']?.isEmpty ?? true) return true;
    if ((result['score']['details'] as Map).isEmpty) return true;

    final sections = [
      'position',
      'summary',
      'structure',
      'improvements',
      'market_insights',
      'salary',
      'expert_opinion'
    ];
    return sections.every((section) =>
        !result.containsKey(section) ||
        (result[section] as List).isEmpty ||
        (result[section] as List).every((item) =>
            item is Map && (item['description']?.toString().isEmpty ?? true)));
  }

  List<Map<String, dynamic>> _convertToList(dynamic section) {
    if (section == null) return [];
    if (section is! List) return [];

    return section.map((item) {
      if (item is! Map<String, dynamic>) {
        return {'title': '', 'description': item.toString(), 'type': 'info'};
      }

      final type = item['type']?.toString() ??
          _determineFeedbackType(item['description']?.toString() ?? '');

      return {
        'title': item['title']?.toString() ?? '',
        'description': item['description']?.toString() ?? '',
        'type': type,
      };
    }).toList();
  }

  Map<String, dynamic> _createFallbackResponse(String message) {
    return {
      'score': {
        'value': 0,
        'message': message,
        'details': {
          'technical': 0,
          'experience': 0,
          'presentation': 0,
          'market_fit': 0
        }
      },
      'position': [],
      'summary': [
        {'title': 'Analysis Status', 'description': message, 'type': 'warning'}
      ],
      'structure': [],
      'improvements': [
        {
          'title': 'Suggestions',
          'description':
              'Make sure your CV is in a standard format and contains extractable text. '
                  'If you\'re using a PDF, ensure it\'s not scanned or image-based.',
          'type': 'suggestion'
        }
      ],
      'market_insights': [],
      'salary': [],
      'expert_opinion': {
        'summary': message,
        'market_position': message,
        'unique_value': message,
        'next_steps': message
      }
    };
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

  Future<void> clearUserData() async {
    _cvContext = null;
    _startNewChat();
  }
}
