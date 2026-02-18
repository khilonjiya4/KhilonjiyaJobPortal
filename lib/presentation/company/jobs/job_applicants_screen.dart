import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _rows = [];

  // ------------------------------------------------------------
  // STORAGE CONFIG (MUST MATCH JobSeekerHomeService)
  // ------------------------------------------------------------
  static const String _bucketJobFiles = 'job-files';
  static const int _signedUrlExpirySeconds = 60 * 60; // 1 hour

  // ------------------------------------------------------------
  // FLUENT LIGHT PALETTE
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);
  static const _card = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  String _userId() {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("Session expired");
    return user.id;
  }

  // ------------------------------------------------------------
  // STORAGE HELPERS
  // ------------------------------------------------------------
  bool _looksLikeHttpUrl(String s) {
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  Future<String> _toSignedUrlIfNeeded(String raw) async {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (_looksLikeHttpUrl(v)) return v;

    try {
      final signed = await _client.storage.from(_bucketJobFiles).createSignedUrl(
            v,
            _signedUrlExpirySeconds,
          );
      return signed;
    } catch (_) {
      return v;
    }
  }

  // ------------------------------------------------------------
  // SECURITY: ENSURE THIS EMPLOYER OWNS THIS JOB
  // ------------------------------------------------------------
  Future<bool> _ensureJobOwner() async {
    final userId = _userId();

    final job = await _client
        .from('job_listings')
        .select('id, employer_id')
        .eq('id', widget.jobId)
        .maybeSingle();

    if (job == null) return false;

    final employerId = (job['employer_id'] ?? '').toString();
    return employerId == userId;
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------
  Future<void> _loadApplicants() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = "Session expired. Please login again.";
        });
        return;
      }

      // 🔒 Security check
      final ok = await _ensureJobOwner();
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = "You are not allowed to view applicants for this job.";
        });
        return;
      }

      final res = await _client
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
          .eq('listing_id', widget.jobId)
          .order('applied_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(res);

      // convert storage paths -> signed urls for UI
      for (final row in rows) {
        final app = row['job_applications'];
        if (app is! Map) continue;

        final resumeRaw = (app['resume_file_url'] ?? '').toString().trim();
        final photoRaw = (app['photo_file_url'] ?? '').toString().trim();

        if (resumeRaw.isNotEmpty) {
          app['resume_file_url'] = await _toSignedUrlIfNeeded(resumeRaw);
        }
        if (photoRaw.isNotEmpty) {
          app['photo_file_url'] = await _toSignedUrlIfNeeded(photoRaw);
        }
      }

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint("JobApplicantsScreen load error: $e");
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to load applicants";
      });
    }
  }

  // ------------------------------------------------------------
  // UPDATE STATUS + INSERT EVENT
  // ------------------------------------------------------------
  Future<void> _updateStatus(String listingRowId, String status) async {
    try {
      final userId = _userId();

      await _client
          .from('job_applications_listings')
          .update({'application_status': status})
          .eq('id', listingRowId);

      // log event (schema has application_events)
      try {
        await _client.from('application_events').insert({
          'job_application_listing_id': listingRowId,
          'event_type': 'status_changed',
          'actor_user_id': userId,
          'notes': 'Status changed to $status',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      await _loadApplicants();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status")),
      );
    }
  }

  // ------------------------------------------------------------
  // ACTIONS
  // ------------------------------------------------------------
  Future<void> _call(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return;

    final uri = Uri.parse("tel:$p");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _email(String email) async {
    final e = email.trim();
    if (e.isEmpty) return;

    final uri = Uri.parse("mailto:$e");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.6,
        iconTheme: const IconThemeData(color: _text),
        titleSpacing: 4.w,
        title: const Text(
          'Applicants',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadApplicants,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _rows.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadApplicants,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 4.h),
                        itemCount: _rows.length,
                        itemBuilder: (context, index) {
                          final row = _rows[index];
                          final app = (row['job_applications'] ?? {})
                              as Map<String, dynamic>;

                          final name = (app['name'] ?? '')
                              .toString()
                              .trim()
                              .ifEmpty("Candidate");

                          final phone = (app['phone'] ?? '').toString().trim();
                          final email = (app['email'] ?? '').toString().trim();

                          final district =
                              (app['district'] ?? '').toString().trim();
                          final education =
                              (app['education'] ?? '').toString().trim();

                          final expectedSalary =
                              (app['expected_salary'] ?? '').toString().trim();

                          final experienceLevel =
                              (app['experience_level'] ?? '').toString().trim();

                          final experienceDetails =
                              (app['experience_details'] ?? '')
                                  .toString()
                                  .trim();

                          final skills = (app['skills'] ?? '').toString().trim();

                          final resumeUrl =
                              (app['resume_file_url'] ?? '').toString().trim();

                          final photoUrl =
                              (app['photo_file_url'] ?? '').toString().trim();

                          return _applicantCard(
                            listingRowId: row['id'].toString(),
                            status: (row['application_status'] ?? 'applied')
                                .toString(),
                            appliedAt: row['applied_at'],
                            name: name,
                            phone: phone,
                            email: email,
                            district: district,
                            education: education,
                            expectedSalary: expectedSalary,
                            experienceLevel: experienceLevel,
                            experienceDetails: experienceDetails,
                            skills: skills,
                            resumeUrl: resumeUrl,
                            photoUrl: photoUrl,
                          );
                        },
                      ),
                    ),
    );
  }

  // ------------------------------------------------------------
  // CARD
  // ------------------------------------------------------------
  Widget _applicantCard({
    required String listingRowId,
    required String status,
    required dynamic appliedAt,
    required String name,
    required String phone,
    required String email,
    required String district,
    required String education,
    required String expectedSalary,
    required String experienceLevel,
    required String experienceDetails,
    required String skills,
    required String resumeUrl,
    required String photoUrl,
  }) {
    final statusUi = _statusUi(status);

    return Container(
      margin: EdgeInsets.only(bottom: 1.6.h),
      padding: EdgeInsets.fromLTRB(4.w, 2.0.h, 4.w, 2.0.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _avatar(photoUrl, name),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.6,
                        fontWeight: FontWeight.w900,
                        color: _text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _appliedAgo(appliedAt),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(statusUi.label, statusUi.bg, statusUi.fg),
            ],
          ),

          SizedBox(height: 1.6.h),

          // Contact buttons row
          Row(
            children: [
              Expanded(
                child: _miniAction(
                  icon: Icons.call_rounded,
                  label: "Call",
                  onTap: phone.trim().isEmpty ? null : () => _call(phone),
                ),
              ),
              SizedBox(width: 2.5.w),
              Expanded(
                child: _miniAction(
                  icon: Icons.mail_rounded,
                  label: "Email",
                  onTap: email.trim().isEmpty ? null : () => _email(email),
                ),
              ),
              SizedBox(width: 2.5.w),
              Expanded(
                child: _miniAction(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "Resume",
                  onTap: resumeUrl.trim().isEmpty
                      ? null
                      : () => _openUrl(resumeUrl),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.6.h),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          SizedBox(height: 1.6.h),

          // Summary pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.location_on_rounded,
                text: district.isEmpty ? "District not set" : district,
              ),
              _pill(
                icon: Icons.school_rounded,
                text: education.isEmpty ? "Education not set" : education,
              ),
              _pill(
                icon: Icons.work_rounded,
                text: experienceLevel.isEmpty
                    ? "Experience not set"
                    : experienceLevel,
              ),
              _pill(
                icon: Icons.currency_rupee_rounded,
                text: expectedSalary.isEmpty
                    ? "Salary not set"
                    : expectedSalary,
              ),
            ],
          ),

          if (phone.trim().isNotEmpty || email.trim().isNotEmpty) ...[
            SizedBox(height: 1.4.h),
            _keyValueRow("Phone", phone.isEmpty ? "Not provided" : phone),
            if (email.trim().isNotEmpty) _keyValueRow("Email", email.trim()),
          ],

          if (experienceDetails.trim().isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            const Text(
              "Experience Details",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              experienceDetails,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],

          if (skills.trim().isNotEmpty) ...[
            SizedBox(height: 1.6.h),
            const Text(
              "Skills",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skills,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],

          SizedBox(height: 2.h),

          // Status actions
          if (status == 'applied') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'shortlisted'),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      "Shortlist",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'rejected'),
                    icon: const Icon(Icons.cancel_rounded, size: 18),
                    label: const Text(
                      "Reject",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9F1239),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(listingRowId, 'viewed'),
                    icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                    label: const Text(
                      "Mark Viewed",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _text,
                      side: const BorderSide(color: _line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatar(String photoUrl, String name) {
    if (photoUrl.trim().isEmpty) {
      final letter = name.trim().isEmpty ? 'C' : name.trim()[0].toUpperCase();
      final color = Colors.primaries[
          Random(name.hashCode).nextInt(Colors.primaries.length)];

      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 52,
          height: 52,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFF9F1239),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SMALL UI PIECES
  // ------------------------------------------------------------
  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled ? _line : const Color(0xFFDBEAFE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled ? const Color(0xFF94A3B8) : _primary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: disabled ? const Color(0xFF94A3B8) : _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF334155)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyValueRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  _StatusUI _statusUi(String status) {
    final s = status.toLowerCase();

    if (s == 'shortlisted') {
      return _StatusUI(
        label: "Shortlisted",
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF14532D),
      );
    }
    if (s == 'rejected') {
      return _StatusUI(
        label: "Rejected",
        bg: const Color(0xFFFFF1F2),
        fg: const Color(0xFF9F1239),
      );
    }
    if (s == 'viewed') {
      return _StatusUI(
        label: "Viewed",
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF334155),
      );
    }

    return _StatusUI(
      label: "Applied",
      bg: const Color(0xFFEFF6FF),
      fg: const