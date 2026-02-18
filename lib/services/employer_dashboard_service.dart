// lib/services/employer_dashboard_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerDashboardService {
  final SupabaseClient _db = Supabase.instance.client;

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  // ------------------------------------------------------------
  // COMPANY RESOLUTION (owner_id OR company_members)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> resolveMyCompany() async {
    final user = _requireUser();

    // 1) Try owner_id
    final owned = await _db
        .from('companies')
        .select('''
          id,
          name,
          logo_url,
          is_verified,
          headquarters_city,
          headquarters_state,
          industry,
          company_size,
          website,
          description,
          rating,
          total_reviews,
          created_at
        ''')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (owned != null) {
      return Map<String, dynamic>.from(owned);
    }

    // 2) Try company_members
    final member = await _db
        .from('company_members')
        .select('company_id, role, status')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (member == null) {
      throw Exception(
        "No company linked to this employer account. Please contact support.",
      );
    }

    final companyId = (member['company_id'] ?? '').toString();
    if (companyId.trim().isEmpty) {
      throw Exception("Company link is invalid. Please contact support.");
    }

    final company = await _db
        .from('companies')
        .select('''
          id,
          name,
          logo_url,
          is_verified,
          headquarters_city,
          headquarters_state,
          industry,
          company_size,
          website,
          description,
          rating,
          total_reviews,
          created_at
        ''')
        .eq('id', companyId)
        .maybeSingle();

    if (company == null) {
      throw Exception("Company not found. Please contact support.");
    }

    return Map<String, dynamic>.from(company);
  }

  // ------------------------------------------------------------
  // JOBS (WITH APPLICATION COUNTS)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final user = _requireUser();

    final jobs = await _db
        .from('job_listings')
        .select('''
          id,
          company_id,
          employer_id,
          job_title,
          district,
          job_type,
          salary_min,
          salary_max,
          salary_period,
          status,
          views_count,
          created_at,
          expires_at
        ''')
        .eq('employer_id', user.id)
        .order('created_at', ascending: false);

    final jobList = List<Map<String, dynamic>>.from(jobs);
    if (jobList.isEmpty) return [];

    final jobIds = jobList.map((e) => e['id'].toString()).toList();

    final appsRes = await _db
        .from('job_applications_listings')
        .select('listing_id')
        .inFilter('listing_id', jobIds);

    final rows = List<Map<String, dynamic>>.from(appsRes);

    final Map<String, int> countMap = {};
    for (final r in rows) {
      final listingId = (r['listing_id'] ?? '').toString();
      if (listingId.isEmpty) continue;
      countMap[listingId] = (countMap[listingId] ?? 0) + 1;
    }

    return jobList.map((j) {
      final id = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[id] ?? 0,
      };
    }).toList();
  }

  // ------------------------------------------------------------
  // DASHBOARD STATS
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final user = _requireUser();

    // Optional RPC if exists
    try {
      final rpcRes = await _db.rpc(
        'rpc_employer_dashboard_stats',
        params: {'p_employer_id': user.id},
      );

      if (rpcRes != null && rpcRes is Map) {
        final m = Map<String, dynamic>.from(rpcRes);

        m.putIfAbsent('total_jobs', () => 0);
        m.putIfAbsent('active_jobs', () => 0);
        m.putIfAbsent('paused_jobs', () => 0);
        m.putIfAbsent('closed_jobs', () => 0);
        m.putIfAbsent('expired_jobs', () => 0);

        m.putIfAbsent('total_applicants', () => 0);
        m.putIfAbsent('total_views', () => 0);
        m.putIfAbsent('applicants_last_24h', () => 0);

        return m;
      }
    } catch (_) {}

    // fallback compute
    final jobsRes = await _db
        .from('job_listings')
        .select('id,status,views_count,created_at')
        .eq('employer_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    int totalViews = 0;
    int active = 0;
    int paused = 0;
    int closed = 0;
    int expired = 0;

    for (final j in jobs) {
      final s = (j['status'] ?? 'active').toString().toLowerCase();
      totalViews += _toInt(j['views_count']);

      if (s == 'active') active++;
      if (s == 'paused') paused++;
      if (s == 'closed') closed++;
      if (s == 'expired') expired++;
    }

    int totalApplicants = 0;
    int applicants24h = 0;

    if (jobIds.isNotEmpty) {
      final appsRes = await _db
          .from('job_applications_listings')
          .select('listing_id, applied_at')
          .inFilter('listing_id', jobIds);

      final apps = List<Map<String, dynamic>>.from(appsRes);

      totalApplicants = apps.length;

      final now = DateTime.now();
      for (final a in apps) {
        final d = DateTime.tryParse((a['applied_at'] ?? '').toString());
        if (d == null) continue;
        if (now.difference(d).inHours <= 24) applicants24h++;
      }
    }

    return {
      'total_jobs': jobs.length,
      'active_jobs': active,
      'paused_jobs': paused,
      'closed_jobs': closed,
      'expired_jobs': expired,
      'total_applicants': totalApplicants,
      'total_views': totalViews,
      'applicants_last_24h': applicants24h,
    };
  }

  // ------------------------------------------------------------
  // RECENT APPLICANTS
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    int limit = 6,
  }) async {
    final user = _requireUser();

    final jobsRes = await _db
        .from('job_listings')
        .select('id')
        .eq('employer_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => e['id'].toString()).toList();
    if (jobIds.isEmpty) return [];

    final res = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,

          job_listings (
            id,
            job_title,
            company_id
          ),

          job_applications (
            id,
            user_id,
            name,
            phone,
            email,
            district,
            education,
            experience_level,
            expected_salary,
            resume_file_url,
            photo_file_url
          )
        ''')
        .inFilter('listing_id', jobIds)
        .order('applied_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // TOP JOBS (BY APPLICATION COUNT)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    int limit = 6,
  }) async {
    final user = _requireUser();

    final jobsRes = await _db
        .from('job_listings')
        .select('''
          id,
          job_title,
          status,
          views_count,
          created_at
        ''')
        .eq('employer_id', user.id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    if (jobs.isEmpty) return [];

    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    final appsRes = await _db
        .from('job_applications_listings')
        .select('listing_id')
        .inFilter('listing_id', jobIds);

    final apps = List<Map<String, dynamic>>.from(appsRes);

    final Map<String, int> countMap = {};
    for (final a in apps) {
      final id = (a['listing_id'] ?? '').toString();
      if (id.isEmpty) continue;
      countMap[id] = (countMap[id] ?? 0) + 1;
    }

    final enriched = jobs.map((j) {
      final id = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[id] ?? 0,
      };
    }).toList();

    enriched.sort((a, b) {
      final ac = _toInt(a['applications_count']);
      final bc = _toInt(b['applications_count']);
      return bc.compareTo(ac);
    });

    return enriched.take(limit).toList();
  }

  // ------------------------------------------------------------
  // TODAY'S INTERVIEWS (REAL)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTodayInterviews({
    required String companyId,
    int limit = 10,
  }) async {
    _requireUser();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final res = await _db
        .from('interviews')
        .select('''
          id,
          job_application_listing_id,
          company_id,
          round_number,
          interview_type,
          scheduled_at,
          duration_minutes,
          meeting_link,
          location_address,
          notes,
          created_at,

          job_applications_listings (
            id,
            listing_id,
            application_status,

            job_listings (
              id,
              job_title
            ),

            job_applications (
              id,
              name,
              phone,
              email,
              photo_file_url
            )
          )
        ''')
        .eq('company_id', companyId)
        .gte('scheduled_at', start.toIso8601String())
        .lte('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // LAST 7 DAYS PERFORMANCE (REAL)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchLast7DaysPerformance({
    required String employerId,
  }) async {
    _requireUser();

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);

    // load employer job ids
    final jobsRes = await _db
        .from('job_listings')
        .select('id')
        .eq('employer_id', employerId);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => e['id'].toString()).toList();

    // build days map
    final List<Map<String, dynamic>> days = [];
    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      days.add({
        'date': DateTime(d.year, d.month, d.day).toIso8601String(),
        'views': 0,
        'applications': 0,
      });
    }

    if (jobIds.isEmpty) {
      return {
        'days': days,
        'total_views': 0,
        'total_applications': 0,
      };
    }

    // views in last 7 days
    final viewsRes = await _db
        .from('job_views')
        .select('job_id, viewed_at')
        .inFilter('job_id', jobIds)
        .gte('viewed_at', startDate.toIso8601String());

    final views = List<Map<String, dynamic>>.from(viewsRes);

    // applications in last 7 days
    final appsRes = await _db
        .from('job_applications_listings')
        .select('listing_id, applied_at')
        .inFilter('listing_id', jobIds)
        .gte('applied_at', startDate.toIso8601String());

    final apps = List<Map<String, dynamic>>.from(appsRes);

    int totalViews = 0;
    int totalApps = 0;

    // helper for bucket
    int dayIndex(DateTime d) {
      final base = DateTime(startDate.year, startDate.month, startDate.day);
      final dd = DateTime(d.year, d.month, d.day);
      return dd.difference(base).inDays;
    }

    for (final v in views) {
      final t = DateTime.tryParse((v['viewed_at'] ?? '').toString());
      if (t == null) continue;
      final idx = dayIndex(t);
      if (idx < 0 || idx > 6) continue;
      days[idx]['views'] = (days[idx]['views'] as int) + 1;
      totalViews++;
    }

    for (final a in apps) {
      final t = DateTime.tryParse((a['applied_at'] ?? '').toString());
      if (t == null) continue;
      final idx = dayIndex(t);
      if (idx < 0 || idx > 6) continue;
      days[idx]['applications'] = (days[idx]['applications'] as int) + 1;
      totalApps++;
    }

    return {
      'days': days,
      'total_views': totalViews,
      'total_applications': totalApps,
    };
  }

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------
  Future<int> fetchUnreadNotificationsCount() async {
    final user = _requireUser();

    final res = await _db
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    return List<Map<String, dynamic>>.from(res).length;
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}