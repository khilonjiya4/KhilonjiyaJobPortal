// File: lib/presentation/home_marketplace_feed/support/contact_support_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/app_links.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({Key? key}) : super(key: key);

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forced email
    final email = "support@khilonjiya.com";
    final phone = AppLinks.supportPhone.trim();
    final whatsapp = AppLinks.supportWhatsapp.trim();
    final supportUrl = AppLinks.contactSupportUrl.trim();

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Contact & Support"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------
          // SUPPORT CARD
          // ------------------------------------------------------------
          _card(
            title: "Support",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "For help, contact us using the options below.",
                  style: KhilonjiyaUI.body,
                ),
                const SizedBox(height: 12),

                _actionTile(
                  icon: Icons.email_outlined,
                  title: "Email",
                  value: email,
                  onTap: () => _launch("mailto:$email"),
                ),

                if (phone.isNotEmpty)
                  _actionTile(
                    icon: Icons.call_outlined,
                    title: "Call",
                    value: phone,
                    onTap: () => _launch("tel:$phone"),
                  ),

                if (whatsapp.isNotEmpty)
                  _actionTile(
                    icon: Icons.chat_outlined,
                    title: "WhatsApp",
                    value: whatsapp,
                    onTap: () => _launch("https://wa.me/$whatsapp"),
                  ),

                if (supportUrl.isNotEmpty)
                  _actionTile(
                    icon: Icons.language_outlined,
                    title: "Support website",
                    value: supportUrl,
                    onTap: () => _launch(supportUrl),
                  ),
              ],
            ),
          ),

          // ------------------------------------------------------------
          // HELPLINE NUMBER CARD
          // ------------------------------------------------------------
          _card(
            title: "Helpline Number",
            child: _actionTile(
              icon: Icons.support_agent_outlined,
              title: "Customer Helpline",
              value: "+916003170583",
              onTap: () => _launch("tel:+916003170583"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF334155)),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 18, color: KhilonjiyaUI.muted),
          ],
        ),
      ),
    );
  }
}