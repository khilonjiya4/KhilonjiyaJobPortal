// File: lib/presentation/home_marketplace_feed/legal/privacy_policy_page.dart

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "18 Feb 2026";

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
          _headerCard(),
          const SizedBox(height: 12),

          _card(
            title: "1. Who we are",
            body: """
${AppLinks.companyName} (“we”, “our”, “us”) operates the Khilonjiya mobile application (“App”).

This Privacy Policy explains how we collect, use, store, and share information when you use the App.
""",
          ),

          _card(
            title: "2. Information we collect",
            body: """
We may collect the following information depending on how you use the App:

A) Account & Profile Information
• Full name
• Mobile number
• Email address
• Education, skills, experience, job preferences

B) Uploaded Files
• Resume (PDF/DOC/DOCX etc.)
• Profile photo (optional)

C) Job Activity Data
• Jobs viewed, saved, applied, shared
• Application status history (if applicable)

D) Location Data (Optional)
• City / State / District you enter
• Current latitude/longitude only if you provide it (used for “Nearby jobs”)

E) Device & Technical Data
• App usage events, crash logs (if enabled by platform)
• Basic device information (for security and fraud prevention)
""",
          ),

          _card(
            title: "3. Why we collect your data (Purpose)",
            body: """
We use your information to:
• Create and manage your account
• Show relevant job listings based on your profile and preferences
• Enable job applications and allow employers to review applications
• Improve app performance, safety, and reliability
• Prevent spam, fraud, and misuse of the platform
""",
          ),

          _card(
            title: "4. How employers see your information",
            body: """
When you apply for a job, the employer may receive and view your application information, including:
• Your name and contact details
• Your education, skills, and experience
• Your resume file (if uploaded)
• Any additional details you submit during application

Employers are responsible for how they handle applicant information once they receive it.
""",
          ),

          _card(
            title: "5. Storage & security",
            body: """
Your data is stored using Supabase (database + file storage).

We apply security controls such as:
• Authentication (login required)
• Row-Level Security (RLS) policies
• Access restrictions for files stored in buckets

However, no system can be guaranteed 100% secure. You should protect your account credentials.
""",
          ),

          _card(
            title: "6. Sharing of data",
            body: """
We do not sell your personal data.

We may share information only in the following cases:
• With employers when you apply for a job
• With service providers (e.g., Supabase) strictly to operate the App
• When required by law, regulation, or valid legal process
• To protect the rights, safety, and security of users and the platform
""",
          ),

          _card(
            title: "7. Data retention",
            body: """
We retain your information as long as:
• Your account is active, or
• It is needed to provide services, resolve disputes, enforce policies, or comply with legal requirements.

You may request deletion of your account and associated data.
Some information may be retained if legally required (e.g., transaction records).
""",
          ),

          _card(
            title: "8. Your rights and choices",
            body: """
You can:
• View and edit your profile information anytime
• Replace your resume and profile photo anytime
• Control what you choose to provide (e.g., location, optional fields)
• Request account deletion via Support

To request deletion:
Go to Settings → Contact & Support and submit a deletion request.
""",
          ),

          _card(
            title: "9. Children’s privacy",
            body: """
This App is not intended for children under 18.

If you believe a child has provided personal data, contact Support and we will take appropriate action.
""",
          ),

          _card(
            title: "10. Third-party links",
            body: """
The App may contain links to third-party websites or services (for example, employer websites or external apply links).

We are not responsible for third-party privacy practices. Please review their policies before sharing information.
""",
          ),

          _card(
            title: "11. Updates to this Privacy Policy",
            body: """
We may update this Privacy Policy from time to time.

We will update the “Last updated” date at the top of this page. Continued use of the App means you accept the updated policy.
""",
          ),

          _card(
            title: "12. Contact",
            body: """
For privacy-related requests or questions, contact us:
• From the App: Settings → Contact & Support
• Email: ${AppLinks.supportEmail}

Company: ${AppLinks.companyName}
""",
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Privacy Policy",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Last updated: $_lastUpdated",
            style: KhilonjiyaUI.sub.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "This policy applies to the Khilonjiya mobile application.",
            style: KhilonjiyaUI.body.copyWith(
              height: 1.35,
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
}