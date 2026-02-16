// File: lib/presentation/home_marketplace_feed/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  static const int price = 999;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  Razorpay? _razorpay;

  bool _loading = true;
  bool _paying = false;

  bool _isActive = false;

  // Prefill
  String _prefillEmail = "";
  String _prefillPhone = "";

  // Needed for verification after Razorpay returns
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _bootstrap();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    super.dispose();
  }

  // ============================================================
  // BOOTSTRAP
  // ============================================================
  Future<void> _bootstrap() async {
    await _loadPrefill();
    await _loadSubscription();
  }

  Future<void> _loadPrefill() async {
    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;

      if (user == null) return;

      _prefillEmail = (user.email ?? "").trim();

      // try from user_profiles
      final profile = await db
          .from('user_profiles')
          .select('mobile_number')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _prefillPhone = (profile['mobile_number'] ?? "").toString().trim();
      }
    } catch (_) {
      // ignore
    }
  }

  // ============================================================
  // INIT RAZORPAY
  // ============================================================
  void _initRazorpay() {
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  // ============================================================
  // LOAD SUBSCRIPTION STATUS
  // ============================================================
  Future<void> _loadSubscription() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final active = await _subscriptionService.isProActive();
      if (!mounted) return;

      setState(() {
        _isActive = active;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isActive = false;
        _loading = false;
      });
    }
  }

  // ============================================================
  // START PAYMENT FLOW
  // ============================================================
  Future<void> _startPayment() async {
    if (_paying) return;

    setState(() => _paying = true);

    try {
      // Reset old transaction id (important for retries)
      _transactionId = null;

      // 1) Create order from Supabase function
      final order = await _subscriptionService.createOrder(
        amountRupees: SubscriptionPage.price,
        planKey: "pro_monthly",
      );

      _transactionId = order['transaction_id']?.toString();
      final razorpayOrderId = order['order_id']?.toString();

      if (_transactionId == null || razorpayOrderId == null) {
        throw Exception("Order creation returned invalid response");
      }

      // 2) Open Razorpay checkout
      //
      // IMPORTANT:
      // - key is your Razorpay Key ID (NOT secret)
      // - for now keep dummy key, later replace with real key
      final options = {
        "key": "rzp_test_REPLACE_LATER",
        "amount": order['amount'], // in paise (99900)
        "currency": "INR",
        "name": "Khilonjiya Pro",
        "description": "Monthly subscription (30 days)",
        "order_id": razorpayOrderId,
        "prefill": {
          "contact": _prefillPhone,
          "email": _prefillEmail,
        },
        "method": {
          "upi": true,
          "card": true,
          "netbanking": true,
          "wallet": true,
        }
      };

      _razorpay!.open(options);
    } catch (e) {
      if (!mounted) return;

      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment start failed: $e")),
      );
    }
  }

  // ============================================================
  // RAZORPAY CALLBACKS
  // ============================================================
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final txId = _transactionId;
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;

      if (txId == null ||
          orderId == null ||
          paymentId == null ||
          signature == null) {
        throw Exception("Missing Razorpay payment response fields");
      }

      // 3) Verify payment using Supabase function
      await _subscriptionService.verifyPayment(
        transactionId: txId,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );

      if (!mounted) return;

      // 4) Reload subscription status
      await _loadSubscription();

      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription Activated")),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment verification failed: $e")),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;

    setState(() => _paying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Payment failed: ${response.message ?? "Cancelled"}",
        ),
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External wallet: ${response.walletName ?? ""}"),
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
            onPressed: _loading ? null : _loadSubscription,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _heroCard(),
                const SizedBox(height: 16),
                _featuresSection(),
                const SizedBox(height: 18),
                _faqSection(),
              ],
            ),
    );
  }

  Widget _heroCard() {
    final buttonText = _isActive ? "Renew Now" : "Subscribe Now";

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
              color: _isActive
                  ? Colors.green.withOpacity(0.10)
                  : KhilonjiyaUI.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isActive
                    ? Colors.green.withOpacity(0.25)
                    : KhilonjiyaUI.primary.withOpacity(0.12),
              ),
            ),
            child: Text(
              _isActive ? "SUBSCRIPTION ACTIVE" : "KHILONJIYA PRO",
              style: KhilonjiyaUI.sub.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _isActive ? Colors.green : KhilonjiyaUI.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _isActive ? "You are a Pro user" : "Get hired faster",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isActive
                ? "Your subscription is active for 30 days. You can renew anytime."
                : "Unlock premium job features designed to help you get more calls, more interviews, and better offers.",
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

          // CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isActive ? const Color(0xFF16A34A) : KhilonjiyaUI.primary,
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
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
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
              "No hidden charges • Manual renewal",
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

  Widget _featuresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          subtitle: "Apply to exclusive jobs available only to Pro users.",
        ),
      ],
    );
  }

  Widget _faqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              "Currently subscriptions are non-refundable. You can renew anytime after expiry.",
        ),
        _faqTile(
          title: "Will I definitely get a job?",
          answer:
              "No service can guarantee a job. Pro increases visibility and improves your chances.",
        ),
        _faqTile(
          title: "Can I cancel anytime?",
          answer:
              "Yes. Since this is manual renewal, your plan will simply expire after 30 days.",
        ),
      ],
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