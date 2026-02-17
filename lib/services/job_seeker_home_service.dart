import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobSeekerHomeService {
  final SupabaseClient _db = Supabase.instance.client;

  // ============================================================
  // AUTH GUARD
  // ============================================================

  void _ensureAuthenticatedSync() {
    final user = _db.auth.currentUser;
    final session = _db.auth.currentSession;

    if (user == null || session == null) {
      throw Exception('Authentication required. Please login again.');
    }
  }

  String _userId() {
    _ensureAuthenticatedSync();
    return _db.auth.currentUser!.id;
  }

  // ============================================================
  // COMMON SELECT (Job + Company + Business Type)
  // ============================================================

  String get _jobWithCompanySelect => '''
    *,
    companies (
      id,
      name,
      slug,
      logo_url,
      industry,
      is_verified,
      rating,
      total_reviews,
      company_size,
      description,
      website,

      business_type_id,
      business_types_master (
        id,
        type_name,
        logo_url
      )
    )
  ''';

  // ============================================================
  // LOCATION HELPERS (Assam nearby logic)
  // ============================================================

  Future<bool> isUserInAssam() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    try {
      final p = await _db
          .from('user_profiles')
          .select('current_state, current_city, location')
          .eq('id', userId)
          .maybeSingle();

      if (p == null) return false;

      final state = (p['current_state'] ?? '').toString().trim().toLowerCase();
      final city = (p['current_city'] ?? '').toString().trim().toLowerCase();
      final loc = (p['location'] ?? '').toString().trim().toLowerCase();

      if (state == 'assam') return true;
      if (city.contains('assam')) return true;
      if (loc.contains('assam')) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, double>?> getMyCurrentLatLngFromProfile() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    try {
      final p = await _db
          .from('user_profiles')
          .select('current_latitude, current_longitude')
          .eq('id', userId)
          .maybeSingle();

      if (p == null) return null;

      double? toDouble(dynamic v) {
        if (v == null) return null;
        if (v is double) return v;
        if (v is int) return v.toDouble();
        return double.tryParse(v.toString());
      }

      final lat = toDouble(p['current_latitude']);
      final lng = toDouble(p['current_longitude']);

      if (lat == null || lng == null) return null;
      return {'lat': lat, 'lng': lng};
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssamDistrictMaster() async {
    final res = await _db
        .from('assam_districts_master')
        .select('district_name, latitude, longitude')
        .order('district_name', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  Future<List<String>> getAssamDistrictsByDistance({
    required double userLat,
    required double userLng,
  }) async {
    try {
      final districts = await fetchAssamDistrictMaster();
      if (districts.isEmpty) return [];

      final scored = <Map<String, dynamic>>[];

      for (final d in districts) {
        final name = (d['district_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        final lat = double.tryParse(d['latitude'].toString());
        final lng = double.tryParse(d['longitude'].toString());
        if (lat == null || lng == null) continue;

        final dist = _haversineKm(userLat, userLng, lat, lng);

        scored.add({'name': name, 'dist': dist});
      }

      scored.sort((a, b) {
        final da = (a['dist'] as double);
        final db = (b['dist'] as double);
        return da.compareTo(db);
      });

      return scored.map((e) => e['name'].toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // JOB FEED (BASE) - PAGINATED
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // LATEST JOBS (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchLatestJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    return fetchJobs(offset: offset, limit: limit);
  }

  // ============================================================
  // JOBS POSTED TODAY (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsPostedToday({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String())
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // JOBS NEARBY (PAGINATED + Assam logic)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsNearby({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final inAssam = await isUserInAssam();
    if (!inAssam) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final gps = await getMyCurrentLatLngFromProfile();
    if (gps == null) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final userLat = gps['lat']!;
    final userLng = gps['lng']!;

    final districtsOrdered = await getAssamDistrictsByDistance(
      userLat: userLat,
      userLng: userLng,
    );

    if (districtsOrdered.isEmpty) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }

    final nowIso = DateTime.now().toIso8601String();

    // fetch large set, then sort + slice in Dart
    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .inFilter('district', districtsOrdered)
        .order('created_at', ascending: false)
        .limit(800);

    final all = List<Map<String, dynamic>>.from(res);

    final districtRank = <String, int>{};
    for (int i = 0; i < districtsOrdered.length; i++) {
      districtRank[districtsOrdered[i].toLowerCase()] = i;
    }

    all.sort((a, b) {
      final da = (a['district'] ?? '').toString().trim().toLowerCase();
      final db = (b['district'] ?? '').toString().trim().toLowerCase();

      final ra = districtRank[da] ?? 9999;
      final rb = districtRank[db] ?? 9999;

      if (ra != rb) return ra.compareTo(rb);

      final ca = DateTime.tryParse((a['created_at'] ?? '').toString());
      final cb = DateTime.tryParse((b['created_at'] ?? '').toString());

      if (ca == null && cb == null) return 0;
      if (ca == null) return 1;
      if (cb == null) return -1;

      return cb.compareTo(ca);
    });

    if (offset >= all.length) return [];
    final end = (offset + limit) > all.length ? all.length : (offset + limit);

    return all.sublist(offset, end);
  }

  // ============================================================
  // PREMIUM JOBS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchPremiumJobs({
    int limit = 5,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .eq('is_premium', true)
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // COMPANY JOBS (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCompanyJobs({
    required String companyId,
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .eq('company_id', companyId)
        .gte('expires_at', nowIso)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // RECOMMENDED JOBS (PAGINATED) - FIXED
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();
    final userId = _userId();

    try {
      final rec = await _db
          .from('job_recommendations')
          .select('job_id, match_score')
          .eq('user_id', userId)
          .order('match_score', ascending: false)
          .range(offset, offset + limit - 1);

      final recList = List<Map<String, dynamic>>.from(rec);

      if (recList.isEmpty) {
        return fetchLatestJobs(offset: offset, limit: limit);
      }

      final ids = recList.map((e) => e['job_id'].toString()).toList();

      // IMPORTANT: do NOT limit here, fetch all ids
      final jobs = await _db
          .from('job_listings')
          .select(_jobWithCompanySelect)
          .inFilter('id', ids)
          .eq('status', 'active')
          .gte('expires_at', nowIso);

      final list = List<Map<String, dynamic>>.from(jobs);

      // map score
      final scoreMap = <String, int>{};
      for (final r in recList) {
        final id = r['job_id'].toString();
        final ms = r['match_score'];
        final v = (ms is int) ? ms : int.tryParse(ms.toString()) ?? 0;
        scoreMap[id] = v;
      }

      for (final j in list) {
        final id = j['id'].toString();
        j['match_score'] = scoreMap[id] ?? 0;
      }

      // sort by match_score desc
      list.sort((a, b) {
        final sa = (a['match_score'] ?? 0) as int;
        final sb = (b['match_score'] ?? 0) as int;
        return sb.compareTo(sa);
      });

      return list;
    } catch (_) {
      return fetchLatestJobs(offset: offset, limit: limit);
    }
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int offset = 0,
    int limit = 20,
  }) async {
    return getRecommendedJobs(offset: offset, limit: limit);
  }

  // ============================================================
  // JOBS FILTERED BY SALARY (MONTHLY) - PAGINATED
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsByMinSalaryMonthly({
    required int minMonthlySalary,
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();
    final minSalary = minMonthlySalary < 0 ? 0 : minMonthlySalary;

    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .or(
          'salary_period.is.null,salary_period.eq.Monthly,salary_period.eq.monthly',
        )
        .gte('salary_max', minSalary)
        .order('salary_max', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // SAVED JOBS (PAGINATED)
  // ============================================================

  Future<Set<String>> getUserSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res =
        await _db.from('saved_jobs').select('job_id').eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('saved_jobs')
        .select(
          'saved_at, job_listings($_jobWithCompanySelect)',
        )
        .eq('user_id', userId)
        .order('saved_at', ascending: false)
        .range(offset, offset + limit - 1);

    return res.map<Map<String, dynamic>>((e) {
      final j = e['job_listings'];
      if (j is Map<String, dynamic>) return j;
      return Map<String, dynamic>.from(j);
    }).toList();
  }

  Future<bool> toggleSaveJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final existing = await _db
        .from('saved_jobs')
        .select('id')
        .eq('user_id', userId)
        .eq('job_id', jobId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('saved_jobs')
          .delete()
          .eq('user_id', userId)
          .eq('job_id', jobId);

      return false;
    }

    await _db.from('saved_jobs').insert({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': DateTime.now().toIso8601String(),
    });

    try {
      await _db.from('user_job_activity').insert({
        'user_id': userId,
        'job_id': jobId,
        'activity_type': 'saved',
        'activity_date': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return true;
  }

  // ============================================================
  // APPLIED JOBS (PAGINATED)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAppliedJobs({
    int offset = 0,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();
    final nowIso = DateTime.now().toIso8601String();

    final res = await _db
        .from('job_applications_listings')
        .select('''
          applied_at,
          application_status,
          listing_id,
          job_listings($_jobWithCompanySelect)
        ''')
        .eq('user_id', userId)
        .order('applied_at', ascending: false)
        .range(offset, offset + limit - 1);

    final rows = List<Map<String, dynamic>>.from(res);

    final jobs = <Map<String, dynamic>>[];

    for (final r in rows) {
      final j = r['job_listings'];
      if (j == null) continue;

      final job = Map<String, dynamic>.from(j);

      job['applied_at'] = r['applied_at'];
      job['application_status'] = r['application_status'];

      final status = (job['status'] ?? '').toString();
      final expiresAt = (job['expires_at'] ?? '').toString();

      if (status != 'active') continue;
      if (expiresAt.isNotEmpty && expiresAt.compareTo(nowIso) < 0) continue;

      jobs.add(job);
    }

    return jobs;
  }

  // ============================================================
  // JOB DETAILS HELPERS
  // ============================================================

  Future<void> trackJobView(String jobId) async {
    try {
      final userId = _db.auth.currentUser?.id;
      if (userId == null) return;

      await _db.from('job_views').insert({
        'user_id': userId,
        'job_id': jobId,
        'viewed_at': DateTime.now().toIso8601String(),
        'device_type': 'mobile',
      });

      try {
        await _db.from('user_job_activity').insert({
          'user_id': userId,
          'job_id': jobId,
          'activity_type': 'viewed',
          'activity_date': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('trackJobView error: $e');
    }
  }

  // ============================================================
  // TOP COMPANIES
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchTopCompanies({
    int limit = 8,
  }) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('companies_with_stats')
        .select(
          'id, name, slug, logo_url, industry, company_size, is_verified, total_jobs',
        )
        .order('total_jobs', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<int> getUnreadNotificationsCount() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (res as List).length;
  }

  // ============================================================
  // SUBSCRIPTION (PRO)
  // ============================================================

  Future<Map<String, dynamic>?> getMySubscription() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final res = await _db
        .from('subscriptions')
        .select('id, user_id, status, plan_price, starts_at, expires_at')
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  Future<bool> isProActive() async {
    final sub = await getMySubscription();
    if (sub == null) return false;

    final status = (sub['status'] ?? 'inactive').toString();
    if (status != 'active') return false;

    final expiresAtRaw = sub['expires_at']?.toString();
    if (expiresAtRaw == null || expiresAtRaw.trim().isEmpty) return false;

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return false;

    return expiresAt.isAfter(DateTime.now());
  }

  Future<Map<String, dynamic>> createProOrder({
    int amountRupees = 999,
    String planKey = 'pro_monthly',
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final payload = {
      'user_id': userId,
      'amount_rupees': amountRupees,
      'plan_key': planKey,
    };

    final res =
        await _db.functions.invoke('create_razorpay_order', body: payload);

    if (res.status != 200) {
      throw Exception(
        'create_razorpay_order failed: ${res.status} ${res.data}',
      );
    }

    final data = res.data;
    if (data == null || data is! Map) {
      throw Exception('Invalid create_razorpay_order response');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<bool> verifyProPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    int amountRupees = 999,
    String planKey = 'pro_monthly',
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final payload = {
      'user_id': userId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
      'amount_rupees': amountRupees,
      'plan_key': planKey,
    };

    final res =
        await _db.functions.invoke('verify_razorpay_payment', body: payload);

    if (res.status != 200) {
      throw Exception(
        'verify_razorpay_payment failed: ${res.status} ${res.data}',
      );
    }

    final data = res.data;
    if (data == null || data is! Map) return false;

    return (data['success'] ?? false) == true;
  }

  Future<bool> refreshProStatus() async {
    return isProActive();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void tellDebug(String msg) {
    if (kDebugMode) debugPrint(msg);
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String _firstNameOrFallback(String fullName) {
    if (fullName.trim().isEmpty) return "Your Profile";
    final parts = fullName.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return "Your Profile";
    return "${parts.first}'s profile";
  }

  String _formatLastUpdated(String? iso) {
    if (iso == null || iso.trim().isEmpty) return "Updated recently";

    final d = DateTime.tryParse(iso);
    if (d == null) return "Updated recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "Updated just now";
    if (diff.inHours < 24) return "Updated today";
    if (diff.inDays == 1) return "Updated 1d ago";
    if (diff.inDays < 7) return "Updated ${diff.inDays}d ago";
    if (diff.inDays < 30) return "Updated ${(diff.inDays / 7).floor()}w ago";

    return "Updated ${(diff.inDays / 30).floor()}mo ago";
  }
}