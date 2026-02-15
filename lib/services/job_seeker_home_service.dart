// File: lib/services/job_seeker_home_service.dart

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
  // COMMON SELECT (Job + Company)
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
      website
    )
  ''';

  // ============================================================
  // JOB FEED (BASE)
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
  // LATEST JOBS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchLatestJobs({
    int limit = 40,
  }) async {
    return fetchJobs(limit: limit);
  }

  // ============================================================
  // JOBS NEARBY (fallback)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsNearby({
    int limit = 40,
  }) async {
    return fetchJobs(limit: limit);
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
  // COMPANY JOBS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCompanyJobs({
    required String companyId,
    int limit = 50,
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
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // RECOMMENDED JOBS
  // ============================================================

  Future<List<Map<String, dynamic>>> getRecommendedJobs({
    int limit = 40,
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
          .limit(limit);

      final recList = List<Map<String, dynamic>>.from(rec);

      if (recList.isEmpty) {
        return fetchJobs(limit: limit);
      }

      final ids = recList.map((e) => e['job_id'].toString()).toList();

      final jobs = await _db
          .from('job_listings')
          .select(_jobWithCompanySelect)
          .inFilter('id', ids)
          .eq('status', 'active')
          .gte('expires_at', nowIso)
          .limit(limit);

      final list = List<Map<String, dynamic>>.from(jobs);

      // attach match_score
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

      // sort
      list.sort((a, b) {
        final sa = (a['match_score'] ?? 0) as int;
        final sb = (b['match_score'] ?? 0) as int;
        return sb.compareTo(sa);
      });

      return list;
    } catch (_) {
      return fetchJobs(limit: limit);
    }
  }

  Future<List<Map<String, dynamic>>> getJobsBasedOnActivity({
    int limit = 50,
  }) async {
    return getRecommendedJobs(limit: limit);
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

      // activity log (schema allows: viewed, applied, saved, shared)
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

  Future<List<Map<String, dynamic>>> fetchSimilarJobs({
    required String jobId,
    int limit = 12,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();

    try {
      final base = await _db
          .from('job_listings')
          .select('job_category_id, district, company_id')
          .eq('id', jobId)
          .maybeSingle();

      if (base == null) return [];

      final catId = base['job_category_id'];
      final district = base['district'];
      final companyId = base['company_id'];

      final res = await _db
          .from('job_listings')
          .select(_jobWithCompanySelect)
          .eq('status', 'active')
          .gte('expires_at', nowIso)
          .neq('id', jobId)
          .neq('company_id', companyId)
          .eq('job_category_id', catId)
          .eq('district', district)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchCompanyDetails(String companyId) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('companies')
        .select(
          'id, name, slug, logo_url, website, description, industry, company_size, founded_year, headquarters_city, headquarters_state, rating, total_reviews, total_jobs, is_verified',
        )
        .eq('id', companyId)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  // ============================================================
  // JOBS FILTERED BY SALARY (MONTHLY)
  // ============================================================
  // IMPORTANT FIX:
  // - do NOT hard-require salary_period == Monthly
  //   because many rows may have NULL or different casing
  // - still filter by salary_max >= minSalary
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchJobsByMinSalaryMonthly({
    required int minMonthlySalary,
    int limit = 80,
  }) async {
    _ensureAuthenticatedSync();

    final nowIso = DateTime.now().toIso8601String();
    final minSalary = minMonthlySalary < 0 ? 0 : minMonthlySalary;

    // Prefer monthly jobs, but allow null salary_period too.
    // Supabase OR syntax:
    // .or('salary_period.eq.Monthly,salary_period.is.null')
    final res = await _db
        .from('job_listings')
        .select(_jobWithCompanySelect)
        .eq('status', 'active')
        .gte('expires_at', nowIso)
        .or('salary_period.eq.Monthly,salary_period.is.null')
        .gte('salary_max', minSalary)
        .order('salary_max', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // SAVED JOBS
  // ============================================================

  Future<Set<String>> getUserSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res =
        await _db.from('saved_jobs').select('job_id').eq('user_id', userId);

    return res.map<String>((e) => e['job_id'].toString()).toSet();
  }

  Future<List<Map<String, dynamic>>> getSavedJobs() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('saved_jobs')
        .select(
          'job_listings($_jobWithCompanySelect)',
        )
        .eq('user_id', userId)
        .order('saved_at', ascending: false);

    // each row = { job_listings: {...} }
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

      // IMPORTANT:
      // Your schema does NOT allow "unsaved"
      // activity_type only: viewed, applied, saved, shared
      return false;
    }

    await _db.from('saved_jobs').insert({
      'user_id': userId,
      'job_id': jobId,
      'saved_at': DateTime.now().toIso8601String(),
    });

    // activity log: SAVED
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
  // APPLY STATUS
  // ============================================================

  Future<bool> hasAppliedToJob(String jobId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('user_id', userId)
        .eq('listing_id', jobId)
        .maybeSingle();

    return res != null;
  }

  // ============================================================
  // APPLIED JOBS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchAppliedJobs({
    int limit = 80,
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
        .limit(limit);

    final rows = List<Map<String, dynamic>>.from(res);

    final jobs = <Map<String, dynamic>>[];

    for (final r in rows) {
      final j = r['job_listings'];
      if (j == null) continue;

      final job = Map<String, dynamic>.from(j);

      // Attach application info for UI
      job['applied_at'] = r['applied_at'];
      job['application_status'] = r['application_status'];

      // Only show valid jobs
      final status = (job['status'] ?? '').toString();
      final expiresAt = (job['expires_at'] ?? '').toString();

      if (status != 'active') continue;
      if (expiresAt.isNotEmpty && expiresAt.compareTo(nowIso) < 0) continue;

      jobs.add(job);
    }

    return jobs;
  }

  // ============================================================
  // HOME SUMMARY
  // ============================================================

  Future<Map<String, dynamic>> getHomeProfileSummary() async {
    final user = _db.auth.currentUser;

    if (user == null) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }

    try {
      final profile = await _db
          .from('user_profiles')
          .select(
            'full_name, profile_completion_percentage, last_profile_update',
          )
          .eq('id', user.id)
          .maybeSingle();

      String profileName = "Your Profile";
      int completion = 0;
      String lastUpdatedText = "Updated recently";

      if (profile != null) {
        final fullName = (profile['full_name'] ?? '').toString().trim();
        profileName = _firstNameOrFallback(fullName);

        completion =
            _toInt(profile['profile_completion_percentage']).clamp(0, 100);

        lastUpdatedText =
            _formatLastUpdated(profile['last_profile_update']?.toString());
      }

      return {
        "profileName": profileName,
        "profileCompletion": completion,
        "lastUpdatedText": lastUpdatedText,
        "missingDetails": completion >= 100 ? 0 : 1,
      };
    } catch (_) {
      return {
        "profileName": "Your Profile",
        "profileCompletion": 0,
        "lastUpdatedText": "Updated recently",
        "missingDetails": 0,
      };
    }
  }

  Future<int> getJobsPostedTodayCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final res = await _db
          .from('job_listings')
          .select('id')
          .eq('status', 'active')
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // EXPECTED SALARY (PER MONTH)
  // ============================================================

  Future<int> getExpectedSalaryPerMonth() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    try {
      tellDebug("Loading expected salary for user: $userId");

      final profile = await _db
          .from('user_profiles')
          .select('expected_salary_min')
          .eq('id', userId)
          .maybeSingle();

      if (profile == null) return 0;

      final raw = profile['expected_salary_min'];
      if (raw == null) return 0;

      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> updateExpectedSalaryPerMonth(int salary) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final clean = salary < 0 ? 0 : salary;
    final max = clean + 5000;

    await _db.from('user_profiles').update({
      'expected_salary_min': clean,
      'expected_salary_max': max,
      'last_profile_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ============================================================
  // PROFILE (EDIT PAGE)
  // ============================================================
  // IMPORTANT FIXES (schema aligned):
  // - phone -> mobile_number
  // - location_text -> location
  // - preferred_job_type -> preferred_job_types (array)
  // - preferred_employment_type does NOT exist -> ignore
  // ============================================================

  Future<Map<String, dynamic>> fetchMyProfile() async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final res = await _db
        .from('user_profiles')
        .select('''
          id,
          full_name,
          mobile_number,
          current_city,
          current_state,
          location,
          bio,
          skills,
          highest_education,
          total_experience_years,
          expected_salary_min,
          expected_salary_max,
          notice_period_days,
          preferred_job_types,
          preferred_locations,
          profile_completion_percentage,
          last_profile_update
        ''')
        .eq('id', userId)
        .maybeSingle();

    if (res == null) return {};
    return Map<String, dynamic>.from(res);
  }

  Future<void> updateMyProfile(Map<String, dynamic> payload) async {
    _ensureAuthenticatedSync();
    final userId = _userId();

    final completion = _calculateProfileCompletion(payload);

    await _db.from('user_profiles').update({
      ...payload,
      'profile_completion_percentage': completion,
      'last_profile_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  int _calculateProfileCompletion(Map<String, dynamic> p) {
    // 10 key fields => 100%
    final fields = [
      'full_name',
      'mobile_number',
      'current_city',
      'current_state',
      'highest_education',
      'total_experience_years',
      'expected_salary_min',
      'skills',
      'bio',
      'preferred_job_types',
    ];

    int filled = 0;

    for (final f in fields) {
      final v = p[f];

      bool ok = false;

      if (v == null) {
        ok = false;
      } else if (v is String) {
        ok = v.trim().isNotEmpty;
      } else if (v is int) {
        ok = v > 0;
      } else if (v is double) {
        ok = v > 0;
      } else if (v is List) {
        ok = v.isNotEmpty;
      } else {
        ok = v.toString().trim().isNotEmpty;
      }

      if (ok) filled++;
    }

    final pct = ((filled / fields.length) * 100).round();
    return pct.clamp(0, 100);
  }

  // ============================================================
  // TOP COMPANIES (REAL)
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchTopCompanies({
    int limit = 8,
  }) async {
    _ensureAuthenticatedSync();

    // SQL VIEW: companies_with_stats
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
  // FOLLOW COMPANY
  // ============================================================

  Future<bool> isCompanyFollowed(String companyId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('followed_companies')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .maybeSingle();

    return res != null;
  }

  Future<bool> toggleFollowCompany(String companyId) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final existing = await _db
        .from('followed_companies')
        .select('id')
        .eq('user_id', userId)
        .eq('company_id', companyId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('followed_companies')
          .delete()
          .eq('user_id', userId)
          .eq('company_id', companyId);

      return false;
    }

    await _db.from('followed_companies').insert({
      'user_id': userId,
      'company_id': companyId,
      'followed_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  // ============================================================
  // COMPANY REVIEWS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchCompanyReviews({
    required String companyId,
    int limit = 20,
  }) async {
    _ensureAuthenticatedSync();

    final res = await _db
        .from('company_reviews')
        .select('id, rating, review_text, created_at, is_anonymous')
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 40,
  }) async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    final res = await _db
        .from('notifications')
        .select('id, type, title, body, data, is_read, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

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

  Future<void> markNotificationRead(String notificationId) async {
    _ensureAuthenticatedSync();

    await _db
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllNotificationsRead() async {
    _ensureAuthenticatedSync();

    final userId = _userId();

    await _db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
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