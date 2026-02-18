// lib/services/employer_jobs_service.dart
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
  // FETCH JOBS (WITH APPLICATION COUNTS)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchEmployerJobs({
    String search = '',
    String status = 'all', // all | active | paused | closed | expired
  }) async {
    final user = _requireUser();

    var q = _db.from('job_listings').select('''
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
        ''');

    q = q.eq('employer_id', user.id).order('created_at', ascending: false);

    final s = status.trim().toLowerCase();
    if (s != 'all') {
      if (!allowedStatuses.contains(s)) {
        throw Exception("Invalid status filter: $status");
      }
      q = q.eq('status', s);
    }

    final searchText = search.trim();
    if (searchText.isNotEmpty) {
      q = q.ilike('job_title', '%$searchText%');
    }

    final jobs = await q;

    final jobList = List<Map<String, dynamic>>.from(jobs);
    if (jobList.isEmpty) return [];

    final jobIds = jobList.map((e) => e['id'].toString()).toList();

    // Applications count
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

    // Ensure employer owns this job
    final updated = await _db
        .from('job_listings')
        .update({
          'status': s,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('employer_id', user.id)
        .select('id,status')
        .maybeSingle();

    if (updated == null) {
      throw Exception("Job not found or not permitted.");
    }

    // Optional: status history
    try {
      await _db.from('job_status_history').insert({
        'job_id': id,
        'employer_id': user.id,
        'new_status': s,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // DELETE JOB (REAL)
  // ------------------------------------------------------------
  Future<void> deleteJob({required String jobId}) async {
    final user = _requireUser();

    final id = jobId.trim();
    if (id.isEmpty) throw Exception("Job ID missing");

    // Ensure job belongs to employer
    final job = await _db
        .from('job_listings')
        .select('id')
        .eq('id', id)
        .eq('employer_id', user.id)
        .maybeSingle();

    if (job == null) {
      throw Exception("Job not found or not permitted.");
    }

    // IMPORTANT:
    // Your DB has job_applications_listings referencing job_listings.
    // If foreign key is NOT ON DELETE CASCADE, delete will fail.
    //
    // So we do safe deletion order:
    // 1) delete stage history + events + interviews (if any)
    // 2) delete job_applications_listings
    // 3) delete job_listings

    // 1) Load all listing rows for this job
    final listingRows = await _db
        .from('job_applications_listings')
        .select('id')
        .eq('listing_id', id);

    final listingList = List<Map<String, dynamic>>.from(listingRows);
    final listingIds = listingList.map((e) => (e['id'] ?? '').toString()).where((x) => x.isNotEmpty).toList();

    if (listingIds.isNotEmpty) {
      // delete interviews
      try {
        await _db.from('interviews').delete().inFilter('job_application_listing_id', listingIds);
      } catch (_) {}

      // delete application events
      try {
        await _db.from('application_events').delete().inFilter('job_application_listing_id', listingIds);
      } catch (_) {}

      // delete stage history
      try {
        await _db.from('application_stage_history').delete().inFilter('job_application_listing_id', listingIds);
      } catch (_) {}
    }

    // 2) delete job_applications_listings rows
    try {
      await _db.from('job_applications_listings').delete().eq('listing_id', id);
    } catch (e) {
      throw Exception(
        "Cannot delete job because applications exist and DB constraints blocked deletion. "
        "Enable ON DELETE CASCADE or allow soft delete.\n\n$e",
      );
    }

    // 3) delete the job itself
    await _db.from('job_listings').delete().eq('id', id).eq('employer_id', user.id);
  }

  // ------------------------------------------------------------
  // COMPANY ID FOR PIPELINE PAGE
  // ------------------------------------------------------------
  Future<String> resolveMyCompanyId() async {
    final user = _requireUser();

    // owner_id
    final owned = await _db
        .from('companies')
        .select('id')
        .eq('owner_id', user.id)
        .maybeSingle();

    if (owned != null) return (owned['id'] ?? '').toString();

    // company_members
    final member = await _db
        .from('company_members')
        .select('company_id,status')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (member == null) throw Exception("No company linked to employer account");

    final companyId = (member['company_id'] ?? '').toString();
    if (companyId.trim().isEmpty) throw Exception("Company ID invalid");

    return companyId;
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