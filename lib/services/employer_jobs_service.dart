// lib/services/employer_jobs_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerJobsService {
  final SupabaseClient _db = Supabase.instance.client;

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

    if (status != 'all') {
      q = q.eq('status', status);
    }

    if (search.trim().isNotEmpty) {
      // Supabase ilike
      q = q.ilike('job_title', '%${search.trim()}%');
    }

    final jobs = await q;

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
  // STATUS UPDATE (ACTIVE/PAUSED/CLOSED)
  // ------------------------------------------------------------
  Future<void> updateJobStatus({
    required String jobId,
    required String newStatus, // active | paused | closed
  }) async {
    final user = _requireUser();

    if (jobId.trim().isEmpty) throw Exception("Job ID missing");
    if (newStatus.trim().isEmpty) throw Exception("Status missing");

    // Only allow employer to update their own job
    final updated = await _db
        .from('job_listings')
        .update({
          'status': newStatus,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', jobId)
        .eq('employer_id', user.id)
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw Exception("Job not found or not permitted.");
    }

    // Optional: status history (if table exists)
    try {
      await _db.from('job_status_history').insert({
        'job_id': jobId,
        'employer_id': user.id,
        'new_status': newStatus,
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
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