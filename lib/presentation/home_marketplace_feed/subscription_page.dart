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
  bool _isExpired = false;

  DateTime? _expiresAt;
  int _daysLeft = 0;

  String _prefillEmail = "";
  String _prefillPhone = "";
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

      final profile = await db
          .from('user_profiles')
          .select('mobile_number')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _prefillPhone =
            (profile['mobile_number'] ?? "").toString().trim();
      }
    } catch (_) {}
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  Future<void> _loadSubscription() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final sub = await _subscriptionService.getMySubscription();

      if (sub == null) {
        setState(() {
          _isActive = false;
          _isExpired = false;
          _expiresAt = null;
          _daysLeft = 0;
          _loading = false;
        });
        return;
      }

      final status = (sub['status'] ?? '').toString();
      final expiresRaw = sub['expires_at'];

      final expires = expiresRaw == null
          ? null
          : DateTime.tryParse(expiresRaw.toString());

      final now = DateTime.now();

      final active = status == "active" &&
          expires != null &&
          expires.isAfter(now);

      final expired = status == "active" &&
          expires != null &&
          expires.isBefore(now);

      int daysLeft = 0;
      if (expires != null && expires.isAfter(now)) {
        daysLeft = expires.difference(now).inDays;
      }

      setState(() {
        _isActive = active;
        _isExpired = expired;
        _expiresAt = expires;
        _daysLeft = daysLeft;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _isActive = false;
        _isExpired = false;
        _expiresAt = null;
        _daysLeft = 0;
        _loading = false;
      });
    }
  }

  Future<void> _startPayment() async {
    if (_paying) return;
    setState(() => _paying = true);

    try {
      _transactionId = null;

      final order = await _subscriptionService.createOrder(
        amountRupees: SubscriptionPage.price,
        planKey: "pro_monthly",
      );

      _transactionId = order['transaction_id']?.toString();
      final razorpayOrderId = order['order_id']?.toString();

      if (_transactionId == null || razorpayOrderId == null) {
        throw Exception("Invalid order response");
      }

      final options = {
        "key": "rzp_test_SGkM8xnibeJDru",
        "amount": order['amount'],
        "currency": "INR",
        "name": "Khilonjiya Pro",
        "description": "Pro subscription (30 days)",
        "order_id": razorpayOrderId,
        "prefill": {
          "contact": _prefillPhone,
          "email": _prefillEmail,
        },
      };

      _razorpay!.open(options);
    } catch (e) {
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment start failed")),
      );
    }
  }

  Future<void> _onPaymentSuccess(
      PaymentSuccessResponse response) async {
    try {
      await _subscriptionService.verifyPayment(
        transactionId: _transactionId!,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      await _loadSubscription();
      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription Activated")),
      );
    } catch (_) {
      setState(() => _paying = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);
  }

  void _onExternalWallet(ExternalWalletResponse response) {}

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
        title: Text(
          "Subscription",
          style: KhilonjiyaUI.cardTitle,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _heroCard(),
                const SizedBox(height: 18),
                _featuresSection(),
              ],
            ),
    );
  }

  // ============================================================
  // HERO (Slim like Job Card)
  // ============================================================

  Widget _heroCard() {
    final buttonText = _isActive
        ? "Extend / Renew"
        : (_isExpired ? "Renew Now" : "Subscribe Now");

    final subtitle = _isActive
        ? "Active • $_daysLeft days left"
        : "Unlock premium features and increase visibility.";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Khilonjiya Pro",
            style: KhilonjiyaUI.cardTitle,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: KhilonjiyaUI.sub,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${SubscriptionPage.price}",
                style: KhilonjiyaUI.cardTitle.copyWith(
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 2),
                child: Text(
                  "/ 30 days",
                  style: KhilonjiyaUI.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    KhilonjiyaUI.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: _paying ? null : _startPayment,
              child: _paying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: KhilonjiyaUI.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURES (Slim Cards)
  // ============================================================

  Widget _featuresSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          "What you get",
          style: KhilonjiyaUI.cardTitle,
        ),
        const SizedBox(height: 10),
        _featureTile(
          Icons.bolt_rounded,
          "Priority applications",
          "Shown higher to employers.",
        ),
        _featureTile(
          Icons.verified_rounded,
          "Verified job access",
          "Access premium listings.",
        ),
        _featureTile(
          Icons.lock_open_rounded,
          "Unlock premium jobs",
          "Exclusive jobs for Pro users.",
        ),
      ],
    );
  }

  Widget _featureTile(
      IconData icon,
      String title,
      String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: KhilonjiyaUI.cardDecoration(),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: KhilonjiyaUI.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}