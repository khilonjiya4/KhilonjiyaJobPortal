import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

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
          _card(
            title: "Company",
            body:
                "${AppLinks.companyName} provides this job marketplace application.",
          ),
          _card(
            title: "Eligibility",
            body:
                "You must provide correct information. Fake profiles and fake job postings are not allowed.",
          ),
          _card(
            title: "User responsibilities",
            body: """
You agree:
• Not to upload illegal or harmful content
• Not to impersonate others
• Not to misuse employer contact details
• Not to spam employers or job seekers
""",
          ),
          _card(
            title: "Employer responsibilities",
            body: """
Employers agree:
• Jobs must be genuine
• No misleading salary or location
• No illegal hiring or discrimination
""",
          ),
          _card(
            title: "Account suspension",
            body:
                "We may suspend accounts involved in fraud, abuse, spam, or policy violations.",
          ),
          _card(
            title: "Payments (if applicable)",
            body:
                "Subscriptions (if enabled) will be billed as shown in the app. Refund rules are listed in the Refund Policy page.",
          ),
          _card(
            title: "Disclaimer",
            body:
                "We do not guarantee employment. We only provide a platform to connect job seekers and employers.",
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