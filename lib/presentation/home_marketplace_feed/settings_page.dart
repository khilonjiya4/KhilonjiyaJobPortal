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
        title: Text(
          "Settings",
          style: KhilonjiyaUI.hTitle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _tile(
            context,
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage job alerts & updates",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notificationsSettings);
            },
          ),

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

          _tile(
            context,
            icon: Icons.language_outlined,
            title: "Language",
            subtitle: "English / Assamese (later)",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.languageSettings);
            },
          ),

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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: KhilonjiyaUI.cardDecoration(radius: 20),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: KhilonjiyaUI.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 20,
                color: KhilonjiyaUI.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w600, // lighter but same size
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: KhilonjiyaUI.muted,
            ),
          ],
        ),
      ),
    );
  }
}