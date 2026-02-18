// File: lib/services/employer_applicants_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicantsService {
  final SupabaseClient _db = Supabase.instance.client;

  // ------------------------------------------------------------
  // AUTH HELPERS
  // ------------------------------------------------------------
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
  //
  // IMPORTANT:
  // In your app you have BOTH patterns in code:
  // - job_listings.user_id
  // - job_listings.employer_id
  //
  // This method now supports BOTH safely.
  //
  Future<void> ensureJobOwner(String jobId) async {
    final uid = _userId();

    final job = await _db
        .from('job_listings')
        .select('id, employer_id, user_id')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final employerId = (job['employer_id'] ?? '').toString().trim();
    final userId = (job['user_id'] ?? '').toString().trim();

    final ownerId = employerId.isNotEmpty ? employerId : userId;

    if (ownerId.isEmpty) {
      throw Exception("Job owner not set. Please fix job_listings owner field.");
    }

    if (ownerId != uid) {
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
  //
  // This method now:
  // 1) Updates pipeline_stage_id
  // 2) Writes application_stage_history
  // 3) Writes application_events
  // 4) Optionally maps application_status using stage_key (if you want)
  //
  Future<void> moveApplicantToStage({
    required String listingRowId,
    required String jobId,
    required String? fromStageId,
    required String toStageId,
    String? note,
  }) async {
    _ensureAuth();

    // SECURITY: verify ownership for THIS job
    await ensureJobOwner(jobId);

    final uid = _userId();

    // ------------------------------------------------------------
    // 1) Update listing stage
    // ------------------------------------------------------------
    await _db.from('job_applications_listings').update({
      'pipeline_stage_id': toStageId,
      // if you want, also store employer_notes directly
      if ((note ?? '').trim().isNotEmpty) 'employer_notes': (note ?? '').trim(),
    }).eq('id', listingRowId);

    // ------------------------------------------------------------
    // 2) Insert stage history
    // ------------------------------------------------------------
    try {
      await _db.from('application_stage_history').insert({
        'job_application_listing_id': listingRowId,
        'from_stage_id': (fromStageId ?? '').trim().isEmpty ? null : fromStageId,
        'to_stage_id': toStageId,
        'changed_by': uid,
        'notes': (note ?? '').trim(),
        'changed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint("stage_history insert failed: $e");
    }

    // ------------------------------------------------------------
    // 3) Insert event
    // ------------------------------------------------------------
    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'stage_changed',
        'actor_user_id': uid,
        'notes': (note ?? '').trim().isEmpty ? 'Moved stage' : (note ?? '').trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint("application_events insert failed: $e");
    }

    // ------------------------------------------------------------
    // 4) OPTIONAL: auto update application_status
    // ------------------------------------------------------------
    //
    // Only do this if your DB uses application_status for filtering.
    // If you rely ONLY on pipeline_stage_id, you can remove this.
    //
    // This mapping is safe even if stage IDs are UUIDs,
    // because we read stage_key from company_pipeline_stages.
    //
    try {
      final stage = await _db
          .from('company_pipeline_stages')
          .select('id, stage_key')
          .eq('id', toStageId)
          .maybeSingle();

      final stageKey = (stage?['stage_key'] ?? '').toString().toLowerCase().trim();

      String? mappedStatus;

      // Keep these values consistent with your existing UI:
      // applied, shortlisted, rejected, viewed, etc.
      if (stageKey == 'applied') mappedStatus = 'applied';
      if (stageKey == 'shortlisted') mappedStatus = 'shortlisted';
      if (stageKey == 'rejected') mappedStatus = 'rejected';
      if (stageKey == 'interview') mappedStatus = 'shortlisted'; // or 'interview'
      if (stageKey == 'hired') mappedStatus = 'shortlisted'; // or 'hired'

      if (mappedStatus != null) {
        await _db.from('job_applications_listings').update({
          'application_status': mappedStatus,
        }).eq('id', listingRowId);
      }
    } catch (e) {
      // ignore: mapping is optional
      if (kDebugMode) debugPrint("status mapping failed: $e");
    }
  }
}