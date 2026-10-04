import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/repo.dart';
import 'common.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _teachers = 0;
  int _students = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await Repo.countByRole('teacher');
    final s = await Repo.countByRole('student');
    if (!mounted) return;
    setState(() {
      _teachers = t;
      _students = s;
      _loading = false;
    });
  }

  Widget _stat(String label, int value) {
    return Expanded(
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MutedText(label, size: 14),
            const SizedBox(height: 4),
            Text('$value',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Admin Dashboard');
    return PageScaffold(
      title: 'Admin Dashboard',
      actions: [userMenu(context, showSettings: true)],
      children: [
        Row(
          children: [
            _stat('Teachers', _teachers),
            const SizedBox(width: 12),
            _stat('Students', _students),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            style: slateButton(),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const AdminUsersScreen()));
              _load();
            },
            child: const Text('Manage Users'),
          ),
        ),
      ],
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await Repo.managedUsers();
    if (!mounted) return;
    setState(() {
      _users = u;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final msg = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const AdminCreateUserScreen()),
    );
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    if (msg != null) showMsg(context, msg);
  }

  Future<void> _reset(AppUser u) async {
    final ok = await confirmDialog(context,
        'Reset this password? They will have to set a new one on next login.',
        confirmLabel: 'Reset');
    if (!ok) return;
    await Repo.resetPassword(u.id);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    showMsg(context,
        'Password reset for "${u.registrationNumber}" - they will be asked to set a new password on next login.');
  }

  Future<void> _remove(AppUser u) async {
    final ok = await confirmDialog(context, 'Remove this user?',
        confirmLabel: 'Remove');
    if (!ok) return;
    await Repo.deleteUser(u.id);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    showMsg(context, 'User removed.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'Teachers & Students');
    return PageScaffold(
      title: 'Teachers & Students',
      actions: [userMenu(context, showSettings: true)],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kSlate,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
      children: [
        if (_users.isEmpty)
          const Panel(child: Center(child: MutedText('No users yet.'))),
        for (final u in _users)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarLetter(
                        name: u.name,
                        color: u.isTeacher ? Colors.indigo : kSlate,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            MutedText(u.registrationNumber),
                          ],
                        ),
                      ),
                      StatusChip(
                        text: u.isTeacher ? 'Teacher' : 'Student',
                        background: u.isTeacher
                            ? Colors.indigo.shade50
                            : Colors.blueGrey.shade50,
                        foreground: u.isTeacher
                            ? Colors.indigo.shade700
                            : Colors.blueGrey.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  MutedText(u.mustChangePassword
                      ? 'Must set password on next login'
                      : 'Password set'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _reset(u),
                        child: const Text('Reset Password'),
                      ),
                      TextButton(
                        onPressed: () => _remove(u),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 70),
      ],
    );
  }
}

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reg = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String _role = 'teacher';
  bool _busy = false;

  @override
  void dispose() {
    _reg.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final reg = _reg.text.trim();
    final err = await Repo.createUser(
      registrationNumber: reg,
      name: _name.text.trim(),
      email: _email.text,
      role: _role,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showMsg(context, err, error: true);
      return;
    }
    Navigator.of(context).pop(
        'User created. They can log in with registration number "$reg" - it will ask them to set their own password on first login.');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Add Teacher / Student',
      children: [
        Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _reg,
                  decoration: inputDeco('Registration Number'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: inputDeco('Full Name'),
                  validator: requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDeco('Email (optional)'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    final ok = t.contains('@') && t.contains('.');
                    return ok ? null : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 12),
                DropdownField<String>(
                  label: 'Role',
                  value: _role,
                  items: const [
                    DropdownMenuItem<String>(
                        value: 'teacher', child: Text('Teacher')),
                    DropdownMenuItem<String>(
                        value: 'student', child: Text('Student')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'teacher'),
                ),
                const SizedBox(height: 16),
                BusyButton(
                  label: 'Create User',
                  busy: _busy,
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
