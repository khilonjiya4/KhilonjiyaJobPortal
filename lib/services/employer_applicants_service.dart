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
  // ACCESS CONTROL (REAL)
  //
  // Your rule now:
  // - A job belongs to an organization (company_id)
  // - Any active member of that organization can manage applicants
  // - No strict employer_id ownership
  // ------------------------------------------------------------
  Future<Map<String, dynamic>> ensureCanAccessJobAndGetJob(String jobId) async {
    final user = _requireUser();

    final job = await _db
        .from('job_listings')
        .select('id, company_id, job_title')
        .eq('id', jobId)
        .maybeSingle();

    if (job == null) throw Exception("Job not found");

    final companyId = (job['company_id'] ?? '').toString().trim();
    if (companyId.isEmpty) {
      throw Exception("This job is not linked to any organization.");
    }

    // Must be active member of that company
    final member = await _db
        .from('company_members')
        .select('id, status')
        .eq('company_id', companyId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (member == null) {
      throw Exception("You are not a member of this organization.");
    }

    final status = (member['status'] ?? '').toString().toLowerCase();
    if (status != 'active') {
      throw Exception("Your organization membership is not active.");
    }

    return Map<String, dynamic>.from(job);
  }

  // ------------------------------------------------------------
  // PIPELINE STAGES (REAL)
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
  // LOAD APPLICANTS FOR JOB (REAL)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchApplicantsForJob(String jobId) async {
    _requireUser();
    await ensureCanAccessJobAndGetJob(jobId);

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
  // MARK VIEWED (REAL)
  // ------------------------------------------------------------
  Future<void> markViewed({
    required String listingRowId,
    required String jobId,
  }) async {
    final user = _requireUser();
    await ensureCanAccessJobAndGetJob(jobId);

    // Only upgrade applied -> viewed
    final row = await _db
        .from('job_applications_listings')
        .select('id, application_status')
        .eq('id', listingRowId)
        .maybeSingle();

    if (row == null) return;

    final s = (row['application_status'] ?? 'applied').toString().toLowerCase();
    if (s != 'applied') return;

    await _db.from('job_applications_listings').update({
      'application_status': 'viewed',
    }).eq('id', listingRowId);

    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'viewed',
        'actor_user_id': user.id,
        'notes': 'Employer viewed application',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // UPDATE STATUS (REAL)
  // ------------------------------------------------------------
  Future<void> updateApplicationStatus({
    required String listingRowId,
    required String jobId,
    required String status,
    String? note,
  }) async {
    final user = _requireUser();
    await ensureCanAccessJobAndGetJob(jobId);

    final s = status.trim().toLowerCase();
    const allowed = {
      'applied',
      'viewed',
      'shortlisted',
      'interview_scheduled',
      'interviewed',
      'selected',
      'rejected',
    };
    if (!allowed.contains(s)) {
      throw Exception("Invalid status: $status");
    }

    await _db.from('job_applications_listings').update({
      'application_status': s,
      if ((note ?? '').trim().isNotEmpty) 'employer_notes': note!.trim(),
    }).eq('id', listingRowId);

    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'status_changed',
        'actor_user_id': user.id,
        'notes': 'Changed status to $s',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // SCHEDULE INTERVIEW (REAL)
  // ------------------------------------------------------------
  Future<void> scheduleInterview({
    required String listingRowId,
    required String jobId,
    required String companyId,
    required DateTime scheduledAt,
    int durationMinutes = 30,
    String interviewType = 'video',
    String? meetingLink,
    String? locationAddress,
    String? notes,
  }) async {
    final user = _requireUser();
    final job = await ensureCanAccessJobAndGetJob(jobId);

    final jobCompanyId = (job['company_id'] ?? '').toString().trim();
    if (jobCompanyId.isEmpty) {
      throw Exception("Job has no organization linked.");
    }

    // safety: prevent scheduling under wrong org id
    if (companyId.trim() != jobCompanyId) {
      throw Exception("Organization mismatch for this job.");
    }

    await _db.from('interviews').insert({
      'job_application_listing_id': listingRowId,
      'company_id': companyId,
      'round_number': 1,
      'interview_type': interviewType,
      'scheduled_at': scheduledAt.toIso8601String(),
      'duration_minutes': durationMinutes,
      'meeting_link': (meetingLink ?? '').trim().isEmpty ? null : meetingLink,
      'location_address':
          (locationAddress ?? '').trim().isEmpty ? null : locationAddress,
      'notes': (notes ?? '').trim().isEmpty ? null : notes,
      'created_by': user.id,
    });

    await _db.from('job_applications_listings').update({
      'interview_date': scheduledAt.toIso8601String(),
      'application_status': 'interview_scheduled',
    }).eq('id', listingRowId);

    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'interview_scheduled',
        'actor_user_id': user.id,
        'notes': 'Interview scheduled',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // EMPLOYER NOTES (REAL)
  // ------------------------------------------------------------
  Future<void> updateEmployerNotes({
    required String listingRowId,
    required String jobId,
    required String notes,
  }) async {
    final user = _requireUser();
    await ensureCanAccessJobAndGetJob(jobId);

    await _db.from('job_applications_listings').update({
      'employer_notes': notes.trim(),
    }).eq('id', listingRowId);

    try {
      await _db.from('application_events').insert({
        'job_application_listing_id': listingRowId,
        'event_type': 'note_updated',
        'actor_user_id': user.id,
        'notes': 'Employer updated notes',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // PIPELINE STAGE
  // IMPORTANT:
  // This is still a workaround, because your schema currently has
  // no pipeline_stage_id column in job_applications_listings.
  //
  // If you want a real pipeline board, you MUST add:
  // job_applications_listings.pipeline_stage_id uuid
  // ------------------------------------------------------------
  Future<void> moveApplicantToStage({
    required String listingRowId,
    required String jobId,
    required String toStageId,
    String? note,
  }) async {
    final user = _requireUser();
    await ensureCanAccessJobAndGetJob(jobId);

    final row = await _db
        .from('job_applications_listings')
        .select('id, employer_notes')
        .eq('id', listingRowId)
        .maybeSingle();

    if (row == null) throw Exception("Application row not found");

    final existingNotes = (row['employer_notes'] ?? '').toString().trim();

    final newNotes = _mergeNotes(
      existingNotes: existingNotes,
      stageId: toStageId,
      note: note,
    );

    await _db.from('job_applications_listings').update({
      'employer_notes': newNotes,
    }).eq('id', listingRowId);

    // stage history
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

    // event
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

  String _mergeNotes({
    required String existingNotes,
    required String stageId,
    String? note,
  }) {
    String cleaned = existingNotes;
    cleaned = cleaned.replaceAll(RegExp(r'\[pipeline_stage_id:.*?\]\s*'), '');

    final tag = '[pipeline_stage_id:$stageId]';
    final extra = (note ?? '').trim();

    if (extra.isEmpty) return '$tag\n$cleaned'.trim();
    return '$tag\n$cleaned\n\n$extra'.trim();
  }

  String extractStageId(dynamic employerNotes) {
    if (employerNotes == null) return '';
    final s = employerNotes.toString();

    final m = RegExp(r'\[pipeline_stage_id:(.*?)\]').firstMatch(s);
    if (m == null) return '';
    return (m.group(1) ?? '').trim();
  }
}