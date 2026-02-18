import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Refund Policy"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            title: "Refund policy",
            body: """
This policy applies to payments made to ${AppLinks.companyName} through the app.

If subscriptions are enabled:
• Subscription benefits are delivered instantly.
• Refunds are generally not provided once a subscription is activated.
""",
          ),
          _card(
            title: "Refund exceptions",
            body: """
Refunds may be considered only if:
• Payment was successful but subscription was not activated due to a technical issue.
• Duplicate payment occurred.
""",
          ),
          _card(
            title: "How to request a refund",
            body: """
Go to Settings → Contact & Support and share:
• Payment ID
• Order ID
• Registered phone/email
""",
          ),
          _card(
            title: "Processing time",
            body:
                "If approved, refunds are processed within 7–10 working days depending on your bank/payment method.",
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