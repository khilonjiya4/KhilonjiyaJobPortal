import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobsService {
  final SupabaseClient _db = Supabase.instance.client;

  // Allowed statuses in your schema:
  // active | paused | closed | expired
  static const Set<String> allowedStatuses = {
    'active',
    'paused',
    'closed',
    'expired',
  };

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  // ------------------------------------------------------------
  // COMPANY IDS (MULTI-ORG)
  // ------------------------------------------------------------
  Future<List<String>> fetchMyActiveCompanyIds() async {
    final user = _requireUser();

    final res = await _db
        .from('company_members')
        .select('company_id,status')
        .eq('user_id', user.id)
        .eq('status', 'active');

    final rows = List<Map<String, dynamic>>.from(res);

    final ids = rows
        .map((e) => (e['company_id'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    return ids;
  }

  // ------------------------------------------------------------
  // FETCH JOBS (MULTI-ORG) + APPLICATION COUNTS
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs({
    String search = '',
    String status = 'all', // all | active | paused | closed | expired
  }) async {
    final user = _requireUser();

    final s = status.trim().toLowerCase();
    if (s != 'all' && !allowedStatuses.contains(s)) {
      throw Exception("Invalid status filter: $status");
    }

    final searchText = search.trim();

    // 1) Fetch all orgs where this employer is an active member
    final companyIds = await fetchMyActiveCompanyIds();

    // If user is not member of any org, show empty list.
    // (Employer must create org first.)
    if (companyIds.isEmpty) return [];

    // 2) Fetch jobs for those companies
    var query = _db
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
        .inFilter('company_id', companyIds);

    if (s != 'all') {
      query = query.eq('status', s);
    }

    if (searchText.isNotEmpty) {
      query = query.ilike('job_title', '%$searchText%');
    }

    final jobs = await query.order('created_at', ascending: false);

    final jobList = List<Map<String, dynamic>>.from(jobs);
    if (jobList.isEmpty) return [];

    final jobIds = jobList.map((e) => e['id'].toString()).toList();

    // 3) Applications count
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
  // STATUS UPDATE (ACTIVE/PAUSED/CLOSED/EXPIRED)
  // ------------------------------------------------------------
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus, // active | paused | closed | expired
  }) async {
    final user = _requireUser();

    final id = jobId.trim();
    if (id.isEmpty) throw Exception("Job ID missing");

    final s = newStatus.trim().toLowerCase();
    if (s.isEmpty) throw Exception("Status missing");

    if (!allowedStatuses.contains(s)) {
      throw Exception("Invalid status: $newStatus");
    }

    // IMPORTANT:
    // Since we allow multiple employers to manage same company,
    // the permission check must be based on company membership, not employer_id.
    //
    // So:
    // 1) Load job company_id
    // 2) Ensure user is active member of that company
    // 3) Update

    final job = await _db
        .from('job_listings')
        .select('id,company_id,status')
        .eq('id', id)
        .maybeSingle();

    if (job == null) {
      throw Exception("Job not found.");
    }

    final companyId = (job['company_id'] ?? '').toString().trim();
    if (companyId.isEmpty) {
      throw Exception("Job has no organization linked.");
    }

    final membership = await _db
        .from('company_members')
        .select('id,status')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (membership == null) {
      throw Exception("Not permitted. You are not a member of this organization.");
    }

    // Update job
    final updated = await _db
        .from('job_listings')
        .update({
          'status': s,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select('id,status,company_id')
        .maybeSingle();

    if (updated == null) {
      throw Exception("Update failed.");
    }

    // Optional: status history
    try {
      await _db.from('job_status_history').insert({
        'job_id': id,
        'employer_id': user.id,
        'company_id': companyId,
        'old_status': (job['status'] ?? '').toString(),
        'new_status': s,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // DELETE JOB (MULTI-ORG SAFE)
  // ------------------------------------------------------------
  Future<void> deleteJob({required String jobId}) async {
    final user = _requireUser();

    final id = jobId.trim();
    if (id.isEmpty) throw Exception("Job ID missing");

    // 1) Load job + company_id
    final job = await _db
        .from('job_listings')
        .select('id,company_id')
        .eq('id', id)
        .maybeSingle();

    if (job == null) {
      throw Exception("Job not found.");
    }

    final companyId = (job['company_id'] ?? '').toString().trim();
    if (companyId.isEmpty) {
      throw Exception("Job has no organization linked.");
    }

    // 2) Membership check
    final membership = await _db
        .from('company_members')
        .select('id,status')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (membership == null) {
      throw Exception("Not permitted. You are not a member of this organization.");
    }

    // 3) Safe deletion order (because FK may block)
    final listingRows = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('listing_id', id);

    final listingList = List<Map<String, dynamic>>.from(listingRows);

    final listingIds = listingList
        .map((e) => (e['id'] ?? '').toString())
        .where((x) => x.isNotEmpty)
        .toList();

    if (listingIds.isNotEmpty) {
      // delete interviews
      try {
        await _db
            .from('interviews')
            .delete()
            .inFilter('job_application_listing_id', listingIds);
      } catch (_) {}

      // delete application events
      try {
        await _db
            .from('application_events')
            .delete()
            .inFilter('job_application_listing_id', listingIds);
      } catch (_) {}

      // delete stage history
      try {
        await _db
            .from('application_stage_history')
            .delete()
            .inFilter('job_application_listing_id', listingIds);
      } catch (_) {}
    }

    // delete job_applications_listings rows
    try {
      await _db.from('job_applications_listings').delete().eq('listing_id', id);
    } catch (e) {
      throw Exception(
        "Cannot delete job because applications exist and DB constraints blocked deletion.\n\n$e",
      );
    }

    // delete the job itself
    await _db.from('job_listings').delete().eq('id', id);
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  int toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}