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
            business_type_id
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

    orgs.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return orgs;
  }

  Future<List<Map<String, dynamic>>> fetchMyCompanies() async {
    return fetchMyOrganizations();
  }

  Future<String> resolveDefaultOrganizationId() async {
    final orgs = await fetchMyOrganizations();
    if (orgs.isEmpty) {
      throw Exception("No organization linked. Please create one first.");
    }
    return (orgs.first['id'] ?? '').toString();
  }

  Future<String> resolveDefaultCompanyId() async {
    return resolveDefaultOrganizationId();
  }

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
          business_type_id
        ''')
        .eq('id', id)
        .maybeSingle();

    if (org == null) {
      throw Exception("Organization not found or access denied.");
    }

    return Map<String, dynamic>.from(org);
  }

  Future<Map<String, dynamic>> fetchCompanyById({
    required String companyId,
  }) async {
    return fetchOrganizationById(organizationId: companyId);
  }

  Future<Map<String, dynamic>> resolveMyCompany() async {
    final companyId = await resolveDefaultOrganizationId();
    return await fetchOrganizationById(organizationId: companyId);
  }

  // ------------------------------------------------------------
  // CREATE ORGANIZATION (REAL)
  // REQUIRED BY YOUR SCHEMA:
  // companies.business_type_id (uuid NOT NULL)
  // companies.created_by (uuid NOT NULL)
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

    if (distRow == null) {
      throw Exception("District invalid");
    }

    final districtName = (distRow['district_name'] ?? '').toString().trim();
    if (districtName.isEmpty) {
      throw Exception("District invalid");
    }

    // create org
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

    // add member
    await _db.from('company_members').insert({
      'company_id': companyId,
      'user_id': user.id,
      'role': 'recruiter',
      'status': 'active',
    });

    return companyId;
  }

  // ------------------------------------------------------------
  // JOBS
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
  // DASHBOARD STATS
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> fetchCompanyDashboardStats({
    required String companyId,
  }) async {
    _requireUser();

    final id = companyId.trim();
    if (id.isEmpty) throw Exception("Company ID missing");

    // fallback compute
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
  // BACKWARD COMPATIBILITY
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs() async {
    final orgId = await resolveDefaultOrganizationId();
    return await fetchCompanyJobs(companyId: orgId);
  }

  Future<Map<String, dynamic>> fetchEmployerDashboardStats() async {
    final orgId = await resolveDefaultOrganizationId();
    return await fetchCompanyDashboardStats(companyId: orgId);
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