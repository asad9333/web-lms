import 'package:flutter/material.dart';
import '../core/repo.dart';
import '../core/security.dart';
import '../core/session.dart';
import 'common.dart';
import 'root.dart';

void _goHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const RootGate()),
    (r) => false,
  );
}

/// Shared look for the small auth cards.
class _AuthShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _AuthShell({
    required this.title,
    required this.children,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: lmsAppBar('Course LMS'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Panel(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      MutedText(subtitle!),
                    ],
                    const SizedBox(height: 16),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- step 1

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reg = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reg.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final user = await Repo.userByReg(_reg.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (user == null) {
      setState(() => _error = 'No account found with that registration number.');
      return;
    }
    if (user.mustChangePassword) {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            SetupPasswordScreen(registrationNumber: user.registrationNumber),
      ));
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) =>
            LoginPasswordScreen(registrationNumber: user.registrationNumber),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: 'Login',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _reg,
                decoration: inputDeco('Registration Number'),
                validator: requiredValidator,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _continue(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              BusyButton(label: 'Continue', busy: _busy, onPressed: _continue),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- step 2a

class LoginPasswordScreen extends StatefulWidget {
  final String registrationNumber;
  const LoginPasswordScreen({super.key, required this.registrationNumber});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final user = await Repo.userByReg(widget.registrationNumber);
    if (!mounted) return;
    if (user == null || !Passwords.verify(_password.text, user.passwordHash)) {
      setState(() {
        _busy = false;
        _error = 'Incorrect password.';
      });
      return;
    }
    await Session.login(user);
    if (!mounted) return;
    _goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: 'Enter Password',
      subtitle: widget.registrationNumber,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: inputDeco('Password'),
                validator: requiredValidator,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              BusyButton(label: 'Login', busy: _busy, onPressed: _login),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- step 2b

class SetupPasswordScreen extends StatefulWidget {
  final String registrationNumber;
  const SetupPasswordScreen({super.key, required this.registrationNumber});

  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final user = await Repo.userByReg(widget.registrationNumber);
    if (user == null || !user.mustChangePassword) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMsg(context, 'This account is not waiting for a first password.',
          error: true);
      return;
    }
    await Repo.setPassword(user.id, _password.text, mustChange: false);
    final fresh = await Repo.userById(user.id);
    if (fresh != null) {
      await Session.login(fresh);
    }
    if (!mounted) return;
    _goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: 'Set Your Password',
      subtitle:
          '${widget.registrationNumber} - this is your first login. Choose a password to continue.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: inputDeco('New Password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: inputDeco('Confirm Password'),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              BusyButton(
                  label: 'Set Password & Login',
                  busy: _busy,
                  onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------ forced password change

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final u = Session.user;
    if (u == null) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    await Repo.setPassword(u.id, _password.text, mustChange: false);
    await Session.refresh();
    if (!mounted) return;
    _goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      title: 'Set a New Password',
      subtitle:
          'This is your first login (or an admin-assigned password). Please set your own password to continue.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: inputDeco('New Password'),
                validator: (v) => (v == null || v.length < 6)
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: inputDeco('Confirm Password'),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 16),
              BusyButton(label: 'Save Password', busy: _busy, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
