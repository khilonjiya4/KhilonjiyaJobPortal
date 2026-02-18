// File: lib/presentation/home_marketplace_feed/legal/terms_and_conditions_page.dart

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "18 Feb 2026";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Terms & Conditions"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),

          _card(
            title: "1. Company and service",
            body: """
${AppLinks.companyName} (“we”, “our”, “us”) operates the Khilonjiya mobile application (“App”).

The App is a marketplace platform that connects job seekers and employers. We do not act as an employer, recruiter, or staffing agency unless explicitly stated.
""",
          ),

          _card(
            title: "2. Acceptance of these Terms",
            body: """
By creating an account, accessing, or using the App, you agree to these Terms & Conditions.

If you do not agree, do not use the App.
""",
          ),

          _card(
            title: "3. Eligibility",
            body: """
You must be at least 18 years old to use this App.

You agree that all information you provide is accurate, complete, and up to date.
""",
          ),

          _card(
            title: "4. Account and security",
            body: """
You are responsible for:
• Keeping your login credentials secure
• All activity performed under your account
• Updating your profile information when it changes

We may suspend or terminate accounts that are compromised, fraudulent, or violate these Terms.
""",
          ),

          _card(
            title: "5. User responsibilities (Job seekers)",
            body: """
You agree NOT to:
• Create fake profiles or impersonate any person or organization
• Upload false or misleading resumes, certificates, or details
• Spam employers or misuse employer contact details
• Upload illegal, abusive, hateful, or sexually explicit content
• Attempt to bypass platform security or scrape data

You agree that employers may view your profile/application details when you apply.
""",
          ),

          _card(
            title: "6. Employer responsibilities",
            body: """
Employers agree NOT to:
• Post fake jobs, scams, or misleading job listings
• Misrepresent salary, job type, or location
• Collect user data for illegal purposes
• Discriminate unlawfully based on protected characteristics
• Request money from job seekers for recruitment

Employers are solely responsible for their job listings and hiring decisions.
""",
          ),

          _card(
            title: "7. Prohibited content and behavior",
            body: """
The following are strictly prohibited:
• Fraud, scams, or pyramid schemes
• Content promoting violence or illegal activity
• Harassment, threats, or hate speech
• Sexual exploitation content
• Uploading malware or harmful files
• Any activity that violates Indian law or applicable regulations
""",
          ),

          _card(
            title: "8. Job listings and applications disclaimer",
            body: """
We do not guarantee:
• Employment
• Interview calls
• Job accuracy
• Employer authenticity in every case

We provide a platform. You must perform your own verification before sharing sensitive information or accepting an offer.
""",
          ),

          _card(
            title: "9. Payments, subscriptions and billing",
            body: """
Some features may require payment (for example, subscriptions).

Important:
• Prices, duration, and benefits are shown inside the App before purchase
• Subscription charges are processed through the payment method shown in the App
• Refund and cancellation rules are described in the Refund & Cancellation Policy page

If Google Play Billing is used, Google’s billing terms also apply.
""",
          ),

          _card(
            title: "10. Refunds and cancellations",
            body: """
Refund rules are defined in:
Settings → Refund & Cancellation Policy.

If there is a conflict between this page and the Refund Policy page, the Refund Policy page will apply for payment-related matters.
""",
          ),

          _card(
            title: "11. Intellectual property",
            body: """
The App, design, branding, logos, UI, and content created by us are owned by ${AppLinks.companyName}.

You may not copy, modify, reverse engineer, or distribute the App or its content without permission.
""",
          ),

          _card(
            title: "12. Suspension and termination",
            body: """
We may suspend or terminate your account if:
• You violate these Terms
• You misuse the platform
• You engage in fraud or spam
• You upload prohibited content

We may also remove job listings or user content that violates policies.
""",
          ),

          _card(
            title: "13. Limitation of liability",
            body: """
To the maximum extent permitted by law:
• We are not responsible for job outcomes, hiring decisions, or employer conduct
• We are not responsible for losses caused by third-party links or communications
• We are not responsible for indirect or consequential damages

Your use of the App is at your own risk.
""",
          ),

          _card(
            title: "14. Changes to the App and Terms",
            body: """
We may update the App and these Terms from time to time.

We will update the “Last updated” date at the top of this page. Continued use means you accept the updated Terms.
""",
          ),

          _card(
            title: "15. Governing law",
            body: """
These Terms are governed by the laws of India.

Any disputes will be subject to the jurisdiction of courts in India, as applicable.
""",
          ),

          _card(
            title: "16. Contact",
            body: """
For questions or support:
• In the App: Settings → Contact & Support
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
            "Terms & Conditions",
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
            "These Terms apply to your use of the Khilonjiya mobile application.",
            style: KhilonjiyaUI.body.copyWith(height: 1.35),
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