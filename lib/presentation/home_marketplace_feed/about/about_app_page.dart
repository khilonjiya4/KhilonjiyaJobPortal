// File: lib/presentation/home_marketplace_feed/about/about_app_page.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({Key? key}) : super(key: key);

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String _versionText = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;

      setState(() {
        _versionText = "${info.version} (${info.buildNumber})";
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionText = "1.0.0");
    }
  }

  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("About"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _brandCard(),
          const SizedBox(height: 12),

          _card(
            title: "What is Khilonjiya?",
            body:
                "Khilonjiya is a job marketplace app focused on Assam and nearby regions. "
                "It helps job seekers find relevant opportunities and helps employers post genuine jobs.",
          ),

          _card(
            title: "Company",
            body:
                "${AppLinks.companyName} operates this application and provides the services offered inside the app.",
          ),

          _tile(
            icon: Icons.public,
            title: "Website",
            subtitle: AppLinks.websiteUrl,
            onTap: () => _openUrl(AppLinks.websiteUrl),
          ),

          _tile(
            icon: Icons.mail_outline,
            title: "Support Email",
            subtitle: AppLinks.supportEmail,
            onTap: () => _openUrl("mailto:${AppLinks.supportEmail}"),
          ),

          _tile(
            icon: Icons.shield_outlined,
            title: "Privacy Policy",
            subtitle: AppLinks.privacyPolicyUrl,
            onTap: () => _openUrl(AppLinks.privacyPolicyUrl),
          ),

          _tile(
            icon: Icons.description_outlined,
            title: "Terms & Conditions",
            subtitle: AppLinks.termsUrl,
            onTap: () => _openUrl(AppLinks.termsUrl),
          ),

          _tile(
            icon: Icons.currency_rupee_rounded,
            title: "Refund & Cancellation Policy",
            subtitle: AppLinks.refundPolicyUrl,
            onTap: () => _openUrl(AppLinks.refundPolicyUrl),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: KhilonjiyaUI.cardDecoration(radius: 18),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF475569)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "App Version: $_versionText",
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _brandCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: KhilonjiyaUI.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Khilonjiya",
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLinks.companyName,
                  style: KhilonjiyaUI.sub.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8)),
          const SizedBox(height: 8),
          Text(
            body.trim(),
            style: KhilonjiyaUI.body.copyWith(height: 1.35),
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
    final sub = subtitle.trim();

    return InkWell(
      onTap: sub.isEmpty ? null : onTap,
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
                    sub.isEmpty ? "Not set" : sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              sub.isEmpty ? Icons.lock_outline : Icons.open_in_new,
              color: KhilonjiyaUI.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}