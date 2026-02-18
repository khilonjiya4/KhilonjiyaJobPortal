import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({Key? key}) : super(key: key);

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
        title: const Text("Privacy & Policies"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.policy_outlined,
            title: "Policies",
            subtitle: "Privacy policy, terms, refund, cancellation",
            onTap: () => _go(context, AppRoutes.policies),
          ),
          _tile(
            icon: Icons.shield_outlined,
            title: "Profile visibility",
            subtitle: "Control whether profile is public",
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("This will be added in Profile settings"),
                ),
              );
            },
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