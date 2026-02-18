// lib/presentation/company/jobs/job_applicants_pipeline_page.dart
import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
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

  bool _loading = true;
  bool _moving = false;

  List<Map<String, dynamic>> _stages = [];
  List<Map<String, dynamic>> _rows = [];

  // stageId -> listing rows
  final Map<String, List<Map<String, dynamic>>> _stageBuckets = {};

  // UI
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      await _service.ensureJobOwner(widget.jobId);

      _stages = await _service.getCompanyPipelineStages(
        companyId: widget.companyId,
      );

      // Ensure at least 1 stage
      if (_stages.isEmpty) {
        // fallback virtual stage
        _stages = [
          {
            'id': 'applied',
            'stage_name': 'Applied',
            'stage_order': 1,
            'is_default': true,
          }
        ];
      }

      _rows = await _service.fetchApplicantsForJob(widget.jobId);

      _rebuildBuckets();
    } catch (e) {
      _stages = [];
      _rows = [];
      _stageBuckets.clear();
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _rebuildBuckets() {
    _stageBuckets.clear();

    // init empty
    for (final s in _stages) {
      final id = (s['id'] ?? '').toString();
      if (id.trim().isEmpty) continue;
      _stageBuckets[id] = [];
    }

    // Put rows into stage based on employer_notes tag
    for (final r in _rows) {
      final notes = r['employer_notes'];
      final stageId = _service.extractStageId(notes);

      String finalStageId = stageId;

      if (finalStageId.trim().isEmpty) {
        // default stage
        final def = _stages.firstWhere(
          (x) => x['is_default'] == true,
          orElse: () => _stages.first,
        );
        finalStageId = (def['id'] ?? '').toString();
      }

      if (_stageBuckets[finalStageId] == null) {
        // stage not found -> push to first stage
        finalStageId = (_stages.first['id'] ?? '').toString();
      }

      _stageBuckets[finalStageId]!.add(r);
    }
  }

  // ------------------------------------------------------------
  // MOVE APPLICANT
  // ------------------------------------------------------------
  Future<void> _moveToStage({
    required Map<String, dynamic> row,
    required String toStageId,
  }) async {
    if (_moving) return;

    final listingRowId = (row['id'] ?? '').toString();
    if (listingRowId.trim().isEmpty) return;

    setState(() => _moving = true);

    try {
      await _service.moveApplicantToStage(
        listingRowId: listingRowId,
        jobId: widget.jobId,
        toStageId: toStageId,
      );

      // Update local row notes
      final existingNotes = (row['employer_notes'] ?? '').toString();
      final updatedNotes =
          '[pipeline_stage_id:$toStageId]\n$existingNotes'.trim();

      row['employer_notes'] = updatedNotes;

      _rebuildBuckets();
      setState(() {});
    } catch (e) {
      _toast("Move failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _moving = false);
  }

  // ------------------------------------------------------------
  // OPEN APPLICANT DETAILS
  // ------------------------------------------------------------
  void _openApplicant(Map<String, dynamic> row) {
    final app = (row['job_applications'] ?? {}) as Map;

    final name = (app['name'] ?? 'Candidate').toString();
    final phone = (app['phone'] ?? '').toString();
    final email = (app['email'] ?? '').toString();
    final district = (app['district'] ?? '').toString();
    final edu = (app['education'] ?? '').toString();
    final exp = (app['experience_level'] ?? '').toString();
    final skills = (app['skills'] ?? '').toString();
    final salary = (app['expected_salary'] ?? '').toString();

    final resume = (app['resume_file_url'] ?? '').toString();
    final photo = (app['photo_file_url'] ?? '').toString();

    final notes = (row['employer_notes'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _avatar(name, photo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: _text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _kv("Phone", phone.isEmpty ? "Not provided" : phone),
                  _kv("Email", email.isEmpty ? "Not provided" : email),
                  _kv("District", district.isEmpty ? "Not provided" : district),
                  _kv("Education", edu.isEmpty ? "Not provided" : edu),
                  _kv("Experience", exp.isEmpty ? "Not provided" : exp),
                  _kv("Expected Salary",
                      salary.isEmpty ? "Not provided" : salary),

                  const SizedBox(height: 12),

                  Text(
                    "Skills",
                    style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    skills.isEmpty ? "Not provided" : skills,
                    style: KhilonjiyaUI.body.copyWith(
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: resume.isEmpty
                              ? null
                              : () {
                                  _toast("Resume open will be added next");
                                },
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text(
                            "Resume",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _text,
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: const BorderSide(color: _border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editNotes(row, notes),
                          icon: const Icon(Icons.edit_note_rounded, size: 20),
                          label: const Text(
                            "Notes",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    "Move to Stage",
                    style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _stages.map((s) {
                      final id = (s['id'] ?? '').toString();
                      final stageName = (s['stage_name'] ?? '').toString();

                      return InkWell(
                        onTap: _moving
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _moveToStage(row: row, toStageId: id);
                              },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _border),
                          ),
                          child: Text(
                            stageName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _text,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // EDIT NOTES (REAL)
  // ------------------------------------------------------------
  Future<void> _editNotes(Map<String, dynamic> row, String existing) async {
    final c = TextEditingController(text: existing);

    final listingRowId = (row['id'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Employer Notes"),
          content: TextField(
            controller: c,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Write private notes for your team...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.updateEmployerNotes(
        listingRowId: listingRowId,
        jobId: widget.jobId,
        notes: c.text.trim(),
      );

      row['employer_notes'] = c.text.trim();
      _rebuildBuckets();
      setState(() {});
      _toast("Saved");
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _text,
        elevation: 0.7,
        title: const Text("Applicants Pipeline"),
        actions: [
          IconButton(
            onPressed: _moving ? null : _loadAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stages.isEmpty
              ? Center(
                  child: Text(
                    "No pipeline stages found.",
                    style: KhilonjiyaUI.body,
                  ),
                )
              : _buildBoard(),
    );
  }

  Widget _buildBoard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        if (_moving)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Updating pipeline...",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_moving) const SizedBox(height: 12),

        // Horizontal board
        SizedBox(
          height: MediaQuery.of(context).size.height - 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final stage = _stages[i];
              final stageId = (stage['id'] ?? '').toString();
              final stageName = (stage['stage_name'] ?? '').toString();

              final list = _stageBuckets[stageId] ?? [];

              return SizedBox(
                width: 320,
                child: _stageColumn(
                  stageId: stageId,
                  stageName: stageName,
                  rows: list,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _stageColumn({
    required String stageId,
    required String stageName,
    required List<Map<String, dynamic>> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(
                  stageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  rows.length.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),

          if (rows.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  "No applicants",
                  style: KhilonjiyaUI.sub.copyWith(color: _muted),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (_, i) => _applicantCard(rows[i], stageId),
              ),
            ),
        ],
      ),
    );
  }

  Widget _applicantCard(Map<String, dynamic> row, String currentStageId) {
    final app = (row['job_applications'] ?? {}) as Map;

    final name = (app['name'] ?? 'Candidate').toString();
    final district = (app['district'] ?? '').toString();
    final exp = (app['experience_level'] ?? '').toString();
    final salary = (app['expected_salary'] ?? '').toString();

    final photo = (app['photo_file_url'] ?? '').toString();

    return InkWell(
      onTap: () => _openApplicant(row),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(name, photo, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (toStageId) async {
                    if (toStageId == currentStageId) return;
                    await _moveToStage(row: row, toStageId: toStageId);
                  },
                  itemBuilder: (_) {
                    return _stages.map((s) {
                      final id = (s['id'] ?? '').toString();
                      final stageName = (s['stage_name'] ?? '').toString();

                      return PopupMenuItem(
                        value: id,
                        child: Text(stageName),
                      );
                    }).toList();
                  },
                  child: const Icon(Icons.more_vert_rounded, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (district.isNotEmpty)
              _miniRow(Icons.location_on_outlined, district),

            if (exp.isNotEmpty)
              _miniRow(Icons.timeline_outlined, exp),

            if (salary.isNotEmpty)
              _miniRow(Icons.currency_rupee_rounded, salary),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
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
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String name, String photoUrl, {double size = 52}) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "C";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
          color: _primary,
        ),
      ),
    );
  }
}