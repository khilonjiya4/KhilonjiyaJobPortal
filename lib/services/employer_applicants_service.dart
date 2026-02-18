import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicantsService {
  final SupabaseClient _db = Supabase.instance.client;

  void _ensureAuth() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
  }

  String _userId() {
    _ensureAuth();
    return _db.auth.currentUser!.id;
  }

  // ------------------------------------------------------------
  // SECURITY: ensure current user owns the job
  // ------------------------------------------------------------
  Future<void> ensureJobOwner(String jobId) async {
    final uid = _userId();

    final job = await _db
        .from('job_listings')
        .select('id, employer_id')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final employerId = (job['employer_id'] ?? '').toString();
    if (employerId != uid) {
      throw Exception("Not allowed to access applicants for this job");
    }
  }

  // ------------------------------------------------------------
  // PIPELINE STAGES
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCompanyPipelineStages({
    required String companyId,
  }) async {
    _ensureAuth();

    final res = await _db
        .from('company_pipeline_stages')
        .select('id, company_id, stage_key, stage_name, sort_order, is_active')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // LOAD APPLICANTS FOR JOB (WITH APPLICATION + STAGE)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    _ensureAuth();

    final res = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,
          pipeline_stage_id,
          employer_notes,
          interview_date,
          user_id,

          job_applications (
            id,
            user_id,
            created_at,
            name,
            phone,
            email,
            district,
            address,
            gender,
            date_of_birth,
            education,
            experience_level,
            experience_details,
            skills,
            expected_salary,
            availability,
            additional_info,
            resume_file_name,
            resume_file_url,
            photo_file_name,
            photo_file_url
          )
        ''')
        .eq('listing_id', jobId)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // MOVE APPLICANT TO STAGE
  // ------------------------------------------------------------
  Future<void> moveApplicantToStage({
    required String listingRowId,
    required String jobId,
    required String? fromStageId,
    required String toStageId,
    String? note,
  }) async {
    _ensureAuth();

    final uid = _userId();

    // Update listing stage
    await _db.from('job_applications_listings').update({
      'pipeline_stage_id': toStageId,
    }).eq('id', listingRowId);

    // Insert stage history
    try {
      await _db.from('application_stage_history').insert({
        'job_application_listing_id': listingRowId,
        'from_stage_id': fromStageId,
        'to_stage_id': toStageId,
        'changed_by': uid,
        'notes': (note ?? '').trim(),
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint("stage_history insert failed: $e");
    }

    // Insert event
    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'stage_changed',
        'actor_user_id': uid,
        'notes': 'Moved stage',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // Optional: auto update application_status
    // (You can modify mapping later)
    String? mappedStatus;
    if (toStageId.isNotEmpty) {
      // if stage_key is stored, we can map better later
      mappedStatus = null;
    }

    if (mappedStatus != null) {
      await _db.from('job_applications_listings').update({
        'application_status': mappedStatus,
      }).eq('id', listingRowId);
    }
  }
}