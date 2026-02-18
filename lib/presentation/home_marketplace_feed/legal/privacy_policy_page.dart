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
• Email address (optional)
• Date of birth (if you enter)
• Gender (if you enter)
• Address, district, state (if you enter)
• Education, skills, experience, job preferences
• Expected salary (if you enter)

B) Uploaded Files
• Resume (PDF/DOC/DOCX etc.)
• Profile photo (optional)

C) Job Activity Data
• Jobs viewed, saved, applied, shared
• Application details and status history (if applicable)

D) Location Data (Optional)
• City / District / State you enter
• Current latitude/longitude only if you allow location permission (used for “Nearby jobs”)

E) Device & Technical Data
• App usage events
• Crash logs (if enabled by platform)
• Basic device information (for security and fraud prevention)
""",
          ),

          _card(
            title: "3. Why we collect your data (Purpose)",
            body: """
We use your information to:
• Create and manage your account
• Verify login and prevent misuse
• Show relevant job listings based on your profile and preferences
• Enable job applications and allow employers to review applications
• Provide customer support
• Improve app performance, safety, and reliability
• Prevent spam, fraud, and illegal activity
""",
          ),

          _card(
            title: "4. How employers see your information",
            body: """
When you apply for a job, the employer may receive and view your application information, including:
• Your name and contact details
• Your education, skills, and experience
• Your resume file (if uploaded)
• Your profile photo (if uploaded)
• Any additional details you submit during application

Important:
Employers are independent parties. They are responsible for how they store, use, or process applicant information after receiving it.
""",
          ),

          _card(
            title: "5. Payments and subscriptions (if enabled)",
            body: """
If the App offers paid subscriptions or paid services, payments may be processed through:
• Google Play Billing (Android)

We do not store your full card/bank details inside our database.

For transaction verification and subscription access, we may store limited payment metadata such as:
• Order ID / Transaction ID
• Purchase time
• Subscription plan identifier
• Subscription status (active/expired)

Refund rules are described in the Refund Policy section of the app.
""",
          ),

          _card(
            title: "6. Push notifications (if enabled)",
            body: """
If you allow notifications, we may send:
• Job alerts
• Application updates
• Important service messages

You can disable notifications anytime from your phone settings or from in-app settings (when available).
""",
          ),

          _card(
            title: "7. Storage & security",
            body: """
Your data is stored using Supabase (database + file storage).

We apply security controls such as:
• Authentication (login required)
• Row-Level Security (RLS) policies
• Access restrictions for files stored in buckets
• Role-based permissions for job seeker and employer data

However, no system can be guaranteed 100% secure. You should protect your account credentials and device.
""",
          ),

          _card(
            title: "8. Sharing of data",
            body: """
We do not sell your personal data.

We may share information only in the following cases:
• With employers when you apply for a job
• With service providers (e.g., Supabase) strictly to operate the App
• With Google Play / platform services for subscription verification
• When required by law, regulation, or valid legal process
• To protect the rights, safety, and security of users and the platform
""",
          ),

          _card(
            title: "9. Data retention",
            body: """
We retain your information as long as:
• Your account is active, or
• It is needed to provide services, resolve disputes, enforce policies, or comply with legal requirements.

You may request deletion of your account and associated data.

Some information may be retained if legally required (for example, payment and transaction records).
""",
          ),

          _card(
            title: "10. Your rights and choices",
            body: """
You can:
• View and edit your profile information anytime
• Replace your resume and profile photo anytime
• Choose what optional information to provide (e.g., location, gender, salary)
• Request account deletion via Support

To request deletion:
Go to Settings → Contact & Support and submit a deletion request.
""",
          ),

          _card(
            title: "11. Children’s privacy",
            body: """
This App is not intended for children under 18.

If you believe a child has provided personal data, contact Support and we will take appropriate action.
""",
          ),

          _card(
            title: "12. Third-party links",
            body: """
The App may contain links to third-party websites or services (for example, employer websites or external apply links).

We are not responsible for third-party privacy practices. Please review their policies before sharing information.
""",
          ),

          _card(
            title: "13. Updates to this Privacy Policy",
            body: """
We may update this Privacy Policy from time to time.

We will update the “Last updated” date at the top of this page. Continued use of the App means you accept the updated policy.
""",
          ),

          _card(
            title: "14. Contact",
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