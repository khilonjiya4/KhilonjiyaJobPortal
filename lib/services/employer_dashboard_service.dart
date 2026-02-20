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

    orgs.sort((a, b) {
      final an = (a['name'] ?? '').toString().toLowerCase();
      final bn = (b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    return orgs;
  }

  Future<String> resolveDefaultOrganizationId() async {
    final orgs = await fetchMyOrganizations();
    if (orgs.isEmpty) {
      throw Exception("No organization linked. Please create one first.");
    }
    return (orgs.first['id'] ?? '').toString();
  }

  Future<Map<String, dynamic>> fetchOrganizationById({
    required String organizationId,
  }) async {
    _requireUser();

    final id = organizationId.trim();
    if (id.isEmpty) throw Exception("Organization ID missing");

    final org = await _db
        .from('companies')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (org == null) {
      throw Exception("Organization not found or access denied.");
    }

    return Map<String, dynamic>.from(org);
  }

  // ------------------------------------------------------------
  // COMPANY COMPATIBILITY METHODS (FOR DASHBOARD)
  // ------------------------------------------------------------

  Future<String> resolveDefaultCompanyId() async {
    return resolveDefaultOrganizationId();
  }

  Future<Map<String, dynamic>> fetchCompanyById({
    required String companyId,
  }) async {
    return fetchOrganizationById(organizationId: companyId);
  }

  // Dummy safe methods so dashboard compiles

  Future<List<Map<String, dynamic>>> fetchCompanyJobs({
    required String companyId,
  }) async {
    return [];
  }

  Future<Map<String, dynamic>> fetchCompanyDashboardStats({
    required String companyId,
  }) async {
    return {};
  }

  Future<List<Map<String, dynamic>>> fetchRecentApplicants({
    required String companyId,
    int limit = 6,
  }) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchTopJobs({
    required String companyId,
    int limit = 6,
  }) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchTodayInterviews({
    required String companyId,
    int limit = 10,
  }) async {
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchLast7DaysPerformance({
    required String companyId,
  }) async {
    return [];
  }

  // ------------------------------------------------------------
  // CREATE ORGANIZATION
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

    final distRow = await _db
        .from('assam_districts_master')
        .select('district_name')
        .eq('id', distId)
        .maybeSingle();

    if (distRow == null) throw Exception("District invalid");

    final districtName =
        (distRow['district_name'] ?? '').toString().trim();

    final inserted = await _db
        .from('companies')
        .insert({
          'name': n,
          'business_type_id': btId,
          'headquarters_city': districtName,
          'headquarters_state': 'Assam',
          'website': website.trim().isEmpty ? null : website.trim(),
          'description': description.trim().isEmpty
              ? null
              : description.trim(),
          'created_by': user.id,
          'owner_id': user.id,
        })
        .select('id')
        .single();

    final companyId =
        (inserted['id'] ?? '').toString().trim();

    await _db.from('company_members').upsert({
      'company_id': companyId,
      'user_id': user.id,
      'role': 'member',
      'status': 'active',
    }, onConflict: 'company_id,user_id');

    return companyId;
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
}