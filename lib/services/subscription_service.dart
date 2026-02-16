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
  // ✅ VERIFY PAYMENT (OPTION B)
  // ============================================================

  Future<void> verifyPayment({
    required String transactionId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    _ensureAuth();

    final uid = _uid();

    final res = await _db.functions.invoke(
      'verify-razorpay-payment', // ✅ OPTION B
      body: {
        "transaction_id": transactionId,
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
        "user_id": uid, // ✅ REQUIRED by your edge function
      },
    );

    if (res.data == null) {
      throw Exception("Payment verification failed");
    }

    final data = Map<String, dynamic>.from(res.data as Map);

    final ok = (data['success'] == true);
    if (!ok) {
      throw Exception(data['error'] ?? "Payment verification failed");
    }
  }
}