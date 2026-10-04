import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db.dart';
import 'models.dart';
import 'security.dart';
import 'utils.dart';

/// All database access (replaces the Laravel controllers/models).
class Repo {
  Repo._();

  static String _now() => DateTime.now().toIso8601String();
  static Future<Database> _d() => AppDb.instance;

  // ------------------------------------------------------------------ users

  static Future<AppUser?> userById(int id) async {
    final db = await _d();
    final rows =
        await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  static Future<AppUser?> userByReg(String reg) async {
    final db = await _d();
    final rows = await db.query('users',
        where: 'registration_number = ?', whereArgs: [reg], limit: 1);
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  /// Returns an error message, or null on success.
  static Future<String?> createUser({
    required String registrationNumber,
    required String name,
    String? email,
    required String role,
  }) async {
    final db = await _d();
    if (await userByReg(registrationNumber) != null) {
      return 'That registration number is already taken.';
    }
    final cleanEmail =
        (email == null || email.trim().isEmpty) ? null : email.trim();
    if (cleanEmail != null) {
      final rows = await db.query('users',
          where: 'email = ?', whereArgs: [cleanEmail], limit: 1);
      if (rows.isNotEmpty) return 'That email is already used.';
    }
    final now = _now();
    await db.insert('users', {
      'registration_number': registrationNumber,
      'name': name,
      'email': cleanEmail,
      'password': Passwords.hash(Passwords.randomPassword()),
      'role': role,
      'must_change_password': 1,
      'created_at': now,
      'updated_at': now,
    });
    return null;
  }

  static Future<List<AppUser>> managedUsers() async {
    final db = await _d();
    final rows = await db.query('users',
        where: "role IN ('teacher','student')", orderBy: 'id DESC');
    return rows.map(AppUser.fromMap).toList();
  }

  static Future<int> countByRole(String role) async {
    final db = await _d();
    final r = await db
        .rawQuery('SELECT COUNT(*) FROM users WHERE role = ?', [role]);
    return Sqflite.firstIntValue(r) ?? 0;
  }

  static Future<void> setPassword(int userId, String plain,
      {bool mustChange = false}) async {
    final db = await _d();
    await db.update(
      'users',
      {
        'password': Passwords.hash(plain),
        'must_change_password': mustChange ? 1 : 0,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<void> resetPassword(int userId) async {
    await setPassword(userId, Passwords.randomPassword(), mustChange: true);
  }

  static Future<void> deleteUser(int userId) async {
    final db = await _d();
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // ---------------------------------------------------------------- courses

  static Future<List<Course>> coursesTaughtBy(int teacherId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM course_materials m WHERE m.course_id = c.id) AS materials_count,
        (SELECT COUNT(*) FROM quizzes q WHERE q.course_id = c.id) AS quizzes_count,
        (SELECT COUNT(*) FROM assignments a WHERE a.course_id = c.id) AS assignments_count,
        (SELECT COUNT(*) FROM course_student cs WHERE cs.course_id = c.id AND cs.status = 'approved') AS students_count
      FROM courses c
      WHERE c.teacher_id = ?
      ORDER BY c.id DESC
    ''', [teacherId]);
    return rows.map(Course.fromMap).toList();
  }

  static Future<int> createCourse(
      int teacherId, String title, String? description) async {
    final db = await _d();
    final desc = (description == null || description.trim().isEmpty)
        ? null
        : description.trim();
    return db.insert('courses', {
      'teacher_id': teacherId,
      'title': title.trim(),
      'description': desc,
      'created_at': _now(),
    });
  }

  static Future<Course?> courseById(int id) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT c.*, u.name AS teacher_name
      FROM courses c JOIN users u ON u.id = c.teacher_id
      WHERE c.id = ?
    ''', [id]);
    return rows.isEmpty ? null : Course.fromMap(rows.first);
  }

  // -------------------------------------------------------------- materials

  static Future<List<CourseMaterial>> materialsOf(int courseId) async {
    final db = await _d();
    final rows = await db.query('course_materials',
        where: 'course_id = ?', whereArgs: [courseId], orderBy: 'id DESC');
    return rows.map(CourseMaterial.fromMap).toList();
  }

  static Future<void> addMaterial(
      int courseId, String title, String type, String filePath) async {
    final db = await _d();
    await db.insert('course_materials', {
      'course_id': courseId,
      'title': title.trim(),
      'type': type,
      'file_path': filePath,
      'created_at': _now(),
    });
  }

  /// Deletes the row and returns the stored file path (so caller can delete the file).
  static Future<String?> deleteMaterial(int id) async {
    final db = await _d();
    final rows = await db.query('course_materials',
        columns: ['file_path'], where: 'id = ?', whereArgs: [id], limit: 1);
    await db.delete('course_materials', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first['file_path'] as String?;
  }

  // --------------------------------------------------------------- syllabus

  static Future<List<SyllabusItem>> syllabusOf(int courseId) async {
    final db = await _d();
    final rows = await db.query('syllabus_outlines',
        where: 'course_id = ?',
        whereArgs: [courseId],
        orderBy: 'week_number ASC, id ASC');
    return rows.map(SyllabusItem.fromMap).toList();
  }

  static Future<void> addSyllabus(
      int courseId, int week, String topic, String phase) async {
    final db = await _d();
    await db.insert('syllabus_outlines', {
      'course_id': courseId,
      'week_number': week,
      'topic': topic.trim(),
      'phase': phase,
      'is_covered': 0,
    });
  }

  static Future<void> markCovered(int syllabusId) async {
    final db = await _d();
    await db.update(
      'syllabus_outlines',
      {'is_covered': 1, 'covered_at': _now()},
      where: 'id = ?',
      whereArgs: [syllabusId],
    );
  }

  static Future<String> coveredTopics(int courseId) async {
    final db = await _d();
    final rows = await db.query('syllabus_outlines',
        columns: ['topic'],
        where: 'course_id = ? AND is_covered = 1',
        whereArgs: [courseId],
        orderBy: 'week_number ASC, id ASC');
    return rows.map((r) => (r['topic'] ?? '').toString()).join(', ');
  }

  // ------------------------------------------------------------ notifications

  static Future<void> notify(int userId, String title, String message,
      String type, int? relatedId) async {
    final db = await _d();
    await db.insert('app_notifications', {
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'created_at': _now(),
    });
  }

  static Future<List<AppNotification>> notificationsFor(int userId,
      {int limit = 10}) async {
    final db = await _d();
    final rows = await db.query('app_notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
        limit: limit);
    return rows.map(AppNotification.fromMap).toList();
  }

  // ------------------------------------------------------------- enrollment

  static Future<List<AppUser>> _studentsByStatus(
      int courseId, String status) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT u.* FROM users u
      JOIN course_student cs ON cs.student_id = u.id
      WHERE cs.course_id = ? AND cs.status = ?
      ORDER BY u.name
    ''', [courseId, status]);
    return rows.map(AppUser.fromMap).toList();
  }

  static Future<List<AppUser>> approvedStudentsOf(int courseId) =>
      _studentsByStatus(courseId, 'approved');

  static Future<List<AppUser>> pendingStudentsOf(int courseId) =>
      _studentsByStatus(courseId, 'pending');

  static Future<void> approveStudent(Course course, AppUser student) async {
    final db = await _d();
    await db.update(
      'course_student',
      {'status': 'approved'},
      where: 'course_id = ? AND student_id = ?',
      whereArgs: [course.id, student.id],
    );
    await notify(
      student.id,
      'Enrollment approved: ${course.title}',
      'Your request to join ${course.title} has been approved. You can now see its quizzes and assignments.',
      'enrollment',
      course.id,
    );
  }

  static Future<void> rejectStudent(Course course, AppUser student) async {
    final db = await _d();
    await db.delete(
      'course_student',
      where: "course_id = ? AND student_id = ? AND status = 'pending'",
      whereArgs: [course.id, student.id],
    );
    await notify(
      student.id,
      'Enrollment request declined: ${course.title}',
      'Your request to join ${course.title} was not approved.',
      'enrollment',
      course.id,
    );
  }

  static Future<void> removeStudent(Course course, AppUser student) async {
    final db = await _d();
    await db.delete(
      'course_student',
      where: 'course_id = ? AND student_id = ?',
      whereArgs: [course.id, student.id],
    );
  }

  static Future<bool> isApprovedStudent(int courseId, int studentId) async {
    final db = await _d();
    final rows = await db.query('course_student',
        where: "course_id = ? AND student_id = ? AND status = 'approved'",
        whereArgs: [courseId, studentId],
        limit: 1);
    return rows.isNotEmpty;
  }

  static Future<List<Course>> enrolledCoursesFor(int studentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT c.*, u.name AS teacher_name FROM courses c
      JOIN course_student cs ON cs.course_id = c.id
      JOIN users u ON u.id = c.teacher_id
      WHERE cs.student_id = ? AND cs.status = 'approved'
      ORDER BY c.id DESC
    ''', [studentId]);
    return rows.map(Course.fromMap).toList();
  }

  static Future<List<Course>> pendingCoursesFor(int studentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT c.*, u.name AS teacher_name FROM courses c
      JOIN course_student cs ON cs.course_id = c.id
      JOIN users u ON u.id = c.teacher_id
      WHERE cs.student_id = ? AND cs.status = 'pending'
      ORDER BY c.id DESC
    ''', [studentId]);
    return rows.map(Course.fromMap).toList();
  }

  static Future<List<Course>> availableCoursesFor(int studentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT c.*, u.name AS teacher_name FROM courses c
      JOIN users u ON u.id = c.teacher_id
      WHERE c.id NOT IN (SELECT course_id FROM course_student WHERE student_id = ?)
      ORDER BY c.id DESC
    ''', [studentId]);
    return rows.map(Course.fromMap).toList();
  }

  static Future<String> requestEnrollment(AppUser student, Course course) async {
    final db = await _d();
    final rows = await db.query('course_student',
        where: 'course_id = ? AND student_id = ?',
        whereArgs: [course.id, student.id],
        limit: 1);
    if (rows.isNotEmpty) {
      return 'You already have a request or enrollment for this course.';
    }
    await db.insert('course_student', {
      'course_id': course.id,
      'student_id': student.id,
      'status': 'pending',
      'created_at': _now(),
    });
    await notify(
      course.teacherId,
      'New enrollment request: ${course.title}',
      '${student.name} (${student.registrationNumber}) has requested to join ${course.title}.',
      'enrollment',
      course.id,
    );
    return 'Enrollment request sent. The teacher will review it.';
  }

  // ---------------------------------------------------------------- quizzes

  static Future<List<Quiz>> quizzesOf(int courseId) async {
    final db = await _d();
    final rows = await db.query('quizzes',
        where: 'course_id = ?', whereArgs: [courseId], orderBy: 'id ASC');
    return rows.map(Quiz.fromMap).toList();
  }

  static Future<Quiz?> quizById(int id) async {
    final db = await _d();
    final rows =
        await db.query('quizzes', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Quiz.fromMap(rows.first);
  }

  static Future<List<QuizQuestion>> questionsOf(int quizId) async {
    final db = await _d();
    final rows = await db.query('quiz_questions',
        where: 'quiz_id = ?', whereArgs: [quizId], orderBy: 'id ASC');
    return rows.map(QuizQuestion.fromMap).toList();
  }

  static Future<int> createQuiz({
    required Course course,
    required String title,
    required DateTime from,
    required DateTime until,
    required List<QuestionDraft> questions,
  }) async {
    final db = await _d();
    final covered = await coveredTopics(course.id);
    final total = questions.fold<int>(0, (s, q) => s + q.marks);
    var quizId = 0;
    await db.transaction((txn) async {
      quizId = await txn.insert('quizzes', {
        'course_id': course.id,
        'title': title.trim(),
        'topics_covered': covered,
        'total_marks': total,
        'available_from': from.toIso8601String(),
        'available_until': until.toIso8601String(),
        'created_at': _now(),
      });
      for (final q in questions) {
        final opts = q.options.where((o) => o.trim().isNotEmpty).toList();
        await txn.insert('quiz_questions', {
          'quiz_id': quizId,
          'question_text': q.questionText.trim(),
          'type': q.type,
          'options': q.type == 'mcq' ? jsonEncode(opts) : null,
          'correct_answer': q.correctAnswer.trim(),
          'marks': q.marks,
        });
      }
    });
    final students = await approvedStudentsOf(course.id);
    for (final s in students) {
      await notify(
        s.id,
        'New quiz: ${title.trim()}',
        'A new quiz is available for ${course.title}. It closes on ${fmtDt(until)}.',
        'quiz',
        quizId,
      );
    }
    return quizId;
  }

  static Future<List<QuizSubmission>> quizSubmissionsOf(int quizId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT qs.*, u.name AS student_name, u.registration_number AS student_reg
      FROM quiz_submissions qs JOIN users u ON u.id = qs.student_id
      WHERE qs.quiz_id = ?
      ORDER BY qs.id
    ''', [quizId]);
    return rows.map(QuizSubmission.fromMap).toList();
  }

  static Future<QuizSubmission?> quizSubmissionOf(
      int quizId, int studentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT qs.*, u.name AS student_name, u.registration_number AS student_reg
      FROM quiz_submissions qs JOIN users u ON u.id = qs.student_id
      WHERE qs.quiz_id = ? AND qs.student_id = ?
      LIMIT 1
    ''', [quizId, studentId]);
    return rows.isEmpty ? null : QuizSubmission.fromMap(rows.first);
  }

  /// Insert or update the student's submission (like Laravel's updateOrCreate).
  static Future<QuizSubmission> saveQuizSubmission(
      int quizId, int studentId, Map<String, String> answers) async {
    final db = await _d();
    final existing = await db.query('quiz_submissions',
        columns: ['id'],
        where: 'quiz_id = ? AND student_id = ?',
        whereArgs: [quizId, studentId],
        limit: 1);
    if (existing.isEmpty) {
      await db.insert('quiz_submissions', {
        'quiz_id': quizId,
        'student_id': studentId,
        'answers': jsonEncode(answers),
        'submitted_at': _now(),
      });
    } else {
      await db.update(
        'quiz_submissions',
        {'answers': jsonEncode(answers), 'submitted_at': _now()},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
    final saved = await quizSubmissionOf(quizId, studentId);
    return saved!;
  }

  static Future<void> setQuizScore(int submissionId, int score) async {
    final db = await _d();
    await db.update(
      'quiz_submissions',
      {'score': score, 'checked_at': _now()},
      where: 'id = ?',
      whereArgs: [submissionId],
    );
  }

  // ------------------------------------------------------------ assignments

  static Future<List<Assignment>> assignmentsOf(int courseId) async {
    final db = await _d();
    final rows = await db.query('assignments',
        where: 'course_id = ?', whereArgs: [courseId], orderBy: 'id ASC');
    return rows.map(Assignment.fromMap).toList();
  }

  static Future<Assignment?> assignmentById(int id) async {
    final db = await _d();
    final rows = await db
        .query('assignments', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Assignment.fromMap(rows.first);
  }

  static Future<int> createAssignment({
    required Course course,
    required String title,
    required String? description,
    required int totalMarks,
    required DateTime from,
    required DateTime until,
  }) async {
    final db = await _d();
    final covered = await coveredTopics(course.id);
    final desc = (description == null || description.trim().isEmpty)
        ? null
        : description.trim();
    final id = await db.insert('assignments', {
      'course_id': course.id,
      'title': title.trim(),
      'description': desc,
      'topics_covered': covered,
      'total_marks': totalMarks,
      'available_from': from.toIso8601String(),
      'available_until': until.toIso8601String(),
      'created_at': _now(),
    });
    final students = await approvedStudentsOf(course.id);
    for (final s in students) {
      await notify(
        s.id,
        'New assignment: ${title.trim()}',
        'A new assignment is available for ${course.title}. Due ${fmtDt(until)}.',
        'assignment',
        id,
      );
    }
    return id;
  }

  static Future<List<AssignmentSubmission>> assignmentSubmissionsOf(
      int assignmentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT s.*, u.name AS student_name, u.registration_number AS student_reg
      FROM assignment_submissions s JOIN users u ON u.id = s.student_id
      WHERE s.assignment_id = ?
      ORDER BY s.id
    ''', [assignmentId]);
    return rows.map(AssignmentSubmission.fromMap).toList();
  }

  static Future<AssignmentSubmission?> assignmentSubmissionOf(
      int assignmentId, int studentId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT s.*, u.name AS student_name, u.registration_number AS student_reg
      FROM assignment_submissions s JOIN users u ON u.id = s.student_id
      WHERE s.assignment_id = ? AND s.student_id = ?
      LIMIT 1
    ''', [assignmentId, studentId]);
    return rows.isEmpty ? null : AssignmentSubmission.fromMap(rows.first);
  }

  static Future<AssignmentSubmission> saveAssignmentSubmission(
      int assignmentId, int studentId, String filePath) async {
    final db = await _d();
    final existing = await db.query('assignment_submissions',
        columns: ['id'],
        where: 'assignment_id = ? AND student_id = ?',
        whereArgs: [assignmentId, studentId],
        limit: 1);
    if (existing.isEmpty) {
      await db.insert('assignment_submissions', {
        'assignment_id': assignmentId,
        'student_id': studentId,
        'file_path': filePath,
        'submitted_at': _now(),
      });
    } else {
      await db.update(
        'assignment_submissions',
        {'file_path': filePath, 'submitted_at': _now()},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
    final saved = await assignmentSubmissionOf(assignmentId, studentId);
    return saved!;
  }

  static Future<void> gradeAssignment(
      int submissionId, int score, String? feedback) async {
    final db = await _d();
    final fb =
        (feedback == null || feedback.trim().isEmpty) ? null : feedback.trim();
    await db.update(
      'assignment_submissions',
      {'score': score, 'feedback': fb, 'checked_at': _now()},
      where: 'id = ?',
      whereArgs: [submissionId],
    );
  }

  // ------------------------------------------------- student result listing

  static Future<List<GradedItem>> gradedQuizzes(
      int studentId, int courseId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT qs.score AS score, qs.feedback AS feedback, q.title AS title, q.total_marks AS total
      FROM quiz_submissions qs JOIN quizzes q ON q.id = qs.quiz_id
      WHERE qs.student_id = ? AND qs.checked_at IS NOT NULL AND q.course_id = ?
      ORDER BY qs.checked_at DESC
    ''', [studentId, courseId]);
    return rows
        .map((r) => GradedItem(
              title: (r['title'] ?? '').toString(),
              score: toInt(r['score']),
              total: toInt(r['total']),
              feedback: r['feedback'] as String?,
            ))
        .toList();
  }

  static Future<List<GradedItem>> gradedAssignments(
      int studentId, int courseId) async {
    final db = await _d();
    final rows = await db.rawQuery('''
      SELECT s.score AS score, s.feedback AS feedback, a.title AS title, a.total_marks AS total
      FROM assignment_submissions s JOIN assignments a ON a.id = s.assignment_id
      WHERE s.student_id = ? AND s.checked_at IS NOT NULL AND a.course_id = ?
      ORDER BY s.checked_at DESC
    ''', [studentId, courseId]);
    return rows
        .map((r) => GradedItem(
              title: (r['title'] ?? '').toString(),
              score: toInt(r['score']),
              total: toInt(r['total']),
              feedback: r['feedback'] as String?,
            ))
        .toList();
  }
}
