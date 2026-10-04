import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/models.dart';
import '../core/repo.dart';
import '../core/utils.dart';
import 'common.dart';

// ============================================================== quiz builder

/// Controllers for one editable question in the quiz builder.
class _QForm {
  final TextEditingController text;
  final TextEditingController correct;
  final TextEditingController marks;
  final List<TextEditingController> options;
  String type;

  _QForm.fromDraft(QuestionDraft d)
      : text = TextEditingController(text: d.questionText),
        correct = TextEditingController(text: d.correctAnswer),
        marks = TextEditingController(text: d.marks.toString()),
        options = [for (final o in d.options) TextEditingController(text: o)],
        type = d.type;

  void dispose() {
    text.dispose();
    correct.dispose();
    marks.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class TeacherQuizCreateScreen extends StatefulWidget {
  final Course course;
  const TeacherQuizCreateScreen({super.key, required this.course});

  @override
  State<TeacherQuizCreateScreen> createState() =>
      _TeacherQuizCreateScreenState();
}

class _TeacherQuizCreateScreenState extends State<TeacherQuizCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _range = TextEditingController();
  final _aiMarks = TextEditingController(text: '10');
  DateTime? _from;
  DateTime? _until;

  List<CourseMaterial> _materials = [];
  String _covered = '';
  int? _materialId;
  String _mix = 'mixed';
  bool _loading = true;
  bool _aiLoading = false;
  String _aiError = '';
  bool _saving = false;

  final List<_QForm> _qs = [_QForm.fromDraft(QuestionDraft())];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final materials = await Repo.materialsOf(widget.course.id);
    final covered = await Repo.coveredTopics(widget.course.id);
    if (!mounted) return;
    setState(() {
      _materials = materials;
      _covered = covered;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _range.dispose();
    _aiMarks.dispose();
    for (final q in _qs) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final id = _materialId;
    if (id == null) {
      setState(() => _aiError = 'Pick a material first.');
      return;
    }
    if (_range.text.trim().isEmpty) {
      setState(() => _aiError = 'Tell it which part of the material to cover.');
      return;
    }
    final marks = int.tryParse(_aiMarks.text.trim());
    if (marks == null || marks < 1 || marks > 100) {
      setState(() => _aiError = 'Enter total marks (1-100).');
      return;
    }
    CourseMaterial? material;
    for (final m in _materials) {
      if (m.id == id) material = m;
    }
    if (material == null) {
      setState(() => _aiError = 'Pick a material first.');
      return;
    }

    setState(() {
      _aiLoading = true;
      _aiError = '';
    });
    try {
      final drafts = await AiQuizGenerator.draftQuestions(
        course: widget.course,
        material: material,
        range: _range.text.trim(),
        totalMarks: marks,
        mix: _mix,
      );
      if (!mounted) return;
      final old = List<_QForm>.from(_qs);
      setState(() {
        _qs
          ..clear()
          ..addAll(drafts.map(_QForm.fromDraft));
      });
      _disposeLater(old);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _addQuestion() {
    setState(() => _qs.add(_QForm.fromDraft(QuestionDraft())));
  }

  void _removeQuestion(int i) {
    late _QForm removed;
    setState(() {
      removed = _qs.removeAt(i);
    });
    _disposeLater(<_QForm>[removed]);
  }

  /// Dispose controllers after the frame that stops using them.
  void _disposeLater(List<_QForm> forms) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final f in forms) {
        f.dispose();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final from = _from;
    final until = _until;
    if (from == null || until == null) {
      showMsg(context, 'Choose both available-from and available-until.',
          error: true);
      return;
    }
    if (!until.isAfter(from)) {
      showMsg(context, 'Available until must be after available from.',
          error: true);
      return;
    }

    final drafts = <QuestionDraft>[];
    for (var i = 0; i < _qs.length; i++) {
      final q = _qs[i];
      final marks = int.tryParse(q.marks.text.trim()) ?? 0;
      final opts = q.options.map((c) => c.text.trim()).toList();
      final correct = q.correct.text.trim();
      if (q.type == 'mcq') {
        final filled = opts.where((o) => o.isNotEmpty).toList();
        if (filled.length < 2) {
          showMsg(context, 'Question ${i + 1}: add at least 2 options.',
              error: true);
          return;
        }
        final match =
            filled.any((o) => o.toLowerCase() == correct.toLowerCase());
        if (!match) {
          showMsg(context,
              'Question ${i + 1}: correct answer must match one of the options exactly.',
              error: true);
          return;
        }
      }
      drafts.add(QuestionDraft(
        questionText: q.text.text.trim(),
        type: q.type,
        options: opts,
        correctAnswer: correct,
        marks: marks,
      ));
    }

    setState(() => _saving = true);
    try {
      await Repo.createQuiz(
        course: widget.course,
        title: _title.text,
        from: from,
        until: until,
        questions: drafts,
      );
      if (!mounted) return;
      Navigator.of(context).pop('Quiz created and students notified.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMsg(context, 'Could not save quiz: $e', error: true);
    }
  }

  Widget _aiPanel() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle('Draft questions with AI (optional)'),
          const SizedBox(height: 12),
          DropdownField<int>(
            label: 'Uploaded material',
            value: _materialId,
            items: [
              for (final m in _materials)
                DropdownMenuItem<int>(
                  value: m.id,
                  child: Text('${m.title} (${m.type})',
                      overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _materialId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _range,
            decoration:
                inputDeco('Which part?', hint: 'e.g. Chapter 1-2 / Page 1-20'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _aiMarks,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Total marks'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownField<String>(
                  label: 'Question mix',
                  value: _mix,
                  items: const [
                    DropdownMenuItem<String>(
                        value: 'mixed', child: Text('Mixed (MCQ + written)')),
                    DropdownMenuItem<String>(
                        value: 'mcq_only', child: Text('All MCQ')),
                    DropdownMenuItem<String>(
                        value: 'written_only', child: Text('All written')),
                  ],
                  onChanged: (v) => setState(() => _mix = v ?? 'mixed'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: BusyButton(
              label: 'Generate Draft from Material',
              busy: _aiLoading,
              onPressed: _generate,
            ),
          ),
          if (_aiError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_aiError,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          const MutedText(
              'This fills the questions below - review and edit before saving.',
              size: 12),
        ],
      ),
    );
  }

  Widget _questionCard(int i) {
    final q = _qs[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Question ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (_qs.length > 1)
                TextButton(
                  onPressed: () => _removeQuestion(i),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700),
                  child: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: q.text,
            decoration: inputDeco('Question text'),
            validator: requiredValidator,
            maxLines: null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownField<String>(
                  label: 'Type',
                  value: q.type,
                  items: const [
                    DropdownMenuItem<String>(value: 'mcq', child: Text('MCQ')),
                    DropdownMenuItem<String>(
                        value: 'short', child: Text('Short Answer')),
                  ],
                  onChanged: (v) => setState(() => q.type = v ?? 'mcq'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: q.marks,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Marks'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n < 1) ? 'Min 1' : null;
                  },
                ),
              ),
            ],
          ),
          if (q.type == 'mcq') ...[
            const SizedBox(height: 10),
            for (var oi = 0; oi < q.options.length; oi++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: q.options[oi],
                  decoration: inputDeco('Option ${oi + 1}'),
                ),
              ),
          ],
          const SizedBox(height: 2),
          TextFormField(
            controller: q.correct,
            decoration: inputDeco('Correct answer (exact text)'),
            validator: requiredValidator,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Generate Quiz');
    return PageScaffold(
      title: 'Generate Quiz',
      children: [
        Text('Generate Quiz - ${widget.course.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Panel(
          color: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          child: Text(
            'Covered so far: ${_covered.isEmpty ? "No topics marked covered yet." : _covered}',
            style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        _aiPanel(),
        const SizedBox(height: 12),
        Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _title,
                  decoration: inputDeco('Quiz Title'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  label: 'Available From',
                  value: _from,
                  onChanged: (d) => setState(() => _from = d),
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  label: 'Available Until',
                  value: _until,
                  onChanged: (d) => setState(() => _until = d),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _qs.length; i++) _questionCard(i),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ),
                const SizedBox(height: 16),
                BusyButton(
                  label: 'Create Quiz & Notify Students',
                  busy: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================== quiz results

class TeacherQuizResultsScreen extends StatefulWidget {
  final Course course;
  final Quiz quiz;
  const TeacherQuizResultsScreen(
      {super.key, required this.course, required this.quiz});

  @override
  State<TeacherQuizResultsScreen> createState() =>
      _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState extends State<TeacherQuizResultsScreen> {
  List<QuizSubmission> _subs = [];
  bool _loading = true;
  bool _busyAll = false;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Repo.quizSubmissionsOf(widget.quiz.id);
    if (!mounted) return;
    setState(() {
      _subs = s;
      _loading = false;
    });
  }

  Future<void> _check(QuizSubmission s) async {
    setState(() => _busyId = s.id);
    try {
      await AiGrader.gradeQuizSubmission(s);
      await _load();
      if (!mounted) return;
      showMsg(context, 'Submission checked with AI.');
    } catch (e) {
      if (!mounted) return;
      showMsg(context, 'AI check failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _checkAll() async {
    final pending = _subs.where((s) => s.checkedAt == null).toList();
    if (pending.isEmpty) return;
    setState(() => _busyAll = true);
    var checked = 0;
    var failed = 0;
    for (final s in pending) {
      try {
        await AiGrader.gradeQuizSubmission(s);
        checked++;
      } catch (_) {
        failed++;
      }
    }
    await _load();
    if (!mounted) return;
    setState(() => _busyAll = false);
    var message = '$checked submission(s) checked with AI.';
    if (failed > 0) {
      message += ' $failed failed - you can check those individually.';
    }
    showMsg(context, message, error: failed > 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Quiz Results');
    final pendingCount = _subs.where((s) => s.checkedAt == null).length;

    return PageScaffold(
      title: 'Quiz Results',
      children: [
        Text('${widget.quiz.title} - Results',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (pendingCount > 0) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: BusyButton(
              label: 'Check All with AI ($pendingCount pending)',
              busy: _busyAll,
              onPressed: _checkAll,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_subs.isEmpty) const Panel(child: MutedText('No submissions yet.')),
        for (final s in _subs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.studentName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            MutedText(s.studentReg),
                          ],
                        ),
                      ),
                      s.checkedAt != null
                          ? StatusChip(
                              text: 'Checked',
                              background: Colors.green.shade50,
                              foreground: Colors.green.shade700)
                          : StatusChip(
                              text: 'Pending',
                              background: Colors.amber.shade50,
                              foreground: Colors.amber.shade800),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Score: ${s.score ?? "Pending"} / ${widget.quiz.totalMarks}',
                      style: const TextStyle(fontSize: 15)),
                  MutedText('Submitted ${fmtDt(s.submittedAt)}'),
                  const SizedBox(height: 4),
                  _busyId == s.id
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : TextButton(
                          onPressed: _busyAll ? null : () => _check(s),
                          child: Text(s.checkedAt != null
                              ? 'Re-check with AI'
                              : 'Check with AI'),
                        ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
