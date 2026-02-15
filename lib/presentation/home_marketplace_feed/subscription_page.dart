import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  static const int price = 999;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: KhilonjiyaUI.text,
        title: const Text(
          "Subscription",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ------------------------------------------------------------
          // HERO CARD
          // ------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: KhilonjiyaUI.r16,
              border: Border.all(color: KhilonjiyaUI.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: KhilonjiyaUI.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: KhilonjiyaUI.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    "KHILONJIYA PRO",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: KhilonjiyaUI.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  "Get hired faster",
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Unlock premium job features designed to help you get more calls, more interviews, and better offers.",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 13.2,
                    height: 1.35,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                // Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹$price",
                      style: KhilonjiyaUI.h1.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "/ month",
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhilonjiyaUI.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Payment integration coming soon"),
                        ),
                      );
                    },
                    child: const Text(
                      "Subscribe Now",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    "Cancel anytime • No hidden charges",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.2,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------------
          // FEATURES
          // ------------------------------------------------------------
          Text(
            "What you get",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          _featureCard(
            icon: Icons.bolt_rounded,
            title: "Priority applications",
            subtitle:
                "Your profile is shown higher to employers for faster callbacks.",
          ),
          _featureCard(
            icon: Icons.verified_rounded,
            title: "Verified job access",
            subtitle: "Get access to premium and verified employer listings.",
          ),
          _featureCard(
            icon: Icons.support_agent_rounded,
            title: "Job support assistance",
            subtitle:
                "Get help in finding suitable jobs based on your profile and skills.",
          ),
          _featureCard(
            icon: Icons.lock_open_rounded,
            title: "Unlock premium jobs",
            subtitle:
                "Apply to exclusive jobs that are available only to Pro users.",
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------------
          // FAQ
          // ------------------------------------------------------------
          Text(
            "FAQs",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),

          _faqTile(
            title: "Is this subscription refundable?",
            answer:
                "Currently subscriptions are non-refundable. You can cancel anytime and your plan will remain active till the end of the billing cycle.",
          ),
          _faqTile(
            title: "Will I definitely get a job?",
            answer:
                "No service can guarantee a job. Pro increases visibility and improves your chances of getting more calls from employers.",
          ),
          _faqTile(
            title: "Can I cancel anytime?",
            answer:
                "Yes. You can cancel anytime from your Google Play subscription settings.",
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  static Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: KhilonjiyaUI.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: KhilonjiyaUI.primary.withOpacity(0.12),
              ),
            ),
            child: Icon(
              icon,
              color: KhilonjiyaUI.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KhilonjiyaUI.body.copyWith(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.6,
                    height: 1.35,
                    color: const Color(0xFF64748B),
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

  static Widget _faqTile({
    required String title,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          title,
          style: KhilonjiyaUI.body.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 13.8,
          ),
        ),
        children: [
          Text(
            answer,
            style: KhilonjiyaUI.sub.copyWith(
              fontSize: 12.8,
              height: 1.4,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}