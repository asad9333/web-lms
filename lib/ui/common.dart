import 'package:flutter/material.dart';
import '../core/session.dart';
import '../core/utils.dart';
import 'root.dart';
import 'settings_screen.dart';

const Color kSlate = Color(0xFF1E293B);
const Color kSlateLight = Color(0xFF334155);
const Color kBg = Color(0xFFF3F4F6);

void showMsgOn(ScaffoldMessengerState messenger, String text,
    {bool error = false}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    behavior: SnackBarBehavior.floating,
  ));
}

void showMsg(BuildContext context, String text, {bool error = false}) {
  showMsgOn(ScaffoldMessenger.of(context), text, error: error);
}

Future<bool> confirmDialog(BuildContext context, String message,
    {String confirmLabel = 'Yes'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

String? requiredValidator(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null;

InputDecoration inputDeco(String label, {String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );

ButtonStyle slateButton() => FilledButton.styleFrom(
      backgroundColor: kSlate,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

/// Logged-in user menu (name/role, optional AI settings, logout).
Widget userMenu(BuildContext context, {bool showSettings = false}) {
  final u = Session.user;
  return PopupMenuButton<String>(
    icon: const Icon(Icons.account_circle_outlined),
    onSelected: (v) async {
      if (v == 'logout') {
        await Session.logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const RootGate()),
          (r) => false,
        );
      } else if (v == 'settings') {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AiSettingsScreen()),
        );
      }
    },
    itemBuilder: (ctx) => <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        child: Text(u == null ? '' : '${u.name} (${u.role})'),
      ),
      if (showSettings)
        const PopupMenuItem<String>(
          value: 'settings',
          child: Text('AI Settings'),
        ),
      const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
    ],
  );
}

AppBar lmsAppBar(String title,
    {List<Widget> actions = const <Widget>[], PreferredSizeWidget? bottom}) {
  return AppBar(
    backgroundColor: kSlate,
    foregroundColor: Colors.white,
    title: Text(title),
    actions: actions,
    bottom: bottom,
  );
}

/// Standard page: slate app bar + centred, width-limited, scrollable body.
class PageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final List<Widget> children;
  final Widget? floatingActionButton;

  const PageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions = const <Widget>[],
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: lmsAppBar(title, actions: actions),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  final String title;
  const LoadingPage({super.key, this.title = 'Course LMS'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: lmsAppBar(title),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      );
}

class MutedText extends StatelessWidget {
  final String text;
  final double size;
  const MutedText(this.text, {super.key, this.size = 13});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(fontSize: size, color: Colors.grey.shade600),
      );
}

class StatusChip extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const StatusChip({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, color: foreground)),
      );
}

class DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: inputDeco(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: inputDeco(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value == null ? 'Select date & time' : fmtDt(value),
          style: TextStyle(
            color: value == null ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Filled button that shows a spinner while busy.
class BusyButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  const BusyButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: slateButton(),
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// Scrollable, centred tab body used by the course tabs.
class TabPage extends StatelessWidget {
  final List<Widget> children;
  const TabPage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}

class AvatarLetter extends StatelessWidget {
  final String name;
  final Color color;
  const AvatarLetter({super.key, required this.name, this.color = kSlate});

  @override
  Widget build(BuildContext context) => CircleAvatar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase()),
      );
}
