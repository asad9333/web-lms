import 'package:flutter/material.dart';
import '../core/ai.dart';
import 'common.dart';

/// Replaces the web app's .env (GEMINI_API_KEY / GROQ_API_KEY ...).
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final _geminiKey = TextEditingController();
  final _geminiModel = TextEditingController();
  final _groqKey = TextEditingController();
  final _groqModel = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hide = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await AiSettings.load();
    if (!mounted) return;
    setState(() {
      _geminiKey.text = cfg['geminiKey'] ?? '';
      _geminiModel.text = cfg['geminiModel'] ?? '';
      _groqKey.text = cfg['groqKey'] ?? '';
      _groqModel.text = cfg['groqModel'] ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AiSettings.save(
      geminiKey: _geminiKey.text,
      geminiModel: _geminiModel.text,
      groqKey: _groqKey.text,
      groqModel: _groqModel.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showMsg(context, 'AI settings saved.');
  }

  @override
  void dispose() {
    _geminiKey.dispose();
    _geminiModel.dispose();
    _groqKey.dispose();
    _groqModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingPage(title: 'AI Settings');
    return PageScaffold(
      title: 'AI Settings',
      children: [
        const MutedText(
            'AI quiz/assignment drafting and AI grading need an internet connection and your own API key. Gemini is tried first, Groq is the automatic fallback for text. Keys are stored only on this device.'),
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Gemini'),
              const SizedBox(height: 12),
              TextField(
                controller: _geminiKey,
                obscureText: _hide,
                decoration: inputDeco('Gemini API key').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _geminiModel,
                decoration: inputDeco('Gemini model'),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Groq (fallback)'),
              const SizedBox(height: 12),
              TextField(
                controller: _groqKey,
                obscureText: _hide,
                decoration: inputDeco('Groq API key'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _groqModel,
                decoration: inputDeco('Groq model'),
              ),
              const SizedBox(height: 20),
              BusyButton(label: 'Save', busy: _saving, onPressed: _save),
            ],
          ),
        ),
      ],
    );
  }
}
