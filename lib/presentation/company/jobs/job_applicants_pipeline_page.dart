import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/employer_applicants_service.dart';

class JobApplicantsPipelinePage extends StatefulWidget {
  final String jobId;
  final String companyId;

  const JobApplicantsPipelinePage({
    Key? key,
    required this.jobId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<JobApplicantsPipelinePage> createState() =>
      _JobApplicantsPipelinePageState();
}

class _JobApplicantsPipelinePageState extends State<JobApplicantsPipelinePage> {
  final EmployerApplicantsService _service = EmployerApplicantsService();
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // stages: [{id, stage_key, stage_name, sort_order}]
  List<Map<String, dynamic>> _stages = [];

  // all rows from job_applications_listings
  List<Map<String, dynamic>> _rows = [];

  // ------------------------------------------------------------
  // storage config (same bucket)
  // ------------------------------------------------------------
  static const String _bucketJobFiles = 'job-files';
  static const int _signedUrlExpirySeconds = 60 * 60;

  // ------------------------------------------------------------
  // palette
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ------------------------------------------------------------
  // storage signed url
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
      final signed =
          await _client.storage.from(_bucketJobFiles).createSignedUrl(
                v,
                _signedUrlExpirySeconds,
              );
      return signed;
    } catch (_) {
      return v;
    }
  }

  // ------------------------------------------------------------
  // load
  // ------------------------------------------------------------
  Future<void> _load() async {
    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      await _service.ensureJobOwner(widget.jobId);

      final stages = await _service.getCompanyPipelineStages(
        companyId: widget.companyId,
      );

      // fallback if stages empty
      if (stages.isEmpty) {
        _stages = [
          {
            'id': 'applied',
            'stage_key': 'applied',
            'stage_name': 'Applied',
            'sort_order': 1,
          },
          {
            'id': 'shortlisted',
            'stage_key': 'shortlisted',
            'stage_name': 'Shortlisted',
            'sort_order': 2,
          },
          {
            'id': 'interview',
            'stage_key': 'interview',
            'stage_name': 'Interview',
            'sort_order': 3,
          },
          {
            'id': 'hired',
            'stage_key': 'hired',
            'stage_name': 'Hired',
            'sort_order': 4,
          },
          {
            'id': 'rejected',
            'stage_key': 'rejected',
            'stage_name': 'Rejected',
            'sort_order': 5,
          },
        ];
      } else {
        _stages = stages;
      }

      final rows = await _service.fetchApplicantsForJob(widget.jobId);

      // sign urls for UI
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
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ------------------------------------------------------------
  // group rows by stage
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _rowsForStage(String stageId) {
    return _rows.where((r) {
      final v = (r['pipeline_stage_id'] ?? '').toString().trim();

      // if pipeline_stage_id not set, treat as applied
      if (v.isEmpty) {
        return stageId == _stages.first['id'].toString();
      }

      return v == stageId;
    }).toList();
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------
  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _call(String phone) async {
    final p = phone.trim();
    if (p.isEmpty) return;

    final uri = Uri.parse("tel:$p");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _email(String email) async {
    final e = email.trim();
    if (e.isEmpty) return;

    final uri = Uri.parse("mailto:$e");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ------------------------------------------------------------
  // move
  // ------------------------------------------------------------
  Future<void> _move({
    required String listingRowId,
    required String? fromStageId,
    required String toStageId,
  }) async {
    try {
      await _service.moveApplicantToStage(
        listingRowId: listingRowId,
        jobId: widget.jobId,
        fromStageId: fromStageId,
        toStageId: toStageId,
      );

      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to move applicant")),
      );
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
        title: const Text(
          "Applicants Pipeline",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: _text),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : _pipeline(),
    );
  }

  Widget _pipeline() {
    return ListView(
      padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 3.h),
      children: [
        const Text(
          "Drag a candidate card into another stage.",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        SizedBox(height: 1.4.h),
        SizedBox(
          height: 78.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stages.length,
            separatorBuilder: (_, __) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final s = _stages[index];
              final stageId = s['id'].toString();
              final stageName = (s['stage_name'] ?? 'Stage').toString();

              final items = _rowsForStage(stageId);

              return _stageColumn(
                stageId: stageId,
                title: stageName,
                count: items.length,
                items: items,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _stageColumn({
    required String stageId,
    required String title,
    required int count,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      width: 78.w,
      padding: EdgeInsets.fromLTRB(3.5.w, 1.4.h, 3.5.w, 1.2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                    color: _text,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _line),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.2.h),

          Expanded(
            child: DragTarget<Map<String, dynamic>>(
              onWillAccept: (data) => data != null,
              onAccept: (data) async {
                final listingRowId = data['id'].toString();
                final fromStageId =
                    (data['pipeline_stage_id'] ?? '').toString().trim();

                final actualFrom =
                    fromStageId.isEmpty ? _stages.first['id'].toString() : fromStageId;

                if (actualFrom == stageId) return;

                await _move(
                  listingRowId: listingRowId,
                  fromStageId: actualFrom,
                  toStageId: stageId,
                );
              },
              builder: (context, candidateData, rejectedData) {
                final highlight = candidateData.isNotEmpty;

                return Container(
                  decoration: BoxDecoration(
                    color: highlight
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: highlight ? const Color(0xFFBFDBFE) : _line,
                    ),
                  ),
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            "Drop here",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _muted.withOpacity(0.85),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final row = items[i];
                            return _draggableApplicantCard(row);
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _draggableApplicantCard(Map<String, dynamic> row) {
    return Draggable<Map<String, dynamic>>(
      data: row,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 70.w,
          child: Opacity(
            opacity: 0.92,
            child: _applicantCard(row, isDragging: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _applicantCard(row),
      ),
      child: _applicantCard(row),
    );
  }

  Widget _applicantCard(Map<String, dynamic> row, {bool isDragging = false}) {
    final app = (row['job_applications'] ?? {}) as Map<String, dynamic>;

    final name = (app['name'] ?? '').toString().trim().ifEmpty("Candidate");
    final phone = (app['phone'] ?? '').toString().trim();
    final email = (app['email'] ?? '').toString().trim();

    final resumeUrl = (app['resume_file_url'] ?? '').toString().trim();
    final photoUrl = (app['photo_file_url'] ?? '').toString().trim();

    final district = (app['district'] ?? '').toString().trim();
    final education = (app['education'] ?? '').toString().trim();
    final exp = (app['experience_level'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(photoUrl, name),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                    fontSize: 14.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (district.isNotEmpty) _pillText(district),
              if (education.isNotEmpty) _pillText(education),
              if (exp.isNotEmpty) _pillText(exp),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _miniAction(
                  icon: Icons.call_rounded,
                  label: "Call",
                  onTap: phone.isEmpty ? null : () => _call(phone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniAction(
                  icon: Icons.mail_rounded,
                  label: "Email",
                  onTap: email.isEmpty ? null : () => _email(email),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniAction(
                  icon: Icons.picture_as_pdf_rounded,
                  label: "Resume",
                  onTap: resumeUrl.isEmpty ? null : () => _openUrl(resumeUrl),
                ),
              ),
            ],
          ),
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
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: 42,
        height: 42,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 42,
          height: 42,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(14),
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

  Widget _miniAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled ? _line : const Color(0xFFDBEAFE),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: disabled ? const Color(0xFF94A3B8) : _primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.2,
                color: disabled ? const Color(0xFF94A3B8) : _primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillText(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF334155),
          fontSize: 12.3,
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(7.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 42, color: Color(0xFF9F1239)),
            const SizedBox(height: 14),
            Text(
              _error ?? "Failed",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          ],
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}