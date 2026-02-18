import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Privacy Policy"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            title: "Company",
            body:
                "${AppLinks.companyName} operates this mobile application (Khilonjiya).",
          ),
          _card(
            title: "What data we collect",
            body: """
We may collect:
• Name, phone, email
• Profile details (education, skills, experience)
• Resume and profile photo (if uploaded)
• Job activity (viewed/saved/applied)
• Location (only if you provide it for nearby jobs)
""",
          ),
          _card(
            title: "Why we collect data",
            body: """
We use your data to:
• Create and manage your account
• Show jobs relevant to your location and preferences
• Allow employers to view applications
• Improve app performance and security
""",
          ),
          _card(
            title: "Storage and security",
            body:
                "Your uploaded resume and photo are stored securely in Supabase Storage. Access is restricted by security policies.",
          ),
          _card(
            title: "Sharing",
            body: """
We do not sell your personal data.
Your application details are shared only with employers when you apply for a job.
""",
          ),
          _card(
            title: "Your rights",
            body: """
You can:
• Edit your profile anytime
• Delete uploaded resume/photo by replacing them
• Request account deletion by contacting support
""",
          ),
          _card(
            title: "Contact",
            body:
                "For privacy-related requests, contact support from Settings → Contact & Support.",
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8)),
          const SizedBox(height: 8),
          Text(body.trim(), style: KhilonjiyaUI.body),
        ],
      ),
    );
  }
}