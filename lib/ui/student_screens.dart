import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/files.dart';
import '../core/models.dart';
import '../core/repo.dart';
import '../core/session.dart';
import '../core/utils.dart';
import 'common.dart';

// ================================================================ dashboard

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  List<Course> _courses = [];
  int _pendingCount = 0;
  List<AppNotification> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    if (u == null) return;
    final courses = await Repo.enrolledCoursesFor(u.id);
    final pending = await Repo.pendingCoursesFor(u.id);
    final notes = await Repo.notificationsFor(u.id, limit: 10);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _pendingCount = pending.length;
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _browse() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StudentBrowseScreen()),
    );
    _load();
  }

  Future<void> _openCourse(Course c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StudentCourseScreen(course: c)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'My Courses');
    return PageScaffold(
      title: 'My Courses',
      actions: [userMenu(context)],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: slateButton(),
            onPressed: _browse,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Browse Courses'),
                if (_pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$_pendingCount pending',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_courses.isEmpty)
          Panel(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const MutedText('You are not enrolled in any course yet.',
                    size: 14),
                TextButton(
                  onPressed: _browse,
                  child: const Text('Browse available courses'),
                ),
              ],
            ),
          ),
        for (final c in _courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openCourse(c),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    MutedText((c.description ?? '').trim().isEmpty
                        ? 'View quizzes, assignments & results'
                        : c.description!),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        const SectionTitle('Notifications'),
        const SizedBox(height: 8),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: _notes.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: MutedText('No notifications yet.'),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _notes.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_notes[i].title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            MutedText(_notes[i].message),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

// ============================================================ browse courses

class StudentBrowseScreen extends StatefulWidget {
  const StudentBrowseScreen({super.key});

  @override
  State<StudentBrowseScreen> createState() => _StudentBrowseScreenState();
}

class _StudentBrowseScreenState extends State<StudentBrowseScreen> {
  List<Course> _available = [];
  List<Course> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    if (u == null) return;
    final a = await Repo.availableCoursesFor(u.id);
    final p = await Repo.pendingCoursesFor(u.id);
    if (!mounted) return;
    setState(() {
      _available = a;
      _pending = p;
      _loading = false;
    });
  }

  Future<void> _request(Course c) async {
    final u = Session.user;
    if (u == null) return;
    final msg = await Repo.requestEnrollment(u, c);
    await _load();
    if (!mounted) return;
    showMsg(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Browse Courses');
    return PageScaffold(
      title: 'Browse Courses',
      children: [
        if (_pending.isNotEmpty) ...[
          Panel(
            color: Colors.amber.shade50,
            borderColor: Colors.amber.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Awaiting teacher approval:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                        fontSize: 13)),
                const SizedBox(height: 6),
                for (final c in _pending)
                  Text('${c.title} (${c.teacherName})',
                      style:
                          TextStyle(color: Colors.amber.shade800, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (_available.isEmpty)
          const Panel(
            padding: EdgeInsets.all(24),
            child: Center(
              child: MutedText('No more courses available to join right now.',
                  size: 14),
            ),
          ),
        for (final c in _available)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  MutedText((c.description ?? '').trim().isEmpty
                      ? 'No description provided.'
                      : c.description!),
                  const SizedBox(height: 8),
                  MutedText('Taught by ${c.teacherName}', size: 12),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: slateButton(),
                    onPressed: () => _request(c),
                    child: const Text('Request to Join'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ================================================================ course page

class StudentCourseScreen extends StatefulWidget {
  final Course course;
  const StudentCourseScreen({super.key, required this.course});

  @override
  State<StudentCourseScreen> createState() => _StudentCourseScreenState();
}

class _StudentCourseScreenState extends State<StudentCourseScreen> {
  List<Quiz> _quizzes = [];
  List<Assignment> _assignments = [];
  List<GradedItem> _gradedQuizzes = [];
  List<GradedItem> _gradedAssignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    if (u == null) return;
    final enrolled = await Repo.isApprovedStudent(widget.course.id, u.id);
    if (!enrolled) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final quizzes = await Repo.quizzesOf(widget.course.id);
    final assignments = await Repo.assignmentsOf(widget.course.id);
    final gq = await Repo.gradedQuizzes(u.id, widget.course.id);
    final ga = await Repo.gradedAssignments(u.id, widget.course.id);
    if (!mounted) return;
    setState(() {
      _quizzes = quizzes;
      _assignments = assignments;
      _gradedQuizzes = gq;
      _gradedAssignments = ga;
      _loading = false;
    });
  }

  Future<void> _attempt(Quiz q) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => StudentQuizScreen(quizId: q.id)),
    );
    _load();
  }

  Future<void> _submit(Assignment a) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => StudentAssignmentScreen(assignmentId: a.id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return LoadingPage(title: widget.course.title);
    final openQuizzes = _quizzes.where((q) => q.isOpen).toList();
    final openAssignments = _assignments.where((a) => a.isOpen).toList();

    return PageScaffold(
      title: widget.course.title,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MutedText('Open Quizzes', size: 14),
              const SizedBox(height: 6),
              if (openQuizzes.isEmpty) const MutedText('None open right now.'),
              for (final q in openQuizzes)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(q.title),
                  subtitle: Text('Closes ${fmtDt(q.availableUntil)}'),
                  trailing: TextButton(
                    onPressed: () => _attempt(q),
                    child: const Text('Attempt'),
                  ),
                ),
              const SizedBox(height: 14),
              const MutedText('Open Assignments', size: 14),
              const SizedBox(height: 6),
              if (openAssignments.isEmpty)
                const MutedText('None open right now.'),
              for (final a in openAssignments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(a.title),
                  subtitle: Text('Due ${fmtDt(a.availableUntil)}'),
                  trailing: TextButton(
                    onPressed: () => _submit(a),
                    child: const Text('Submit'),
                  ),
                ),
            ],
          ),
        ),
        if (_gradedQuizzes.isNotEmpty || _gradedAssignments.isNotEmpty) ...[
          const SizedBox(height: 14),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Your Results'),
                if (_gradedQuizzes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const MutedText('Quizzes', size: 14),
                  for (final g in _gradedQuizzes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(g.title)),
                          Text('${g.score} / ${g.total}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
                if (_gradedAssignments.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const MutedText('Assignments', size: 14),
                  for (final g in _gradedAssignments)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(g.title)),
                              Text('${g.score} / ${g.total}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if ((g.feedback ?? '').isNotEmpty)
                            MutedText(g.feedback!),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ================================================================ quiz attempt

class StudentQuizScreen extends StatefulWidget {
  final int quizId;
  const StudentQuizScreen({super.key, required this.quizId});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
  Quiz? _quiz;
  List<QuizQuestion> _questions = [];
  QuizSubmission? _existing;
  final Map<int, String> _answers = <int, String>{};
  final Map<int, TextEditingController> _text = <int, TextEditingController>{};
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    final quiz = await Repo.quizById(widget.quizId);
    if (u == null || quiz == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final enrolled = await Repo.isApprovedStudent(quiz.courseId, u.id);
    if (!mounted) return;
    if (!enrolled) {
      Navigator.of(context).pop();
      return;
    }
    final questions = await Repo.questionsOf(quiz.id);
    final existing = await Repo.quizSubmissionOf(quiz.id, u.id);
    if (!mounted) return;
    setState(() {
      _quiz = quiz;
      _questions = questions;
      _existing = existing;
      for (final q in questions) {
        if (!q.isMcq) {
          _text[q.id] = TextEditingController();
        }
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final u = Session.user;
    final quiz = _quiz;
    if (u == null || quiz == null) return;
    if (!quiz.isOpen) {
      showMsg(context, 'This quiz is not currently available.', error: true);
      return;
    }

    final answers = <String, String>{};
    for (final q in _questions) {
      final value =
          q.isMcq ? (_answers[q.id] ?? '') : (_text[q.id]?.text ?? '').trim();
      if (value.isEmpty) {
        setState(() => _error = 'Please answer every question before submitting.');
        return;
      }
      answers[q.id.toString()] = value;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final submission = await Repo.saveQuizSubmission(quiz.id, u.id, answers);
      try {
        await AiGrader.gradeQuizSubmission(submission);
      } catch (_) {
        // Grading problems must not lose the student's answers.
      }
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      showMsgOn(messenger, 'Quiz submitted. Result will appear once checked.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMsg(context, 'Could not submit quiz: $e', error: true);
    }
  }

  Widget _mcqOption(QuizQuestion q, String option) {
    final selected = _answers[q.id] == option;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _answers[q.id] = option),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? kSlate : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(option)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;
    if (_loading || quiz == null) return const LoadingPage(title: 'Quiz');

    final header = <Widget>[
      Text(quiz.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      MutedText(
          'Closes ${fmtDt(quiz.availableUntil)} - Total ${quiz.totalMarks} marks'),
      const SizedBox(height: 14),
    ];

    if (_existing != null) {
      return PageScaffold(
        title: 'Quiz',
        children: [
          ...header,
          Panel(
            color: Colors.blue.shade50,
            borderColor: Colors.blue.shade200,
            child: Text(
              'You already submitted this quiz. Score: ${_existing!.score ?? "Pending"} / ${quiz.totalMarks}',
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ),
        ],
      );
    }

    if (!quiz.isOpen) {
      return PageScaffold(
        title: 'Quiz',
        children: [
          ...header,
          Panel(
            color: Colors.amber.shade50,
            borderColor: Colors.amber.shade200,
            child: Text('This quiz is not currently available.',
                style: TextStyle(color: Colors.amber.shade900)),
          ),
        ],
      );
    }

    return PageScaffold(
      title: 'Quiz',
      children: [
        ...header,
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _questions.length; i++) ...[
                Text(
                  '${i + 1}. ${_questions[i].questionText}  (${_questions[i].marks} marks)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (_questions[i].isMcq) ...[
                  for (final o in _questions[i]
                      .options
                      .where((o) => o.trim().isNotEmpty))
                    _mcqOption(_questions[i], o),
                ] else
                  TextField(
                    controller: _text[_questions[i].id],
                    maxLines: null,
                    decoration: inputDeco('Your answer'),
                  ),
                if (i < _questions.length - 1) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              BusyButton(
                label: 'Submit Quiz',
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================================= assignment submit

class StudentAssignmentScreen extends StatefulWidget {
  final int assignmentId;
  const StudentAssignmentScreen({super.key, required this.assignmentId});

  @override
  State<StudentAssignmentScreen> createState() =>
      _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends State<StudentAssignmentScreen> {
  Assignment? _assignment;
  AssignmentSubmission? _existing;
  ChosenFile? _file;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    final a = await Repo.assignmentById(widget.assignmentId);
    if (u == null || a == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final enrolled = await Repo.isApprovedStudent(a.courseId, u.id);
    if (!mounted) return;
    if (!enrolled) {
      Navigator.of(context).pop();
      return;
    }
    final existing = await Repo.assignmentSubmissionOf(a.id, u.id);
    if (!mounted) return;
    setState(() {
      _assignment = a;
      _existing = existing;
      _loading = false;
    });
  }

  Future<void> _pick() async {
    final f = await FileStore.pick(['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']);
    if (f == null) return;
    if (!mounted) return;
    if (f.size > FileStore.maxBytes) {
      showMsg(context, 'File is too large (max 20 MB).', error: true);
      return;
    }
    setState(() => _file = f);
  }

  Future<void> _submit() async {
    final u = Session.user;
    final a = _assignment;
    final f = _file;
    if (u == null || a == null) return;
    if (f == null) {
      showMsg(context, 'Choose a file to upload first.', error: true);
      return;
    }
    if (!a.isOpen) {
      showMsg(context, 'This assignment is not currently available.',
          error: true);
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rel =
          await FileStore.saveCopy(f.path, 'assignment_submissions/${a.id}');
      final submission =
          await Repo.saveAssignmentSubmission(a.id, u.id, rel);
      await AiGrader.gradeAssignmentSubmission(submission, a);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      showMsgOn(messenger, 'Assignment submitted.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showMsg(context, 'Could not submit assignment: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _assignment;
    if (_loading || a == null) return const LoadingPage(title: 'Assignment');

    final children = <Widget>[
      Text(a.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      MutedText('Due ${fmtDt(a.availableUntil)} - ${a.totalMarks} marks'),
      const SizedBox(height: 14),
    ];

    if ((a.description ?? '').trim().isNotEmpty) {
      children.addAll([
        Panel(color: Colors.grey.shade50, child: Text(a.description!)),
        const SizedBox(height: 14),
      ]);
    }

    final e = _existing;
    if (e != null) {
      children.add(
        Panel(
          color: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submitted on ${fmtDt(e.submittedAt)}. Score: ${e.score ?? "Pending"} / ${a.totalMarks}',
                style: TextStyle(color: Colors.blue.shade800),
              ),
              if ((e.feedback ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Feedback: ${e.feedback}',
                    style: TextStyle(color: Colors.blue.shade800)),
              ],
            ],
          ),
        ),
      );
    } else if (!a.isOpen) {
      children.add(
        Panel(
          color: Colors.amber.shade50,
          borderColor: Colors.amber.shade200,
          child: Text('This assignment is not currently available.',
              style: TextStyle(color: Colors.amber.shade900)),
        ),
      );
    } else {
      children.add(
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Upload your work (PDF / image / doc)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pick,
                icon: const Icon(Icons.attach_file),
                label: Text(_file == null ? 'Choose file' : _file!.name,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 14),
              BusyButton(
                label: 'Submit Assignment',
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      );
    }

    return PageScaffold(title: 'Assignment', children: children);
  }
}
