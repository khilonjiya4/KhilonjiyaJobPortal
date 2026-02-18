import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../core/app_export.dart';

import '../../routes/app_routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  void _go(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

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
            subtitle: "Manage job alerts and app notifications",
            onTap: () => _go(context, AppRoutes.notificationSettings),
          ),
          _tile(
            icon: Icons.lock_outline,
            title: "Privacy & Policies",
            subtitle: "Privacy policy, terms, refund and more",
            onTap: () => _go(context, AppRoutes.privacySettings),
          ),
          _tile(
            icon: Icons.language_outlined,
            title: "Language",
            subtitle: "Choose your preferred language",
            onTap: () => _go(context, AppRoutes.languageSettings),
          ),
          _tile(
            icon: Icons.info_outline,
            title: "About",
            subtitle: "App info, version, company details",
            onTap: () => _go(context, AppRoutes.about),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: KhilonjiyaUI.muted),
          ],
        ),
      ),
    );
  }
}