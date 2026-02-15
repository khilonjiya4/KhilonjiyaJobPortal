import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Settings"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            onTap: () {},
          ),
          _tile(
            icon: Icons.lock_outline,
            title: "Privacy",
            onTap: () {},
          ),
          _tile(
            icon: Icons.language_outlined,
            title: "Language",
            onTap: () {},
          ),
          _tile(
            icon: Icons.info_outline,
            title: "About",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KhilonjiyaUI.r16,
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF334155)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: KhilonjiyaUI.body.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: KhilonjiyaUI.muted),
          ],
        ),
      ),
    );
  }
}