// lib/presentation/company/jobs/job_applicants_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../services/employer_applicants_service.dart';

class JobApplicantsScreen extends StatefulWidget {
  final String jobId;

  // Optional: can be passed from route
  // But we always resolve from job_listings for correctness.
  final String? companyId;

  const JobApplicantsScreen({
    Key? key,
    required this.jobId,
    this.companyId,
  }) : super(key: key);

  @override
  State<JobApplicantsScreen> createState() => _JobApplicantsScreenState();
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  final EmployerApplicantsService _service = EmployerApplicantsService();

  bool _loading = true;
  bool _busy = false;

  List<Map<String, dynamic>> _rows = [];

  // Resolved from job
  String _resolvedCompanyId = '';
  String _jobTitle = '';

  // Filters
  String _filter = 'all';
  final TextEditingController _search = TextEditingController();

  // UI tokens
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final job = await _service.ensureJobOwnerAndGetJob(widget.jobId);

      _resolvedCompanyId = (job['company_id'] ?? '').toString().trim();
      _jobTitle = (job['job_title'] ?? '').toString().trim();

      // fallback if passed
      if (_resolvedCompanyId.isEmpty && widget.companyId != null) {
        _resolvedCompanyId = widget.companyId!.trim();
      }

      _rows = await _service.fetchApplicantsForJob(widget.jobId);
    } catch (e) {
      _rows = [];
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // FILTERING
  // ------------------------------------------------------------
  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();

    return _rows.where((r) {
      final status = (r['application_status'] ?? 'applied')
          .toString()
          .toLowerCase();

      if (_filter != 'all' && status != _filter) return false;

      if (q.isEmpty) return true;

      final app = _asMap(r['job_applications']);

      final name = (app['name'] ?? '').toString().toLowerCase();
      final phone = (app['phone'] ?? '').toString().toLowerCase();
      final email = (app['email'] ?? '').toString().toLowerCase();
      final skills = (app['skills'] ?? '').toString().toLowerCase();

      return name.contains(q) ||
          phone.contains(q) ||
          email.contains(q) ||
          skills.contains(q);
    }).toList();
  }

  // ------------------------------------------------------------
  // ACTIONS
  // ------------------------------------------------------------
  Future<void> _setStatus(Map<String, dynamic> row, String status) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _service.updateApplicationStatus(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
        status: status,
      );

      row['application_status'] = status;
      if (mounted) setState(() {});
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _scheduleInterview(Map<String, dynamic> row) async {
    if (_resolvedCompanyId.trim().isEmpty) {
      _toast("Organization not linked to job. Please contact support.");
      return;
    }

    final picked = await _pickDateTime();
    if (picked == null) return;

    if (_busy) return;
    setState(() => _busy = true);

    try {
      await _service.scheduleInterview(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
        companyId: _resolvedCompanyId,
        scheduledAt: picked,
        durationMinutes: 30,
        interviewType: 'video',
      );

      row['application_status'] = 'interview_scheduled';
      row['interview_date'] = picked.toIso8601String();

      if (mounted) setState(() {});
      _toast("Interview scheduled");
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<DateTime?> _pickDateTime() async {
    final now = DateTime.now();

    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (d == null) return null;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (t == null) return null;

    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  // ------------------------------------------------------------
  // MARK VIEWED
  // ------------------------------------------------------------
  Future<void> _markViewedIfNeeded(Map<String, dynamic> row) async {
    final status =
        (row['application_status'] ?? 'applied').toString().toLowerCase();

    if (status != 'applied') return;

    try {
      await _service.markViewed(
        listingRowId: (row['id'] ?? '').toString(),
        jobId: widget.jobId,
      );
      row['application_status'] = 'viewed';
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // NOTES (REAL)
  // ------------------------------------------------------------
  Future<void> _editNotes(Map<String, dynamic> row) async {
    final listingRowId = (row['id'] ?? '').toString();
    final existing = (row['employer_notes'] ?? '').toString();

    final c = TextEditingController(text: existing);

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
      if (mounted) setState(() {});
      _toast("Saved");
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }
  }

  // ------------------------------------------------------------
  // OPEN RESUME (REAL)
  // ------------------------------------------------------------
  Future<void> _openResume(Map<String, dynamic> row) async {
    final app = _asMap(row['job_applications']);
    final url = (app['resume_file_url'] ?? '').toString().trim();

    if (url.isEmpty) {
      _toast("Resume not uploaded");
      return;
    }

    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast("Cannot open resume");
    } catch (e) {
      _toast("Cannot open resume: ${e.toString()}");
    }
  }

  // ------------------------------------------------------------
  // DETAILS SHEET
  // ------------------------------------------------------------
  void _openApplicant(Map<String, dynamic> row) async {
    await _markViewedIfNeeded(row);

    final app = _asMap(row['job_applications']);

    final name = (app['name'] ?? 'Candidate').toString();
    final phone = (app['phone'] ?? '').toString();
    final email = (app['email'] ?? '').toString();
    final district = (app['district'] ?? '').toString();
    final edu = (app['education'] ?? '').toString();
    final exp = (app['experience_level'] ?? '').toString();
    final skills = (app['skills'] ?? '').toString();
    final salary = (app['expected_salary'] ?? '').toString();
    final notes = (row['employer_notes'] ?? '').toString();

    final status =
        (row['application_status'] ?? 'applied').toString().toLowerCase();

    final interviewDate = row['interview_date'];

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
                      _avatar(name),
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
                  const SizedBox(height: 12),
                  _statusChip(status),
                  const SizedBox(height: 12),
                  _kv("Phone", phone.isEmpty ? "Not provided" : phone),
                  _kv("Email", email.isEmpty ? "Not provided" : email),
                  _kv("District", district.isEmpty ? "Not provided" : district),
                  _kv("Education", edu.isEmpty ? "Not provided" : edu),
                  _kv("Experience", exp.isEmpty ? "Not provided" : exp),
                  _kv(
                    "Expected Salary",
                    salary.isEmpty ? "Not provided" : salary,
                  ),
                  if (interviewDate != null)
                    _kv("Interview", _formatDateTime(interviewDate)),
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
                  Text(
                    "Employer Notes",
                    style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      notes.trim().isEmpty ? "No notes yet." : notes,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _text,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _openResume(row);
                                },
                          icon: const Icon(Icons.description_outlined),
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
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _editNotes(row);
                                },
                          icon: const Icon(Icons.edit_note_rounded),
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

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _scheduleInterview(row);
                                },
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: const Text(
                            "Schedule",
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _setStatus(row, 'shortlisted');
                                },
                          icon: const Icon(Icons.star_border_rounded),
                          label: const Text(
                            "Shortlist",
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
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _setStatus(row, 'selected');
                                },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            "Select",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF166534),
                            backgroundColor: const Color(0xFFECFDF5),
                            side: const BorderSide(color: Color(0xFFBBF7D0)),
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
                          onPressed: _busy
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  await _setStatus(row, 'rejected');
                                },
                          icon: const Icon(Icons.block_outlined),
                          label: const Text(
                            "Reject",
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9F1239),
                            backgroundColor: const Color(0xFFFFF1F2),
                            side: const BorderSide(color: Color(0xFFFDA4AF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
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
        title: const Text("Applicants"),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(34),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              _jobTitle.isEmpty ? "Job Applicants" : _jobTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _topFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _emptyCard(),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final row = _filtered[i];
                              return _applicantTile(row);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  // ------------------------------------------------------------
  // UI: FILTERS
  // ------------------------------------------------------------
  Widget _topFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: "Search name, phone, email, skills...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_search.text.trim().isNotEmpty)
                  InkWell(
                    onTap: () {
                      _search.clear();
                      setState(() {});
                    },
                    child: const Icon(Icons.close_rounded, color: _muted),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip("All", "all"),
                _filterChip("Applied", "applied"),
                _filterChip("Viewed", "viewed"),
                _filterChip("Shortlisted", "shortlisted"),
                _filterChip("Interview", "interview_scheduled"),
                _filterChip("Selected", "selected"),
                _filterChip("Rejected", "rejected"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String key) {
    final active = _filter == key;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => setState(() => _filter = key),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? const Color(0xFFBFDBFE) : _border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: active ? _primary : _text,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI: LIST ITEM
  // ------------------------------------------------------------
  Widget _applicantTile(Map<String, dynamic> row) {
    final app = _asMap(row['job_applications']);

    final name = (app['name'] ?? 'Candidate').toString();
    final district = (app['district'] ?? '').toString();
    final exp = (app['experience_level'] ?? '').toString();
    final salary = (app['expected_salary'] ?? '').toString();

    final status =
        (row['application_status'] ?? 'applied').toString().toLowerCase();

    final appliedAt = row['applied_at'];
    final interviewAt = row['interview_date'];

    return InkWell(
      onTap: () => _openApplicant(row),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _avatar(name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appliedAt == null
                            ? "Recently applied"
                            : "Applied ${_timeAgo(appliedAt)}",
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                      if (status == 'interview_scheduled' && interviewAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Interview: ${_formatDateTime(interviewAt)}",
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7C2D12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _mini(Icons.location_on_outlined,
                      district.isEmpty ? "Assam" : district),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mini(Icons.timeline_outlined,
                      exp.isEmpty ? "Experience: -" : exp),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _mini(Icons.currency_rupee_rounded,
                salary.isEmpty ? "Expected salary: -" : salary),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String text) {
    return Row(
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
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();

    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    String label = 'Applied';

    if (s == 'viewed') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF334155);
      label = 'Viewed';
    } else if (s == 'shortlisted') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Shortlisted';
    } else if (s == 'interview_scheduled') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interview';
    } else if (s == 'interviewed') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interviewed';
    } else if (s == 'selected') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF14532D);
      label = 'Selected';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
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

  Widget _avatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "C";

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: _primary,
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.people_outline, color: _text),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No applicants found",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "When candidates apply, they will appear here.",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'recent';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recent';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  String _formatDateTime(dynamic date) {
    final d = DateTime.tryParse(date.toString());
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return "$dd/$mm/$yy $hh:$mi";
  }
}