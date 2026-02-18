// File: lib/presentation/home_marketplace_feed/legal/refund_policy_page.dart

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../core/ui/app_links.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "18 Feb 2026";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Refund & Cancellation"),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 12),

          _card(
            title: "1. Scope",
            body: """
This Refund & Cancellation Policy applies to payments made for paid features, subscriptions, or services inside the Khilonjiya mobile application operated by ${AppLinks.companyName}.

This policy applies only to payments made directly through the App.
""",
          ),

          _card(
            title: "2. Subscription activation and delivery",
            body: """
If you purchase a subscription:
• Subscription benefits are delivered digitally and usually activate immediately after successful payment.
• You will see your subscription status inside the App.

Because digital benefits are delivered instantly, refunds are limited (see Section 4).
""",
          ),

          _card(
            title: "3. Cancellation",
            body: """
You may cancel your subscription at any time.

Important:
• Cancellation stops future renewals.
• Cancellation does NOT automatically refund the current active billing period.
""",
          ),

          _card(
            title: "4. Refund eligibility",
            body: """
Refunds may be approved only in limited cases, such as:
• Payment succeeded but subscription was not activated due to a technical issue
• Duplicate payment occurred for the same subscription
• Incorrect amount charged due to a confirmed system error

Refunds are NOT provided for:
• Change of mind after subscription activation
• Non-usage of subscription benefits
• Partial period refunds after activation
• Network/device issues on the user side
""",
          ),

          _card(
            title: "5. Google Play Billing purchases (future)",
            body: """
If your subscription is purchased using Google Play Billing:
• Refunds, cancellations, and renewals are governed by Google Play policies.
• You may need to request refunds directly through Google Play.

In such cases, ${AppLinks.companyName} may not be able to override Google’s refund decision.
""",
          ),

          _card(
            title: "6. Razorpay / direct payment purchases",
            body: """
If your subscription is purchased using Razorpay (or another direct payment method inside the App):
• Refund decisions are handled by ${AppLinks.companyName}
• Approved refunds are returned to the original payment method whenever possible
""",
          ),

          _card(
            title: "7. How to request a refund",
            body: """
To request a refund, go to:
Settings → Contact & Support

Provide:
• Razorpay Payment ID / Order ID (if available)
• Registered phone number / email
• Date and time of transaction
• Screenshot of payment success (optional)
""",
          ),

          _card(
            title: "8. Processing time",
            body: """
If a refund is approved:
• We typically initiate the refund within 3–7 working days
• Banks/payment providers may take additional time to credit the amount

Total time may vary depending on your bank/payment method.
""",
          ),

          _card(
            title: "9. Contact",
            body: """
If you have questions about refunds or cancellations, contact:
• In-app: Settings → Contact & Support
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
            "Refund & Cancellation Policy",
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
            "This page explains how refunds and cancellations are handled for paid features.",
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