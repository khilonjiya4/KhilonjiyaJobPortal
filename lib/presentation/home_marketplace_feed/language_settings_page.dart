import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final p = await _service.fetchMyProfile();
      _lang = (p['language_preference'] ?? 'en').toString().trim();
      if (_lang.isEmpty) _lang = 'en';
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await _service.updateMyProfile({
        'language_preference': _lang,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save language")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Language"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _radio("English", "en"),
                _radio("Assamese", "as"),
                _radio("Hindi", "hi"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhilonjiyaUI.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Save"),
                ),
                const SizedBox(height: 10),
                Text(
                  "Full translation will be added later. Currently this is used for preference only.",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
    );
  }

  Widget _radio(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _lang,
        onChanged: (v) => setState(() => _lang = v ?? 'en'),
        title: Text(
          title,
          style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}