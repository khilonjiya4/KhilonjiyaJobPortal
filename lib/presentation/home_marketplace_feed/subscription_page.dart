// File: lib/presentation/home_marketplace_feed/subscription_page.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  static const int price = 999;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  Razorpay? _razorpay;

  bool _loading = true;
  bool _isProActive = false;

  bool _paying = false;

  // For verifying after payment
  String? _lastOrderId;

  @override
  void initState() {
    super.initState();
    _setupRazorpay();
    _loadSubscriptionStatus();
  }

  void _setupRazorpay() {
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _loading = true;
    });

    try {
      final active = await _service.isProActive();
      if (!mounted) return;

      setState(() {
        _isProActive = active;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProActive = false;
        _loading = false;
      });
    }
  }

  Future<void> _startPayment() async {
    if (_paying) return;

    setState(() {
      _paying = true;
    });

    try {
      // 1) Create order from Edge Function
      final order = await _service.createProOrder(
        amountRupees: SubscriptionPage.price,
        planKey: 'pro_monthly',
      );

      final orderId = (order['order_id'] ?? '').toString().trim();
      final keyId = (order['key_id'] ?? '').toString().trim();

      if (orderId.isEmpty || keyId.isEmpty) {
        throw Exception("Invalid order response");
      }

      _lastOrderId = orderId;

      // 2) Open Razorpay checkout
      final options = {
        'key': keyId,
        'amount': SubscriptionPage.price * 100, // in paise
        'currency': 'INR',
        'name': 'Khilonjiya Pro',
        'description': 'Pro Subscription (30 days)',
        'order_id': orderId,
        'timeout': 180,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#FF6A00',
        },
        'retry': {'enabled': true, 'max_count': 1},
      };

      _razorpay!.open(options);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: $e"),
        ),
      );

      setState(() {
        _paying = false;
      });
    }
  }

  // ============================================================
  // RAZORPAY CALLBACKS
  // ============================================================

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final orderId = response.orderId?.trim() ?? _lastOrderId ?? '';
      final paymentId = response.paymentId?.trim() ?? '';
      final signature = response.signature?.trim() ?? '';

      if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
        throw Exception("Payment success but missing details");
      }

      // 3) Verify payment on server
      final ok = await _service.verifyProPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
        amountRupees: SubscriptionPage.price,
        planKey: 'pro_monthly',
      );

      if (!mounted) return;

      if (!ok) {
        throw Exception("Payment verification failed");
      }

      // 4) Refresh subscription status
      await _loadSubscriptionStatus();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subscription Activated"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment verification failed: $e"),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _paying = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() {
      _paying = false;
    });

    final msg = response.message?.toString().trim();
    final code = response.code?.toString().trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg == null || msg.isEmpty
              ? "Payment failed (code: $code)"
              : "Payment failed: $msg",
        ),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "External wallet selected: ${response.walletName ?? ''}",
        ),
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

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
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadSubscriptionStatus,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _isProActive ? _activeCard() : _heroCard(),

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
                  subtitle:
                      "Get access to premium and verified employer listings.",
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
                      "Yes. You can cancel anytime by contacting support. (Manual renewal system)",
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // HERO CARD (INACTIVE)
  // ------------------------------------------------------------
  Widget _heroCard() {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                "₹${SubscriptionPage.price}",
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "/ 30 days",
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
              onPressed: _paying ? null : _startPayment,
              child: _paying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
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
              "Manual renewal • No hidden charges",
              style: KhilonjiyaUI.sub.copyWith(
                fontSize: 12.2,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTIVE CARD (PRO)
  // ------------------------------------------------------------
  Widget _activeCard() {
    return Container(
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.green.withOpacity(0.20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  "SUBSCRIPTION ACTIVE",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "You are a Pro user",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your premium subscription is active. Enjoy priority visibility and premium jobs.",
            style: KhilonjiyaUI.sub.copyWith(
              fontSize: 13.2,
              height: 1.35,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: KhilonjiyaUI.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _loadSubscriptionStatus,
              child: const Text(
                "Refresh Status",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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