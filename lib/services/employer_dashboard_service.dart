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
  // ORGANIZATIONS
  // ------------------------------------------------------------

  /// Returns organizations where current user is an active member.
  Future<List<Map<String, dynamic>>> fetchMyOrganizations() async {
    final user = _requireUser();

    final res = await _db
        .from('company_members')
        .select('''
          company_id,
          role,
          status,
          joined_at,
          companies (
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
            created_at,
            business_type_id,
            owner_id,
            created_by
          )
        ''')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('joined_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(res);

    final List<Map<String, dynamic>> orgs = [];

    for (final r in rows) {
      final c = r['companies'];
      if (c == null || c is! Map) continue;

      final id = (c['id'] ?? '').toString();
      final name = (c['name'] ?? '').toString();

      if (id.trim().isEmpty || name.trim().isEmpty) continue;

      orgs.add({
        ...Map<String, dynamic>.from(c as Map),
        'my_role': (r['role'] ?? 'member').toString(),
        'my_status': (r['status'] ?? 'active').toString(),
        'my_joined_at': r['joined_at'],
      });
    }

    // Stable sorting for UI
    orgs.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return orgs;
  }

  /// Backward compatible name
  Future<List<Map<String, dynamic>>> fetchMyCompanies() async {
    return fetchMyOrganizations();
  }

  /// Picks a default organization for dashboard if user has multiple.
  Future<String> resolveDefaultOrganizationId() async {
    final orgs = await fetchMyOrganizations();
    if (orgs.isEmpty) {
      throw Exception("No organization linked. Please create one first.");
    }
    return (orgs.first['id'] ?? '').toString();
  }

  /// Backward compatible name
  Future<String> resolveDefaultCompanyId() async {
    return resolveDefaultOrganizationId();
  }

  /// Loads full organization object by ID (must be accessible by RLS)
  Future<Map<String, dynamic>> fetchOrganizationById({
    required String organizationId,
  }) async {
    _requireUser();

    final id = organizationId.trim();
    if (id.isEmpty) throw Exception("Organization ID missing");

    final org = await _db
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
          created_at,
          business_type_id,
          owner_id,
          created_by
        ''')
        .eq('id', id)
        .maybeSingle();

    if (org == null) {
      throw Exception("Organization not found or access denied.");
    }

    return Map<String, dynamic>.from(org);
  }

  /// Backward compatible name
  Future<Map<String, dynamic>> fetchCompanyById({
    required String companyId,
  }) async {
    return fetchOrganizationById(organizationId: companyId);
  }

  /// Dashboard uses this
  Future<Map<String, dynamic>> resolveMyCompany() async {
    final companyId = await resolveDefaultOrganizationId();
    return await fetchOrganizationById(organizationId: companyId);
  }

  // ------------------------------------------------------------
  // CREATE ORGANIZATION (REAL)
  // ------------------------------------------------------------
  Future<String> createOrganization({
    required String name,
    required String businessTypeId,
    required String districtId,
    String website = '',
    String description = '',
  }) async {
    final user = _requireUser();

    final n = name.trim();
    if (n.isEmpty) throw Exception("Organization name required");

    final btId = businessTypeId.trim();
    if (btId.isEmpty) throw Exception("Business type required");

    final distId = districtId.trim();
    if (distId.isEmpty) throw Exception("District required");

    // resolve district name from master
    final distRow = await _db
        .from('assam_districts_master')
        .select('district_name')
        .eq('id', distId)
        .maybeSingle();

    if (distRow == null) throw Exception("District invalid");

    final districtName = (distRow['district_name'] ?? '').toString().trim();
    if (districtName.isEmpty) throw Exception("District invalid");

    // 1) create organization
    final inserted = await _db
        .from('companies')
        .insert({
          'name': n,
          'business_type_id': btId,
          'headquarters_city': districtName,
          'headquarters_state': 'Assam',
          'website': website.trim().isEmpty ? null : website.trim(),
          'description': description.trim().isEmpty ? null : description.trim(),
          'created_by': user.id,
          'owner_id': user.id,
        })
        .select('id')
        .single();

    final companyId = (inserted['id'] ?? '').toString().trim();
    if (companyId.isEmpty) throw Exception("Failed to create organization");

    // 2) make current employer an active member
    await _db.from('company_members').insert({
      'company_id': companyId,
      'user_id': user.id,
      'role': 'member',
      'status': 'active',
    });

    return companyId;
  }

  // ------------------------------------------------------------
  // JOBS (ORG BASED)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchCompanyJobs({
    required String companyId,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    final jobs = await _db
        .from('job_listings')
        .select('''
          id,
          company_id,
          employer_id,
          job_title,
          district,
          job_type,
          employment_type,
          salary_min,
          salary_max,
          salary_period,
          status,
          views_count,
          created_at,
          expires_at
        ''')
        .eq('company_id', id)
        .order('created_at', ascending: false);

    final jobList = List<Map<String, dynamic>>.from(jobs);
    if (jobList.isEmpty) return [];

    final jobIds = jobList.map((e) => (e['id'] ?? '').toString()).toList();

    // Application counts
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
      final jid = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[jid] ?? 0,
      };
    }).toList();
  }

  // ------------------------------------------------------------
  // DASHBOARD STATS (ORG BASED)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchCompanyDashboardStats({
    required String companyId,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    final jobsRes = await _db
        .from('job_listings')
        .select('id,status,views_count,created_at')
        .eq('company_id', id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => (e['id'] ?? '').toString()).toList();

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
  // RECENT APPLICANTS (ORG BASED)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    required String companyId,
    int limit = 6,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    final jobsRes = await _db
        .from('job_listings')
        .select('id')
        .eq('company_id', id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => (e['id'] ?? '').toString()).toList();
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
  // TOP JOBS (ORG BASED)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTopJobs({
    required String companyId,
    int limit = 6,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    final jobsRes = await _db
        .from('job_listings')
        .select('''
          id,
          job_title,
          status,
          views_count,
          created_at
        ''')
        .eq('company_id', id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    if (jobs.isEmpty) return [];

    final jobIds = jobs.map((e) => (e['id'] ?? '').toString()).toList();

    final appsRes = await _db
        .from('job_applications_listings')
        .select('listing_id')
        .inFilter('listing_id', jobIds);

    final apps = List<Map<String, dynamic>>.from(appsRes);

    final Map<String, int> countMap = {};
    for (final a in apps) {
      final jid = (a['listing_id'] ?? '').toString();
      if (jid.isEmpty) continue;
      countMap[jid] = (countMap[jid] ?? 0) + 1;
    }

    final enriched = jobs.map((j) {
      final jid = (j['id'] ?? '').toString();
      return {
        ...j,
        'applications_count': countMap[jid] ?? 0,
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
  // TODAY'S INTERVIEWS (ORG BASED)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchTodayInterviews({
    required String companyId,
    int limit = 10,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

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
        .eq('company_id', id)
        .gte('scheduled_at', start.toIso8601String())
        .lte('scheduled_at', end.toIso8601String())
        .order('scheduled_at', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // LAST 7 DAYS PERFORMANCE (ORG BASED)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchLast7DaysPerformance({
    required String companyId,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);

    // load org job ids
    final jobsRes = await _db
        .from('job_listings')
        .select('id')
        .eq('company_id', id);

    final jobs = List<Map<String, dynamic>>.from(jobsRes);
    final jobIds = jobs.map((e) => (e['id'] ?? '').toString()).toList();

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