import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../services/job_seeker_home_service.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;

  bool _notificationEnabled = true;
  bool _jobAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final profile = await _service.fetchMyProfile();

      _notificationEnabled = (profile['notification_enabled'] ?? true) == true;
      _jobAlertsEnabled = (profile['job_alerts_enabled'] ?? true) == true;
    } catch (_) {
      // ignore
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await _service.updateMyProfile({
        'notification_enabled': _notificationEnabled,
        'job_alerts_enabled': _jobAlertsEnabled,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved")),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save settings")),
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
        title: const Text("Notifications"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _switchTile(
                  title: "App notifications",
                  subtitle: "General app notifications",
                  value: _notificationEnabled,
                  onChanged: (v) => setState(() => _notificationEnabled = v),
                ),
                _switchTile(
                  title: "Job alerts",
                  subtitle: "Recommended jobs and updates",
                  value: _jobAlertsEnabled,
                  onChanged: (v) => setState(() => _jobAlertsEnabled = v),
                ),
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
                  "Note: Push notifications will be enabled later when the system is fully integrated.",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          subtitle,
          style: KhilonjiyaUI.sub.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}