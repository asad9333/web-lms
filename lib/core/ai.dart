import 'dart:convert';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'files.dart';
import 'models.dart';
import 'repo.dart';
import 'utils.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// API keys / models are stored on the device (Settings screen) because the
/// app has no server-side .env file any more.
class AiSettings {
  AiSettings._();

  static const String _kGeminiKey = 'ai_gemini_key';
  static const String _kGeminiModel = 'ai_gemini_model';
  static const String _kGroqKey = 'ai_groq_key';
  static const String _kGroqModel = 'ai_groq_model';

  static const String defaultGeminiModel = 'gemini-3.6-flash';
  static const String defaultGroqModel = 'llama-3.3-70b-versatile';

  static Future<Map<String, String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'geminiKey': prefs.getString(_kGeminiKey) ?? '',
      'geminiModel': prefs.getString(_kGeminiModel) ?? defaultGeminiModel,
      'groqKey': prefs.getString(_kGroqKey) ?? '',
      'groqModel': prefs.getString(_kGroqModel) ?? defaultGroqModel,
    };
  }

  static Future<void> save({
    required String geminiKey,
    required String geminiModel,
    required String groqKey,
    required String groqModel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiKey, geminiKey.trim());
    await prefs.setString(_kGeminiModel,
        geminiModel.trim().isEmpty ? defaultGeminiModel : geminiModel.trim());
    await prefs.setString(_kGroqKey, groqKey.trim());
    await prefs.setString(_kGroqModel,
        groqModel.trim().isEmpty ? defaultGroqModel : groqModel.trim());
  }
}

/// Gemini first, automatic Groq fallback (text only) - same as the web app.
class AiClient {
  AiClient._();

  static const int maxInlineBytes = 14 * 1024 * 1024;
  static const Duration _timeout = Duration(seconds: 180);

  static String _short(Object? e) {
    final s = '$e';
    return s.length > 300 ? '${s.substring(0, 300)}...' : s;
  }

  static Future<String> generate(String prompt, {int maxTokens = 2048}) async {
    Object? geminiError;
    try {
      return await _callGemini(
          <Map<String, dynamic>>[
            {'text': prompt}
          ],
          maxTokens);
    } catch (e) {
      geminiError = e;
      debugPrint('Gemini failed, falling back to Groq: $e');
    }
    try {
      return await _callGroq(prompt, maxTokens);
    } catch (e) {
      throw AiException(
          'AI request failed. Gemini: ${_short(geminiError)} | Groq: ${_short(e)}');
    }
  }

  /// Sends a file (PDF or image) plus prompt to Gemini. No Groq fallback
  /// because the Groq model is text-only.
  static Future<String> generateWithFile(
      String prompt, List<int> bytes, String mimeType,
      {int maxTokens = 2048}) async {
    if (bytes.length > maxInlineBytes) {
      throw AiException('File is too large for AI (max about 14 MB).');
    }
    return _callGemini(<Map<String, dynamic>>[
      {
        'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)}
      },
      {'text': prompt},
    ], maxTokens);
  }

  static Future<String> _callGemini(
      List<Map<String, dynamic>> parts, int maxTokens) async {
    final cfg = await AiSettings.load();
    final key = cfg['geminiKey'] ?? '';
    if (key.isEmpty) {
      throw AiException(
          'Gemini API key not set. Open Settings > AI Settings and add it.');
    }
    final model = cfg['geminiModel'] ?? AiSettings.defaultGeminiModel;
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {'parts': parts}
            ],
            'generationConfig': {
              'maxOutputTokens': maxTokens,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AiException(
          'Gemini request failed (${res.statusCode}): ${_short(res.body)}');
    }
    String? text;
    try {
      final data = jsonDecode(res.body);
      final list = data['candidates'][0]['content']['parts'] as List;
      final buf = StringBuffer();
      for (final part in list) {
        final t = part['text'];
        if (t is String) buf.write(t);
      }
      text = buf.toString();
    } catch (_) {
      text = null;
    }
    if (text == null || text.trim().isEmpty) {
      throw AiException('Gemini returned an empty response.');
    }
    return text;
  }

  static Future<String> _callGroq(String prompt, int maxTokens) async {
    final cfg = await AiSettings.load();
    final key = cfg['groqKey'] ?? '';
    if (key.isEmpty) {
      throw AiException('GROQ API key not set.');
    }
    final model = cfg['groqModel'] ?? AiSettings.defaultGroqModel;
    final res = await http
        .post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content':
                    '$prompt\n\nRespond with ONLY valid JSON, no markdown fences, no extra text.',
              }
            ],
            'max_tokens': maxTokens,
            'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(_timeout);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AiException(
          'Groq request failed (${res.statusCode}): ${_short(res.body)}');
    }
    String? text;
    try {
      final data = jsonDecode(res.body);
      final c = data['choices'][0]['message']['content'];
      text = c is String ? c : null;
    } catch (_) {
      text = null;
    }
    if (text == null || text.trim().isEmpty) {
      throw AiException('Groq returned an empty response.');
    }
    return text;
  }

  // --------------------------------------------------------- JSON helpers

  static String _stripFences(String text) {
    var t = text.trim();
    t = t.replaceAll(RegExp(r'^```(json)?', multiLine: true), '');
    t = t.replaceAll(RegExp(r'```$', multiLine: true), '');
    return t.trim();
  }

  static Map<String, dynamic>? extractJsonObject(String? text) {
    if (text == null) return null;
    final t = _stripFences(text);
    try {
      final d = jsonDecode(t);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    final m = RegExp(r'\{.*\}', dotAll: true).firstMatch(t);
    if (m != null) {
      try {
        final d = jsonDecode(m.group(0)!);
        if (d is Map<String, dynamic>) return d;
      } catch (_) {}
    }
    return null;
  }

  static List<dynamic>? extractQuestionList(String? text) {
    if (text == null) return null;
    final t = _stripFences(text);
    try {
      final d = jsonDecode(t);
      if (d is Map && d['questions'] is List) return d['questions'] as List;
      if (d is List) return d;
    } catch (_) {}
    final obj = extractJsonObject(t);
    if (obj != null && obj['questions'] is List) {
      return obj['questions'] as List;
    }
    final m = RegExp(r'\[.*\]', dotAll: true).firstMatch(t);
    if (m != null) {
      try {
        final d = jsonDecode(m.group(0)!);
        if (d is List) return d;
      } catch (_) {}
    }
    return null;
  }

  static String? extractDocxText(List<int> bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final f in archive.files) {
        if (f.name == 'word/document.xml') {
          final content = f.content as List<int>;
          var xml = utf8.decode(content, allowMalformed: true);
          xml = xml.replaceAll('</w:p>', '\n');
          xml = xml.replaceAll(RegExp(r'<[^>]+>'), ' ');
          xml = xml
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&apos;', "'");
          xml = xml.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (xml.isEmpty) return null;
          return xml.length > 20000 ? xml.substring(0, 20000) : xml;
        }
      }
    } catch (_) {}
    return null;
  }
}

/// Reads a course material PDF from app storage (AI drafting works on PDFs).
Future<List<int>> _readMaterialPdf(CourseMaterial material) async {
  if (!material.filePath.toLowerCase().endsWith('.pdf')) {
    throw AiException(
        'AI drafting works with PDF materials only. Please pick a PDF material.');
  }
  final file = await FileStore.resolve(material.filePath);
  if (!await file.exists()) {
    throw AiException('Material file not found on this device.');
  }
  return file.readAsBytes();
}

// ============================================================ quiz drafting

class AiQuizGenerator {
  AiQuizGenerator._();

  static Future<List<QuestionDraft>> draftQuestions({
    required Course course,
    required CourseMaterial material,
    required String range,
    required int totalMarks,
    required String mix,
  }) async {
    final covered = await Repo.coveredTopics(course.id);
    final bytes = await _readMaterialPdf(material);

    final String mixInstruction;
    if (mix == 'mcq_only') {
      mixInstruction = 'Every question must be type "mcq" with exactly 4 options.';
    } else if (mix == 'written_only') {
      mixInstruction =
          'Every question must be type "short" (written answer), no MCQs.';
    } else {
      mixInstruction =
          'Use a mix of MCQ (4 options) and short-answer (written) questions.';
    }

    final prompt = '''
You are drafting a quiz for the course "${course.title}".

Only cover these topics (already taught): $covered

The attached PDF is the study material. Restrict the questions strictly to this part of the material: $range

The quiz must add up to exactly $totalMarks total marks. Decide how many
questions are needed and how many marks each one is worth so the marks sum
to $totalMarks - do not just write one question per mark.

$mixInstruction

For MCQ questions, "correct_answer" must be the exact text of one of the options (not just a letter).

Respond with ONLY a JSON object, no other text, no markdown code fences, in exactly this shape:
{"questions": [
  {"question_text": "...", "type": "mcq", "options": ["option 1", "option 2", "option 3", "option 4"], "correct_answer": "option 1", "marks": 2},
  {"question_text": "...", "type": "short", "options": [], "correct_answer": "expected answer", "marks": 2}
]}
''';

    final text = await AiClient.generateWithFile(
        prompt, bytes, 'application/pdf',
        maxTokens: 8192);
    final raw = AiClient.extractQuestionList(text);
    if (raw == null || raw.isEmpty) {
      debugPrint('Could not parse quiz questions. Raw AI response: $text');
      throw AiException('Could not parse quiz questions from AI response.');
    }

    final out = <QuestionDraft>[];
    for (final q in raw) {
      if (q is! Map) continue;
      var type = (q['type'] ?? '').toString().toLowerCase() == 'short'
          ? 'short'
          : 'mcq';
      if (mix == 'mcq_only') type = 'mcq';
      if (mix == 'written_only') type = 'short';

      var options = <String>[];
      if (q['options'] is List) {
        options = (q['options'] as List).map((e) => e.toString()).toList();
      }
      var correct = (q['correct_answer'] ?? '').toString().trim();

      if (type == 'mcq') {
        while (options.length < 4) {
          options.add('');
        }
        final matches = options
            .any((o) => o.trim().toLowerCase() == correct.toLowerCase());
        if (!matches) {
          final idx = _letterIndex(correct);
          if (idx != null && idx < options.length) {
            correct = options[idx];
          }
        }
      } else {
        options = <String>['', '', '', ''];
      }

      out.add(QuestionDraft(
        questionText: (q['question_text'] ?? '').toString(),
        type: type,
        options: options,
        correctAnswer: correct,
        marks: max(1, toInt(q['marks'], 1)),
      ));
    }
    if (out.isEmpty) {
      throw AiException('Could not parse quiz questions from AI response.');
    }
    return out;
  }

  static int? _letterIndex(String s) {
    var t = s.trim().toLowerCase();
    if (t.endsWith(')') || t.endsWith('.')) {
      t = t.substring(0, t.length - 1);
    }
    if (t.length != 1) return null;
    final code = t.codeUnitAt(0) - 97;
    if (code < 0 || code > 25) return null;
    return code;
  }
}

// ======================================================== assignment drafting

class AiAssignmentGenerator {
  AiAssignmentGenerator._();

  static Future<AssignmentDraft> draftAssignment({
    required Course course,
    required CourseMaterial material,
    required String range,
    required int totalMarks,
  }) async {
    final covered = await Repo.coveredTopics(course.id);
    final bytes = await _readMaterialPdf(material);

    final prompt = '''
You are drafting a course assignment for "${course.title}".

Only cover these topics (already taught): $covered

The attached PDF is the study material. Restrict the assignment strictly to this part of the material: $range

The assignment should be worth around $totalMarks total marks (you may
adjust slightly if it makes more sense pedagogically).

Write:
- A short, clear title for the assignment
- Full description/instructions for the student (what to do, what to submit, how it will be evaluated)
- The topics it covers (comma separated)
- The total marks

Respond with ONLY a JSON object, no other text, no markdown code fences, in exactly this shape:
{"title": "...", "description": "...", "topics_covered": "...", "total_marks": 20}
''';

    final text = await AiClient.generateWithFile(
        prompt, bytes, 'application/pdf',
        maxTokens: 4096);
    final obj = AiClient.extractJsonObject(text);
    if (obj == null) {
      debugPrint('Could not parse assignment draft. Raw AI response: $text');
      throw AiException('Could not parse assignment draft from AI response.');
    }
    return AssignmentDraft(
      title: (obj['title'] ?? '').toString(),
      description: (obj['description'] ?? '').toString(),
      totalMarks: max(1, toInt(obj['total_marks'], totalMarks)),
    );
  }
}

// ================================================================== grading

class GradeResult {
  final bool graded;
  final String? error;
  const GradeResult.ok()
      : graded = true,
        error = null;
  const GradeResult.fail(String message)
      : graded = false,
        error = message;
}

class AiGrader {
  AiGrader._();

  static const Map<String, String> _imageMimes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static bool _sameText(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// MCQ = exact match. Short answers = AI (partial credit), falling back to
  /// exact match if the AI call fails. Always saves score + checked_at.
  static Future<void> gradeQuizSubmission(QuizSubmission submission) async {
    final questions = await Repo.questionsOf(submission.quizId);
    var score = 0;

    for (final q in questions) {
      final given = submission.answers[q.id.toString()];
      if (given == null || given.trim().isEmpty) continue;

      if (q.isMcq) {
        if (_sameText(given, q.correctAnswer)) score += q.marks;
        continue;
      }

      try {
        score += await _gradeShortAnswer(
            q.questionText, q.correctAnswer, given, q.marks);
      } catch (e) {
        debugPrint('AI short-answer grading failed, using exact match: $e');
        if (_sameText(given, q.correctAnswer)) score += q.marks;
      }
    }

    await Repo.setQuizScore(submission.id, score);
  }

  static Future<int> _gradeShortAnswer(
      String question, String expected, String given, int maxMarks) async {
    final prompt = '''
Question: $question
Expected/model answer: $expected
Student's answer: $given
Maximum marks: $maxMarks

Grade the student's answer against the expected answer, allowing for different
wording that means the same thing. Give partial credit where reasonable.

Respond with ONLY a JSON object, no other text, no markdown code fences:
{"marks": <integer 0 to $maxMarks>}
''';
    final text = await AiClient.generate(prompt, maxTokens: 1024);
    final obj = AiClient.extractJsonObject(text);
    final marks = toInt(obj == null ? 0 : obj['marks']);
    return min(max(marks, 0), maxMarks);
  }

  static Future<GradeResult> gradeAssignmentSubmission(
      AssignmentSubmission submission, Assignment assignment) async {
    try {
      final file = await FileStore.resolve(submission.filePath);
      if (!await file.exists()) {
        return const GradeResult.fail(
            'Submission file was not found on this device.');
      }
      final ext = p.extension(file.path).toLowerCase().replaceFirst('.', '');
      final bytes = await file.readAsBytes();

      final header = '''
You are grading a student assignment submission for a course.

Assignment title: ${assignment.title}
Assignment instructions: ${assignment.description ?? ''}
Topics this assignment covers: ${assignment.topicsCovered ?? ''}
Total marks available: ${assignment.totalMarks}
''';
      final footer = '''
Respond with ONLY a JSON object, no other text, no markdown code fences, in
exactly this shape:
{"score": <integer 0 to ${assignment.totalMarks}>, "feedback": "<2-4 sentence feedback for the student>"}
''';

      String raw;
      if (ext == 'pdf') {
        raw = await AiClient.generateWithFile(
            '$header\nThe attached PDF is the student\'s submitted work. Grade it against the instructions and topics above.\n\n$footer',
            bytes,
            'application/pdf',
            maxTokens: 2048);
      } else if (ext == 'docx') {
        final text = AiClient.extractDocxText(bytes);
        if (text == null) {
          return const GradeResult.fail(
              'Could not read text from this docx file - please grade it manually.');
        }
        raw = await AiClient.generate(
            '$header\n--- SUBMITTED WORK START ---\n$text\n--- SUBMITTED WORK END ---\n\nGrade the submitted work against the instructions and topics above.\n\n$footer',
            maxTokens: 2048);
      } else if (_imageMimes.containsKey(ext)) {
        raw = await AiClient.generateWithFile(
            '$header\nLook at the attached image, which is a photo/scan of the student\'s submitted work (it may be handwritten), and grade it against the instructions and topics above.\n\n$footer',
            bytes,
            _imageMimes[ext]!,
            maxTokens: 2048);
      } else {
        return GradeResult.fail(
            'AI cannot grade .$ext files - please grade it manually.');
      }

      final result = AiClient.extractJsonObject(raw);
      if (result == null) {
        return const GradeResult.fail(
            'AI response could not be understood - please grade manually.');
      }
      final score = min(max(toInt(result['score']), 0), assignment.totalMarks);
      final feedback = result['feedback']?.toString();
      await Repo.gradeAssignment(submission.id, score, feedback);
      return const GradeResult.ok();
    } catch (e) {
      debugPrint('AI assignment grading failed: $e');
      return GradeResult.fail(e.toString());
    }
  }
}
