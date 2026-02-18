// File: lib/presentation/home_marketplace_feed/settings_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';

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
          // ------------------------------------------------------------
          // NOTIFICATIONS (later)
          // ------------------------------------------------------------
          _tile(
            context,
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage job alerts & updates",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notificationsSettings);
            },
          ),

          // ------------------------------------------------------------
          // PRIVACY + LEGAL
          // ------------------------------------------------------------
          _tile(
            context,
            icon: Icons.lock_outline,
            title: "Privacy Policy",
            subtitle: "How we handle your data",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.privacyPolicy);
            },
          ),

          _tile(
            context,
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            subtitle: "Rules for using the app",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.termsAndConditions);
            },
          ),

          _tile(
            context,
            icon: Icons.currency_rupee_rounded,
            title: "Refund & Cancellation Policy",
            subtitle: "For subscriptions & payments",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.refundPolicy);
            },
          ),

          // ------------------------------------------------------------
          // LANGUAGE (later)
          // ------------------------------------------------------------
          _tile(
            context,
            icon: Icons.language_outlined,
            title: "Language",
            subtitle: "English / Assamese (later)",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.languageSettings);
            },
          ),

          // ------------------------------------------------------------
          // ABOUT
          // ------------------------------------------------------------
          _tile(
            context,
            icon: Icons.info_outline,
            title: "About",
            subtitle: "Company details & app info",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.aboutApp);
            },
          ),

          _tile(
            context,
            icon: Icons.support_agent_outlined,
            title: "Contact & Support",
            subtitle: "Help, email, report issues",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.contactSupport);
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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