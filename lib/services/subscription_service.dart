// File: lib/services/subscription_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final SupabaseClient _db = Supabase.instance.client;

  void _ensureAuth() {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception("Login required");
    }
  }

  String _uid() {
    _ensureAuth();
    return _db.auth.currentUser!.id;
  }

  // ============================================================
  // SUBSCRIPTION STATUS
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {
    _ensureAuth();

    final uid = _uid();

    final res = await _db
        .from('subscriptions')
        .select('id, user_id, status, plan_price, starts_at, expires_at')
        .eq('user_id', uid)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<bool> isProActive() async {
    final sub = await getMySubscription();
    if (sub == null) return false;

    final status = (sub['status'] ?? '').toString();
    if (status != 'active') return false;

    final expiresAtRaw = sub['expires_at'];
    if (expiresAtRaw == null) return false;

    final expiresAt = DateTime.tryParse(expiresAtRaw.toString());
    if (expiresAt == null) return false;

    return expiresAt.isAfter(DateTime.now());
  }

  // ============================================================
  // RAZORPAY - CREATE ORDER
  // ============================================================

  /// Returns:
  /// {
  ///   order_id: "order_xxx",
  ///   amount: 99900,
  ///   currency: "INR",
  ///   plan_key: "pro_monthly",
  ///   transaction_id: "uuid"
  /// }
  Future<Map<String, dynamic>> createOrder({
    int amountRupees = 999,
    String planKey = "pro_monthly",
  }) async {
    _ensureAuth();

    final uid = _uid();

    final res = await _db.functions.invoke(
      'razorpay_create_order',
      body: {
        "user_id": uid,
        "plan_key": planKey,
        "amount_rupees": amountRupees,
      },
    );

    if (res.data == null) {
      throw Exception("Create order failed");
    }

    return Map<String, dynamic>.from(res.data as Map);
  }

  // ============================================================
  // RAZORPAY - VERIFY PAYMENT
  // ============================================================

  /// This will:
  /// - verify signature in Edge Function
  /// - mark payment success in DB
  /// - activate subscription (30 days)
  Future<void> verifyPayment({
    required String transactionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    _ensureAuth();

    final uid = _uid();

    final res = await _db.functions.invoke(
      // ✅ Your actual function name
      'verify-razorpay-payment',
      body: {
        // ✅ REQUIRED by your function
        "user_id": uid,

        // still send transaction_id (useful for tracking later)
        "transaction_id": transactionId,

        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      },
    );

    if (res.data == null) {
      throw Exception("Payment verification failed");
    }

    final data = Map<String, dynamic>.from(res.data as Map);

    final ok = (data['success'] == true);
    if (!ok) {
      throw Exception(data['message'] ?? "Payment verification failed");
    }
  }
}