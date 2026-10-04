import 'package:flutter/material.dart';
import '../core/files.dart';
import '../core/models.dart';
import '../core/repo.dart';
import '../core/session.dart';
import '../core/utils.dart';
import 'common.dart';
import 'teacher_assignment_screens.dart';
import 'teacher_quiz_screens.dart';

// ================================================================ dashboard

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<Course> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = Session.user;
    if (u == null) return;
    final c = await Repo.coursesTaughtBy(u.id);
    if (!mounted) return;
    setState(() {
      _courses = c;
      _loading = false;
    });
  }

  Future<void> _newCourse() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TeacherCreateCourseScreen()),
    );
    _load();
  }

  Future<void> _open(Course c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => TeacherCourseScreen(courseId: c.id)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'My Courses');
    return PageScaffold(
      title: 'My Courses',
      actions: [userMenu(context, showSettings: true)],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSlate,
        foregroundColor: Colors.white,
        onPressed: _newCourse,
        icon: const Icon(Icons.add),
        label: const Text('New Course'),
      ),
      children: [
        if (_courses.isEmpty)
          const Panel(child: Center(child: MutedText('No courses yet.'))),
        for (final c in _courses)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _open(c),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    MutedText(
                        '${c.studentsCount} students · ${c.materialsCount} materials · ${c.quizzesCount} quizzes · ${c.assignmentsCount} assignments'),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 70),
      ],
    );
  }
}

// ============================================================ create course

class TeacherCreateCourseScreen extends StatefulWidget {
  const TeacherCreateCourseScreen({super.key});

  @override
  State<TeacherCreateCourseScreen> createState() =>
      _TeacherCreateCourseScreenState();
}

class _TeacherCreateCourseScreenState extends State<TeacherCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = Session.user;
    if (u == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final id = await Repo.createCourse(u.id, _title.text, _desc.text);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => TeacherCourseScreen(courseId: id)),
    );
    showMsgOn(messenger, 'Course created.');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'New Course',
      children: [
        Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: inputDeco('Title'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  decoration: inputDeco('Description'),
                ),
                const SizedBox(height: 16),
                BusyButton(label: 'Create', busy: _busy, onPressed: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================ course screen

class TeacherCourseScreen extends StatefulWidget {
  final int courseId;
  const TeacherCourseScreen({super.key, required this.courseId});

  @override
  State<TeacherCourseScreen> createState() => _TeacherCourseScreenState();
}

class _TeacherCourseScreenState extends State<TeacherCourseScreen> {
  Course? _course;
  List<CourseMaterial> _materials = [];
  List<SyllabusItem> _syllabus = [];
  List<Quiz> _quizzes = [];
  List<Assignment> _assignments = [];
  List<AppUser> _students = [];
  List<AppUser> _pending = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await Repo.courseById(widget.courseId);
    final me = Session.user;
    if (c == null || me == null || c.teacherId != me.id) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final materials = await Repo.materialsOf(c.id);
    final syllabus = await Repo.syllabusOf(c.id);
    final quizzes = await Repo.quizzesOf(c.id);
    final assignments = await Repo.assignmentsOf(c.id);
    final students = await Repo.approvedStudentsOf(c.id);
    final pending = await Repo.pendingStudentsOf(c.id);
    if (!mounted) return;
    setState(() {
      _course = c;
      _materials = materials;
      _syllabus = syllabus;
      _quizzes = quizzes;
      _assignments = assignments;
      _students = students;
      _pending = pending;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (_loading || course == null) return const LoadingPage(title: 'Course');
    final desc = course.description ?? '';

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: lmsAppBar(
          course.title,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              const Tab(text: 'Materials'),
              const Tab(text: 'Syllabus'),
              const Tab(text: 'Quizzes'),
              const Tab(text: 'Assignments'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Students'),
                    if (_pending.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_pending.length}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (desc.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: MutedText(desc, size: 14),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _MaterialsTab(
                      course: course,
                      materials: _materials,
                      onChanged: _load,
                    ),
                    _SyllabusTab(
                      course: course,
                      items: _syllabus,
                      onChanged: _load,
                    ),
                    _QuizzesTab(
                      course: course,
                      quizzes: _quizzes,
                      onChanged: _load,
                    ),
                    _AssignmentsTab(
                      course: course,
                      assignments: _assignments,
                      onChanged: _load,
                    ),
                    _StudentsTab(
                      course: course,
                      students: _students,
                      pending: _pending,
                      onChanged: _load,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ materials

class _MaterialsTab extends StatefulWidget {
  final Course course;
  final List<CourseMaterial> materials;
  final Future<void> Function() onChanged;

  const _MaterialsTab({
    required this.course,
    required this.materials,
    required this.onChanged,
  });

  @override
  State<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends State<_MaterialsTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String _type = 'book';
  ChosenFile? _file;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await FileStore.pick(['pdf', 'doc', 'docx', 'ppt', 'pptx']);
    if (f == null) return;
    if (f.size > FileStore.maxBytes) {
      if (!mounted) return;
      showMsg(context, 'File is too large (max 20 MB).', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _file = f);
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    final f = _file;
    if (f == null) {
      showMsg(context, 'Choose a file first.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final rel = await FileStore.saveCopy(
          f.path, 'course_materials/${widget.course.id}');
      await Repo.addMaterial(widget.course.id, _title.text, _type, rel);
      _title.clear();
      _file = null;
      await widget.onChanged();
      if (!mounted) return;
      showMsg(context, 'Material uploaded.');
    } catch (e) {
      if (!mounted) return;
      showMsg(context, 'Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFile(CourseMaterial m) async {
    final err = await FileStore.open(m.filePath);
    if (err != null && mounted) showMsg(context, err, error: true);
  }

  Future<void> _delete(CourseMaterial m) async {
    final ok = await confirmDialog(context, 'Delete "${m.title}"?',
        confirmLabel: 'Delete');
    if (!ok) return;
    final path = await Repo.deleteMaterial(m.id);
    if (path != null) await FileStore.delete(path);
    await widget.onChanged();
    if (!mounted) return;
    showMsg(context, 'Material removed.');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabPage(
      children: [
        Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Upload Study Material'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  decoration: inputDeco('Title'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownField<String>(
                  label: 'Type',
                  value: _type,
                  items: const [
                    DropdownMenuItem<String>(value: 'book', child: Text('Book')),
                    DropdownMenuItem<String>(
                        value: 'slides', child: Text('Slides')),
                    DropdownMenuItem<String>(value: 'pdf', child: Text('PDF')),
                    DropdownMenuItem<String>(
                        value: 'other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'book'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _file == null ? 'Choose file (pdf/doc/ppt)' : _file!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                BusyButton(label: 'Upload', busy: _busy, onPressed: _upload),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: widget.materials.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: MutedText('No material uploaded yet.'),
                )
              : Column(
                  children: [
                    for (final m in widget.materials)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(m.title),
                        subtitle: Text(m.type),
                        onTap: () => _openFile(m),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade700),
                          onPressed: () => _delete(m),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ================================================================= syllabus

class _SyllabusTab extends StatefulWidget {
  final Course course;
  final List<SyllabusItem> items;
  final Future<void> Function() onChanged;

  const _SyllabusTab({
    required this.course,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_SyllabusTab> createState() => _SyllabusTabState();
}

class _SyllabusTabState extends State<_SyllabusTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _week = TextEditingController();
  final _topic = TextEditingController();
  String _phase = 'before_mid';
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _week.dispose();
    _topic.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await Repo.addSyllabus(
        widget.course.id, toInt(_week.text), _topic.text, _phase);
    _week.clear();
    _topic.clear();
    await widget.onChanged();
    if (!mounted) return;
    setState(() => _busy = false);
    showMsg(context, 'Syllabus item added.');
  }

  Future<void> _cover(SyllabusItem item) async {
    await Repo.markCovered(item.id);
    await widget.onChanged();
    if (!mounted) return;
    showMsg(context, 'Marked as covered.');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return TabPage(
      children: [
        Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Syllabus Outline'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _week,
                        keyboardType: TextInputType.number,
                        decoration: inputDeco('Week #'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return (n == null || n < 1) ? 'Min 1' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _topic,
                        decoration: inputDeco('Topic'),
                        validator: requiredValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownField<String>(
                  label: 'Phase',
                  value: _phase,
                  items: const [
                    DropdownMenuItem<String>(
                        value: 'before_mid', child: Text('Before Mid')),
                    DropdownMenuItem<String>(
                        value: 'before_final', child: Text('Before Final')),
                  ],
                  onChanged: (v) => setState(() => _phase = v ?? 'before_mid'),
                ),
                const SizedBox(height: 12),
                BusyButton(label: 'Add Week', busy: _busy, onPressed: _add),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: widget.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: MutedText('No syllabus items yet.'),
                )
              : Column(
                  children: [
                    for (final item in widget.items)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: item.isCovered
                              ? Colors.green.shade100
                              : Colors.amber.shade100,
                          child: Text('${item.weekNumber}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(item.topic),
                        subtitle: Text(
                            '${item.phaseLabel} · ${item.isCovered ? "Covered" : "Pending"}'),
                        trailing: item.isCovered
                            ? Icon(Icons.check_circle,
                                color: Colors.green.shade600)
                            : TextButton(
                                onPressed: () => _cover(item),
                                child: const Text('Mark covered'),
                              ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ================================================================== quizzes

class _QuizzesTab extends StatelessWidget {
  final Course course;
  final List<Quiz> quizzes;
  final Future<void> Function() onChanged;

  const _QuizzesTab({
    required this.course,
    required this.quizzes,
    required this.onChanged,
  });

  Future<void> _create(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
          builder: (_) => TeacherQuizCreateScreen(course: course)),
    );
    await onChanged();
    if (msg != null) showMsgOn(messenger, msg);
  }

  Future<void> _results(BuildContext context, Quiz q) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => TeacherQuizResultsScreen(course: course, quiz: q)),
    );
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Quizzes')),
            FilledButton(
              style: slateButton(),
              onPressed: () => _create(context),
              child: const Text('Generate Quiz'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (quizzes.isEmpty)
          const Panel(child: MutedText('No quizzes yet.')),
        for (final q in quizzes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        MutedText(
                            '${fmtDt(q.availableFrom)} to ${fmtDt(q.availableUntil)} · ${q.totalMarks} marks'),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _results(context, q),
                    child: const Text('Results'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================== assignments

class _AssignmentsTab extends StatelessWidget {
  final Course course;
  final List<Assignment> assignments;
  final Future<void> Function() onChanged;

  const _AssignmentsTab({
    required this.course,
    required this.assignments,
    required this.onChanged,
  });

  Future<void> _create(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
          builder: (_) => TeacherAssignmentCreateScreen(course: course)),
    );
    await onChanged();
    if (msg != null) showMsgOn(messenger, msg);
  }

  Future<void> _submissions(BuildContext context, Assignment a) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) =>
              TeacherSubmissionsScreen(course: course, assignment: a)),
    );
    await onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle('Assignments')),
            FilledButton(
              style: slateButton(),
              onPressed: () => _create(context),
              child: const Text('Create Assignment'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          const Panel(child: MutedText('No assignments yet.')),
        for (final a in assignments)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        MutedText(
                            'Due ${fmtDt(a.availableUntil)} · ${a.totalMarks} marks'),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _submissions(context, a),
                    child: const Text('Submissions'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ================================================================= students

class _StudentsTab extends StatelessWidget {
  final Course course;
  final List<AppUser> students;
  final List<AppUser> pending;
  final Future<void> Function() onChanged;

  const _StudentsTab({
    required this.course,
    required this.students,
    required this.pending,
    required this.onChanged,
  });

  Future<void> _approve(BuildContext context, AppUser s) async {
    await Repo.approveStudent(course, s);
    await onChanged();
    if (context.mounted) showMsg(context, 'Student approved.');
  }

  Future<void> _reject(BuildContext context, AppUser s) async {
    await Repo.rejectStudent(course, s);
    await onChanged();
    if (context.mounted) showMsg(context, 'Request rejected.');
  }

  Future<void> _remove(BuildContext context, AppUser s) async {
    final ok = await confirmDialog(
        context, 'Remove this student from the course?',
        confirmLabel: 'Remove');
    if (!ok) return;
    await Repo.removeStudent(course, s);
    await onChanged();
    if (context.mounted) showMsg(context, 'Student removed from course.');
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      children: [
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              const SectionTitle('Pending Requests'),
              const SizedBox(width: 8),
              StatusChip(
                text: '${pending.length}',
                background: Colors.amber.shade100,
                foreground: Colors.amber.shade900,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final s in pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                color: Colors.amber.shade50,
                borderColor: Colors.amber.shade200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AvatarLetter(name: s.name, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              MutedText(s.registrationNumber),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600),
                          onPressed: () => _approve(context, s),
                          child: const Text('Approve'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                          ),
                          onPressed: () => _reject(context, s),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            const Expanded(child: SectionTitle('Enrolled Students')),
            MutedText('${students.length} total'),
          ],
        ),
        const SizedBox(height: 10),
        if (students.isEmpty)
          const Panel(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  MutedText('No students enrolled yet.'),
                  SizedBox(height: 4),
                  MutedText(
                      'Students can find this course under "Browse Courses" on their dashboard and request to join - approved requests will show up here.',
                      size: 12),
                ],
              ),
            ),
          ),
        for (final s in students)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Row(
                children: [
                  AvatarLetter(name: s.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        MutedText(s.registrationNumber),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _remove(context, s),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
