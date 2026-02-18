// lib/services/employer_applicants_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerApplicantsService {
  final SupabaseClient _db = Supabase.instance.client;

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  // ------------------------------------------------------------
  // SECURITY: ensure current user owns the job
  // ------------------------------------------------------------
  Future<void> ensureJobOwner(String jobId) async {
    final user = _requireUser();

    final job = await _db
        .from('job_listings')
        .select('id, employer_id')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final employerId = (job['employer_id'] ?? '').toString();
    if (employerId != user.id) {
      throw Exception("Not allowed to access applicants for this job");
    }
  }

  // ------------------------------------------------------------
  // PIPELINE STAGES
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCompanyPipelineStages({
    required String companyId,
  }) async {
    _requireUser();

    final res = await _db
        .from('company_pipeline_stages')
        .select('id, company_id, stage_name, stage_order, is_default')
        .eq('company_id', companyId)
        .order('stage_order', ascending: true);

    return List<Map<String, dynamic>>.from(res);
  }

  // ------------------------------------------------------------
  // FETCH APPLICANTS FOR JOB
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    _requireUser();

    final res = await _db
        .from('job_applications_listings')
        .select('''
          id,
          listing_id,
          application_id,
          applied_at,
          application_status,
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
  // MOVE APPLICANT TO A PIPELINE STAGE
  // We store stage_id in employer_notes JSON (since schema doesn't have pipeline_stage_id)
  //
  // IMPORTANT:
  // Your schema for job_applications_listings does NOT have pipeline_stage_id.
  // So we store stage_id in employer_notes as JSON:
  // { "pipeline_stage_id": "...", "note": "..." }
  //
  // This keeps it working without DB migration.
  // ------------------------------------------------------------
  Future<void> moveApplicantToStage({
    required String listingRowId,
    required String jobId,
    required String toStageId,
    String? note,
  }) async {
    final user = _requireUser();

    // Verify owner
    await ensureJobOwner(jobId);

    // Fetch current employer_notes so we don't overwrite
    final row = await _db
        .from('job_applications_listings')
        .select('id, employer_notes')
        .eq('id', listingRowId)
        .maybeSingle();

    if (row == null) throw Exception("Application row not found");

    final existingNotes = (row['employer_notes'] ?? '').toString().trim();

    // Save pipeline stage inside employer_notes JSON-like string
    // (Simple safe format: stage:<uuid>)
    final newNotes = _mergeNotes(
      existingNotes: existingNotes,
      stageId: toStageId,
      note: note,
    );

    await _db.from('job_applications_listings').update({
      'employer_notes': newNotes,
    }).eq('id', listingRowId);

    // Stage history
    try {
      await _db.from('application_stage_history').insert({
        'job_application_listing_id': listingRowId,
        'stage_id': toStageId,
        'moved_by': user.id,
        'moved_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint("stage_history insert failed: $e");
    }

    // Event log
    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'stage_moved',
        'actor_user_id': user.id,
        'notes': 'Moved to stage',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // SAVE EMPLOYER NOTE
  // ------------------------------------------------------------
  Future<void> updateEmployerNotes({
    required String listingRowId,
    required String jobId,
    required String notes,
  }) async {
    _requireUser();
    await ensureJobOwner(jobId);

    await _db.from('job_applications_listings').update({
      'employer_notes': notes.trim(),
    }).eq('id', listingRowId);

    try {
      final user = _db.auth.currentUser;
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'note_updated',
        'actor_user_id': user?.id,
        'notes': 'Employer updated notes',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // INTERNAL: stage stored in notes
  // ------------------------------------------------------------
  String _mergeNotes({
    required String existingNotes,
    required String stageId,
    String? note,
  }) {
    // We store as:
    // [pipeline_stage_id:<uuid>]
    // <existing text...>
    // <note line...>

    String cleaned = existingNotes;

    // Remove old stage tag
    cleaned = cleaned.replaceAll(RegExp(r'\[pipeline_stage_id:.*?\]\s*'), '');

    final tag = '[pipeline_stage_id:$stageId]';

    final extra = (note ?? '').trim();
    if (extra.isEmpty) {
      return '$tag\n$cleaned'.trim();
    }

    return '$tag\n$cleaned\n\n$extra'.trim();
  }

  // Extract stage id from employer_notes
  String extractStageId(dynamic employerNotes) {
    if (employerNotes == null) return '';
    final s = employerNotes.toString();

    final m = RegExp(r'\[pipeline_stage_id:(.*?)\]').firstMatch(s);
    if (m == null) return '';
    return (m.group(1) ?? '').trim();
  }
}