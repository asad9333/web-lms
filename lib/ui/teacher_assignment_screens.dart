import 'package:flutter/material.dart';
import '../core/ai.dart';
import '../core/files.dart';
import '../core/models.dart';
import '../core/repo.dart';
import '../core/utils.dart';
import 'common.dart';

// ========================================================= create assignment

class TeacherAssignmentCreateScreen extends StatefulWidget {
  final Course course;
  const TeacherAssignmentCreateScreen({super.key, required this.course});

  @override
  State<TeacherAssignmentCreateScreen> createState() =>
      _TeacherAssignmentCreateScreenState();
}

class _TeacherAssignmentCreateScreenState
    extends State<TeacherAssignmentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _marks = TextEditingController();
  final _range = TextEditingController();
  final _draftMarks = TextEditingController(text: '20');
  DateTime? _from;
  DateTime? _until;

  List<CourseMaterial> _materials = [];
  int? _materialId;
  bool _loading = true;
  bool _aiLoading = false;
  String _aiError = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final m = await Repo.materialsOf(widget.course.id);
    if (!mounted) return;
    setState(() {
      _materials = m;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _marks.dispose();
    _range.dispose();
    _draftMarks.dispose();
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
    final marks = int.tryParse(_draftMarks.text.trim());
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
      final draft = await AiAssignmentGenerator.draftAssignment(
        course: widget.course,
        material: material,
        range: _range.text.trim(),
        totalMarks: marks,
      );
      if (!mounted) return;
      setState(() {
        _title.text = draft.title;
        _desc.text = draft.description;
        _marks.text = draft.totalMarks.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
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
    setState(() => _saving = true);
    try {
      await Repo.createAssignment(
        course: widget.course,
        title: _title.text,
        description: _desc.text,
        totalMarks: toInt(_marks.text),
        from: from,
        until: until,
      );
      if (!mounted) return;
      Navigator.of(context).pop('Assignment created and students notified.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMsg(context, 'Could not save assignment: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Create Assignment');
    return PageScaffold(
      title: 'Create Assignment',
      children: [
        Text('Create Assignment - ${widget.course.title}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Draft assignment with AI (optional)'),
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
                decoration: inputDeco('Which part?',
                    hint: 'e.g. Chapter 1-2 / Page 1-20'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _draftMarks,
                keyboardType: TextInputType.number,
                decoration: inputDeco('Total marks (approx)'),
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
                  'This fills the fields below - review and edit before saving.',
                  size: 12),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  maxLines: 5,
                  decoration: inputDeco('Description / Instructions'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marks,
                  keyboardType: TextInputType.number,
                  decoration: inputDeco('Total Marks'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return (n == null || n < 1) ? 'Min 1' : null;
                  },
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
                BusyButton(
                  label: 'Create & Notify Students',
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

// ============================================================== submissions

class TeacherSubmissionsScreen extends StatefulWidget {
  final Course course;
  final Assignment assignment;
  const TeacherSubmissionsScreen(
      {super.key, required this.course, required this.assignment});

  @override
  State<TeacherSubmissionsScreen> createState() =>
      _TeacherSubmissionsScreenState();
}

class _TeacherSubmissionsScreenState extends State<TeacherSubmissionsScreen> {
  List<AssignmentSubmission> _subs = [];
  bool _loading = true;
  bool _busyAll = false;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Repo.assignmentSubmissionsOf(widget.assignment.id);
    if (!mounted) return;
    setState(() {
      _subs = s;
      _loading = false;
    });
  }

  Future<void> _aiCheck(AssignmentSubmission s) async {
    setState(() => _busyId = s.id);
    final r = await AiGrader.gradeAssignmentSubmission(s, widget.assignment);
    await _load();
    if (!mounted) return;
    setState(() => _busyId = null);
    if (r.graded) {
      showMsg(context, 'Submission checked with AI.');
    } else {
      showMsg(context, 'AI check failed: ${r.error ?? "unknown error"}',
          error: true);
    }
  }

  Future<void> _aiCheckAll() async {
    final pending = _subs.where((s) => s.checkedAt == null).toList();
    if (pending.isEmpty) return;
    setState(() => _busyAll = true);
    var checked = 0;
    var failed = 0;
    for (final s in pending) {
      final r = await AiGrader.gradeAssignmentSubmission(s, widget.assignment);
      if (r.graded) {
        checked++;
      } else {
        failed++;
      }
    }
    await _load();
    if (!mounted) return;
    setState(() => _busyAll = false);
    var message = '$checked submission(s) checked with AI.';
    if (failed > 0) {
      message +=
          ' $failed need manual grading (unsupported file type or AI error).';
    }
    showMsg(context, message, error: failed > 0);
  }

  Future<void> _saveGrade(
      AssignmentSubmission s, int score, String feedback) async {
    await Repo.gradeAssignment(s.id, score, feedback);
    await _load();
    if (!mounted) return;
    showMsg(context, 'Grade saved.');
  }

  Future<void> _openFile(AssignmentSubmission s) async {
    final err = await FileStore.open(s.filePath);
    if (err != null && mounted) showMsg(context, err, error: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Submissions');
    final a = widget.assignment;
    final pendingCount = _subs.where((s) => s.checkedAt == null).length;

    return PageScaffold(
      title: 'Submissions',
      children: [
        Text('${a.title} - Submissions',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        MutedText(
            'Total marks: ${a.totalMarks}. Use "Check with AI" to auto-grade, or set a score manually below.'),
        const SizedBox(height: 12),
        if (pendingCount > 0) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: BusyButton(
              label: 'Check All with AI ($pendingCount pending)',
              busy: _busyAll,
              onPressed: _aiCheckAll,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_subs.isEmpty) const Panel(child: MutedText('No submissions yet.')),
        for (final s in _subs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SubmissionCard(
              key: ValueKey<String>(
                  '${s.id}-${s.score}-${s.feedback}-${s.checkedAt}'),
              submission: s,
              totalMarks: a.totalMarks,
              aiBusy: _busyId == s.id,
              disabled: _busyAll,
              onOpen: () => _openFile(s),
              onAiCheck: () => _aiCheck(s),
              onSaveGrade: (score, fb) => _saveGrade(s, score, fb),
            ),
          ),
      ],
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  final AssignmentSubmission submission;
  final int totalMarks;
  final bool aiBusy;
  final bool disabled;
  final VoidCallback onOpen;
  final VoidCallback onAiCheck;
  final void Function(int score, String feedback) onSaveGrade;

  const _SubmissionCard({
    super.key,
    required this.submission,
    required this.totalMarks,
    required this.aiBusy,
    required this.disabled,
    required this.onOpen,
    required this.onAiCheck,
    required this.onSaveGrade,
  });

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _score;
  late final TextEditingController _feedback;

  @override
  void initState() {
    super.initState();
    _score = TextEditingController(
        text: widget.submission.score == null
            ? ''
            : widget.submission.score.toString());
    _feedback = TextEditingController(text: widget.submission.feedback ?? '');
  }

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSaveGrade(toInt(_score.text), _feedback.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${s.studentName} (${s.studentReg})',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          MutedText('Submitted ${fmtDt(s.submittedAt)}', size: 12),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onOpen,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View / Download File'),
              ),
              widget.aiBusy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton.tonal(
                      onPressed: widget.disabled ? null : widget.onAiCheck,
                      child: Text(s.checkedAt != null
                          ? 'Re-check with AI'
                          : 'Check with AI'),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: TextFormField(
                        controller: _score,
                        keyboardType: TextInputType.number,
                        decoration: inputDeco('Score / ${widget.totalMarks}'),
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null) return 'Required';
                          if (n < 0 || n > widget.totalMarks) {
                            return '0-${widget.totalMarks}';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _feedback,
                        decoration: inputDeco('Feedback'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: slateButton(),
                  onPressed: _save,
                  child: Text(
                      s.checkedAt != null ? 'Update Grade' : 'Save Grade'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (s.checkedAt != null)
            MutedText('Checked ${fmtDt(s.checkedAt)}', size: 12)
          else
            Text(
              'Not checked yet - use "Check with AI" above or set a score manually.',
              style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
