import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'security.dart';

class AppDb {
  AppDb._();

  static Database? _db;

  static Future<Database> get instance async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final path = p.join(dir, 'course_lms.db');
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
    _db = db;
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        registration_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        email TEXT UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('admin','teacher','student')),
        must_change_password INTEGER NOT NULL DEFAULT 1,
        created_at TEXT,
        updated_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        teacher_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE course_student (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status TEXT NOT NULL DEFAULT 'approved',
        created_at TEXT,
        UNIQUE (course_id, student_id)
      )
    """);
    await db.execute("""
      CREATE TABLE course_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'other',
        file_path TEXT NOT NULL,
        created_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE syllabus_outlines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        week_number INTEGER NOT NULL,
        topic TEXT NOT NULL,
        phase TEXT NOT NULL DEFAULT 'before_mid',
        is_covered INTEGER NOT NULL DEFAULT 0,
        covered_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE quizzes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        topics_covered TEXT,
        total_marks INTEGER NOT NULL DEFAULT 0,
        available_from TEXT NOT NULL,
        available_until TEXT NOT NULL,
        created_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE quiz_questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        question_text TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'mcq',
        options TEXT,
        correct_answer TEXT,
        marks INTEGER NOT NULL DEFAULT 1
      )
    """);
    await db.execute("""
      CREATE TABLE assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        description TEXT,
        topics_covered TEXT,
        total_marks INTEGER NOT NULL DEFAULT 0,
        available_from TEXT NOT NULL,
        available_until TEXT NOT NULL,
        created_at TEXT
      )
    """);
    await db.execute("""
      CREATE TABLE quiz_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
        student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        answers TEXT NOT NULL,
        score INTEGER,
        feedback TEXT,
        submitted_at TEXT NOT NULL,
        checked_at TEXT,
        UNIQUE (quiz_id, student_id)
      )
    """);
    await db.execute("""
      CREATE TABLE assignment_submissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assignment_id INTEGER NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
        student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        file_path TEXT NOT NULL,
        score INTEGER,
        feedback TEXT,
        submitted_at TEXT NOT NULL,
        checked_at TEXT,
        UNIQUE (assignment_id, student_id)
      )
    """);
    await db.execute("""
      CREATE TABLE app_notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'info',
        related_id INTEGER,
        read_at TEXT,
        created_at TEXT
      )
    """);

    // Same default admin as the web version's AdminSeeder.
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'registration_number': 'ADMIN-001',
      'name': 'System Admin',
      'email': 'admin@example.com',
      'password': Passwords.hash('admin123'),
      'role': 'admin',
      'must_change_password': 1,
      'created_at': now,
      'updated_at': now,
    });
  }
}
