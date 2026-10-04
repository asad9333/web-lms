import 'dart:convert';

DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v) : null;
DateTime _dtReq(Object? v) =>
    _dt(v) ?? DateTime.fromMillisecondsSinceEpoch(0);

int _int(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int? _intOrNull(Object? v) => v == null ? null : _int(v);
String _str(Object? v) => v == null ? '' : v.toString();
String? _strOrNull(Object? v) => v == null ? null : v.toString();

class AppUser {
  final int id;
  final String registrationNumber;
  final String name;
  final String? email;
  final String passwordHash;
  final String role;
  final bool mustChangePassword;

  const AppUser({
    required this.id,
    required this.registrationNumber,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.mustChangePassword,
  });

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: _int(m['id']),
        registrationNumber: _str(m['registration_number']),
        name: _str(m['name']),
        email: _strOrNull(m['email']),
        passwordHash: _str(m['password']),
        role: _str(m['role']),
        mustChangePassword: _int(m['must_change_password']) == 1,
      );

  bool get isAdmin => role == 'admin';
  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';
}

class Course {
  final int id;
  final int teacherId;
  final String title;
  final String? description;
  final String teacherName;
  final int materialsCount;
  final int quizzesCount;
  final int assignmentsCount;
  final int studentsCount;

  const Course({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.teacherName,
    required this.materialsCount,
    required this.quizzesCount,
    required this.assignmentsCount,
    required this.studentsCount,
  });

  factory Course.fromMap(Map<String, Object?> m) => Course(
        id: _int(m['id']),
        teacherId: _int(m['teacher_id']),
        title: _str(m['title']),
        description: _strOrNull(m['description']),
        teacherName: _str(m['teacher_name']),
        materialsCount: _int(m['materials_count']),
        quizzesCount: _int(m['quizzes_count']),
        assignmentsCount: _int(m['assignments_count']),
        studentsCount: _int(m['students_count']),
      );
}

class CourseMaterial {
  final int id;
  final int courseId;
  final String title;
  final String type;
  final String filePath;

  const CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.filePath,
  });

  factory CourseMaterial.fromMap(Map<String, Object?> m) => CourseMaterial(
        id: _int(m['id']),
        courseId: _int(m['course_id']),
        title: _str(m['title']),
        type: _str(m['type']),
        filePath: _str(m['file_path']),
      );
}

class SyllabusItem {
  final int id;
  final int courseId;
  final int weekNumber;
  final String topic;
  final String phase;
  final bool isCovered;
  final DateTime? coveredAt;

  const SyllabusItem({
    required this.id,
    required this.courseId,
    required this.weekNumber,
    required this.topic,
    required this.phase,
    required this.isCovered,
    required this.coveredAt,
  });

  factory SyllabusItem.fromMap(Map<String, Object?> m) => SyllabusItem(
        id: _int(m['id']),
        courseId: _int(m['course_id']),
        weekNumber: _int(m['week_number']),
        topic: _str(m['topic']),
        phase: _str(m['phase']),
        isCovered: _int(m['is_covered']) == 1,
        coveredAt: _dt(m['covered_at']),
      );

  String get phaseLabel => phase == 'before_mid' ? 'Before Mid' : 'Before Final';
}

class Quiz {
  final int id;
  final int courseId;
  final String title;
  final String? topicsCovered;
  final int totalMarks;
  final DateTime availableFrom;
  final DateTime availableUntil;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.topicsCovered,
    required this.totalMarks,
    required this.availableFrom,
    required this.availableUntil,
  });

  factory Quiz.fromMap(Map<String, Object?> m) => Quiz(
        id: _int(m['id']),
        courseId: _int(m['course_id']),
        title: _str(m['title']),
        topicsCovered: _strOrNull(m['topics_covered']),
        totalMarks: _int(m['total_marks']),
        availableFrom: _dtReq(m['available_from']),
        availableUntil: _dtReq(m['available_until']),
      );

  bool get isOpen {
    final now = DateTime.now();
    return !now.isBefore(availableFrom) && !now.isAfter(availableUntil);
  }
}

class QuizQuestion {
  final int id;
  final int quizId;
  final String questionText;
  final String type;
  final List<String> options;
  final String correctAnswer;
  final int marks;

  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.marks,
  });

  factory QuizQuestion.fromMap(Map<String, Object?> m) {
    var opts = <String>[];
    final raw = m['options'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is List) {
          opts = d.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return QuizQuestion(
      id: _int(m['id']),
      quizId: _int(m['quiz_id']),
      questionText: _str(m['question_text']),
      type: _str(m['type']),
      options: opts,
      correctAnswer: _str(m['correct_answer']),
      marks: _int(m['marks']),
    );
  }

  bool get isMcq => type == 'mcq';
}

class QuizSubmission {
  final int id;
  final int quizId;
  final int studentId;
  final Map<String, String> answers;
  final int? score;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? checkedAt;
  final String studentName;
  final String studentReg;

  const QuizSubmission({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.answers,
    required this.score,
    required this.feedback,
    required this.submittedAt,
    required this.checkedAt,
    required this.studentName,
    required this.studentReg,
  });

  factory QuizSubmission.fromMap(Map<String, Object?> m) {
    final out = <String, String>{};
    final raw = m['answers'];
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) {
          d.forEach((k, v) => out[k.toString()] = v == null ? '' : v.toString());
        }
      } catch (_) {}
    }
    return QuizSubmission(
      id: _int(m['id']),
      quizId: _int(m['quiz_id']),
      studentId: _int(m['student_id']),
      answers: out,
      score: _intOrNull(m['score']),
      feedback: _strOrNull(m['feedback']),
      submittedAt: _dtReq(m['submitted_at']),
      checkedAt: _dt(m['checked_at']),
      studentName: _str(m['student_name']),
      studentReg: _str(m['student_reg']),
    );
  }
}

class Assignment {
  final int id;
  final int courseId;
  final String title;
  final String? description;
  final String? topicsCovered;
  final int totalMarks;
  final DateTime availableFrom;
  final DateTime availableUntil;

  const Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.topicsCovered,
    required this.totalMarks,
    required this.availableFrom,
    required this.availableUntil,
  });

  factory Assignment.fromMap(Map<String, Object?> m) => Assignment(
        id: _int(m['id']),
        courseId: _int(m['course_id']),
        title: _str(m['title']),
        description: _strOrNull(m['description']),
        topicsCovered: _strOrNull(m['topics_covered']),
        totalMarks: _int(m['total_marks']),
        availableFrom: _dtReq(m['available_from']),
        availableUntil: _dtReq(m['available_until']),
      );

  bool get isOpen {
    final now = DateTime.now();
    return !now.isBefore(availableFrom) && !now.isAfter(availableUntil);
  }
}

class AssignmentSubmission {
  final int id;
  final int assignmentId;
  final int studentId;
  final String filePath;
  final int? score;
  final String? feedback;
  final DateTime submittedAt;
  final DateTime? checkedAt;
  final String studentName;
  final String studentReg;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.filePath,
    required this.score,
    required this.feedback,
    required this.submittedAt,
    required this.checkedAt,
    required this.studentName,
    required this.studentReg,
  });

  factory AssignmentSubmission.fromMap(Map<String, Object?> m) =>
      AssignmentSubmission(
        id: _int(m['id']),
        assignmentId: _int(m['assignment_id']),
        studentId: _int(m['student_id']),
        filePath: _str(m['file_path']),
        score: _intOrNull(m['score']),
        feedback: _strOrNull(m['feedback']),
        submittedAt: _dtReq(m['submitted_at']),
        checkedAt: _dt(m['checked_at']),
        studentName: _str(m['student_name']),
        studentReg: _str(m['student_reg']),
      );
}

class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String message;
  final String type;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
  });

  factory AppNotification.fromMap(Map<String, Object?> m) => AppNotification(
        id: _int(m['id']),
        userId: _int(m['user_id']),
        title: _str(m['title']),
        message: _str(m['message']),
        type: _str(m['type']),
      );
}

/// A graded quiz / assignment line shown on the student's course page.
class GradedItem {
  final String title;
  final int score;
  final int total;
  final String? feedback;

  const GradedItem({
    required this.title,
    required this.score,
    required this.total,
    required this.feedback,
  });
}

/// Editable question used by the quiz builder and the AI draft generator.
class QuestionDraft {
  String questionText;
  String type;
  List<String> options;
  String correctAnswer;
  int marks;

  QuestionDraft({
    this.questionText = '',
    this.type = 'mcq',
    List<String>? options,
    this.correctAnswer = '',
    this.marks = 1,
  }) : options = options ?? <String>['', '', '', ''];
}

class AssignmentDraft {
  final String title;
  final String description;
  final int totalMarks;

  const AssignmentDraft({
    required this.title,
    required this.description,
    required this.totalMarks,
  });
}
