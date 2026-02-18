import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';

class PoliciesPage extends StatelessWidget {
  const PoliciesPage({Key? key}) : super(key: key);

  // IMPORTANT:
  // Replace these with your real website policy links.
  // Example:
  // https://khilonjiya.com/privacy-policy
  static const String privacyUrl = 'https://khilonjiya.com/privacy-policy';
  static const String termsUrl = 'https://khilonjiya.com/terms';
  static const String refundUrl = 'https://khilonjiya.com/refund-policy';
  static const String cancellationUrl =
      'https://khilonjiya.com/cancellation-policy';
  static const String contactUrl = 'https://khilonjiya.com/contact';

  void _open(BuildContext context, String title, String url) {
    Navigator.pushNamed(
      context,
      AppRoutes.webview,
      arguments: {
        'title': title,
        'url': url,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Policies"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "How we collect and use your data",
            onTap: () => _open(context, "Privacy Policy", privacyUrl),
          ),
          _tile(
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            subtitle: "Rules for using the app",
            onTap: () => _open(context, "Terms & Conditions", termsUrl),
          ),
          _tile(
            icon: Icons.currency_rupee_rounded,
            title: "Refund Policy",
            subtitle: "Refund terms for subscription and payments",
            onTap: () => _open(context, "Refund Policy", refundUrl),
          ),
          _tile(
            icon: Icons.cancel_outlined,
            title: "Cancellation Policy",
            subtitle: "How cancellation works",
            onTap: () => _open(context, "Cancellation Policy", cancellationUrl),
          ),
          _tile(
            icon: Icons.support_agent_outlined,
            title: "Contact",
            subtitle: "Support and grievance",
            onTap: () => _open(context, "Contact", contactUrl),
          ),
          const SizedBox(height: 12),
          Text(
            "All policies must also be published on your official website for Play Store compliance.",
            style: KhilonjiyaUI.sub,
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
                    style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: KhilonjiyaUI.sub.copyWith(fontWeight: FontWeight.w700),
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