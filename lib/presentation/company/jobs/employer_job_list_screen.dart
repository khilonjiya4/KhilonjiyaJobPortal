// lib/presentation/company/jobs/employer_job_list_screen.dart
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../services/employer_jobs_service.dart';

class EmployerJobListScreen extends StatefulWidget {
  const EmployerJobListScreen({Key? key}) : super(key: key);

  @override
  State<EmployerJobListScreen> createState() => _EmployerJobListScreenState();
}

class _EmployerJobListScreenState extends State<EmployerJobListScreen> {
  final EmployerJobsService _service = EmployerJobsService();

  bool _loading = true;
  bool _refreshing = false;

  String _search = '';
  String _status = 'all';

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _jobs = [];

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) setState(() => _loading = true);
    if (silent) setState(() => _refreshing = true);

    try {
      final res = await _service.fetchEmployerJobs(
        search: _search,
        status: _status,
      );

      _jobs = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      _jobs = [];
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ------------------------------------------------------------
  // STATUS ACTIONS
  // ------------------------------------------------------------
  Future<void> _changeStatus({
    required String jobId,
    required String newStatus,
  }) async {
    try {
      await _service.updateJobStatus(jobId: jobId, newStatus: newStatus);
      _toast("Updated");
      await _load(silent: true);
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }
  }

  Future<void> _confirmAndChange({
    required String jobId,
    required String newStatus,
    required String title,
    required String body,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
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
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await _changeStatus(jobId: jobId, newStatus: newStatus);
  }

  // ------------------------------------------------------------
  // DELETE JOB
  // ------------------------------------------------------------
  Future<void> _deleteJob(String jobId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Job?"),
          content: const Text(
            "This will permanently delete the job listing.\n\n"
            "Warning: Applicants linked to this job may also be affected depending on DB constraints.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.deleteJob(jobId: jobId);
      _toast("Deleted");
      await _load(silent: true);
    } catch (e) {
      _toast("Failed: ${e.toString()}");
    }
  }

  // ------------------------------------------------------------
  // NAV (USE job.company_id)
  // ------------------------------------------------------------
  Future<void> _openApplicants({
    required String jobId,
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) {
      _toast("Organization missing for this job.");
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.jobApplicants,
      arguments: {
        'jobId': jobId,
        'companyId': companyId,
      },
    );

    await _load(silent: true);
  }

  Future<void> _openPipeline({
    required String jobId,
    required String companyId,
  }) async {
    if (companyId.trim().isEmpty) {
      _toast("Organization missing for this job.");
      return;
    }

    await Navigator.pushNamed(
      context,
      AppRoutes.jobApplicantsPipeline,
      arguments: {
        'jobId': jobId,
        'companyId': companyId,
      },
    );

    await _load(silent: true);
  }

  Future<void> _editJob(String jobId) async {
    final res = await Navigator.pushNamed(
      context,
      AppRoutes.createJob,
      arguments: {
        'mode': 'edit',
        'jobId': jobId,
      },
    );

    if (res == true) await _load(silent: true);
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
        elevation: 0.7,
        title: const Text("My Jobs"),
        foregroundColor: _text,
        actions: [
          TextButton(
            onPressed: _refreshing ? null : () => _load(silent: true),
            child: Text(
              _refreshing ? "Refreshing..." : "Refresh",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: _refreshing ? const Color(0xFF94A3B8) : _primary,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, AppRoutes.createJob);
          if (res == true) await _load(silent: true);
        },
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 1,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Post Job",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(silent: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                children: [
                  _searchBox(),
                  const SizedBox(height: 12),
                  _statusFilter(),
                  const SizedBox(height: 14),
                  _summaryRow(),
                  const SizedBox(height: 12),
                  if (_jobs.isEmpty)
                    _empty()
                  else
                    Column(
                      children: _jobs.map((j) => _jobCard(j)).toList(),
                    ),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // UI: SEARCH
  // ------------------------------------------------------------
  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: _muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _search = v,
              onSubmitted: (_) => _load(silent: true),
              decoration: const InputDecoration(
                hintText: "Search by job title",
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () async {
              _searchController.clear();
              _search = '';
              await _load(silent: true);
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close_rounded, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI: FILTER
  // ------------------------------------------------------------
  Widget _statusFilter() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip("All", "all"),
        _chip("Active", "active"),
        _chip("Paused", "paused"),
        _chip("Closed", "closed"),
        _chip("Expired", "expired"),
      ],
    );
  }

  Widget _chip(String label, String key) {
    final selected = _status == key;

    return InkWell(
      onTap: () async {
        setState(() => _status = key);
        await _load(silent: true);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFBFDBFE) : _border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? _primary : _text,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI: SUMMARY
  // ------------------------------------------------------------
  Widget _summaryRow() {
    final total = _jobs.length;
    final active = _jobs
        .where((j) => (j['status'] ?? 'active').toString() == 'active')
        .length;

    final applicants = _jobs.fold<int>(
      0,
      (sum, j) => sum + _service.toInt(j['applications_count']),
    );

    return Row(
      children: [
        Expanded(child: _miniMetric("Jobs", total.toString())),
        const SizedBox(width: 12),
        Expanded(child: _miniMetric("Active", active.toString())),
        const SizedBox(width: 12),
        Expanded(child: _miniMetric("Applicants", applicants.toString())),
      ],
    );
  }

  Widget _miniMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _muted,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _text,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI: EMPTY
  // ------------------------------------------------------------
  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(Icons.work_outline, size: 40, color: _muted),
          const SizedBox(height: 10),
          const Text(
            "No jobs found",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Try changing filters or post a new job.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // UI: JOB CARD
  // ------------------------------------------------------------
  Widget _jobCard(Map<String, dynamic> j) {
    final jobId = (j['id'] ?? '').toString();
    final companyId = (j['company_id'] ?? '').toString();

    final title = (j['job_title'] ?? 'Job').toString();
    final district = (j['district'] ?? '').toString();
    final jobType = (j['job_type'] ?? 'Full-time').toString();

    final status = (j['status'] ?? 'active').toString().toLowerCase();

    final salaryMin = _service.toInt(j['salary_min']);
    final salaryMax = _service.toInt(j['salary_max']);
    final salaryPeriod = (j['salary_period'] ?? 'Monthly').toString();

    final views = _service.toInt(j['views_count']);
    final apps = _service.toInt(j['applications_count']);

    final createdAt = j['created_at'];
    final expiresAt = j['expires_at'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + status
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(status),
            ],
          ),

          const SizedBox(height: 8),

          // location + type
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  district.isEmpty ? "Assam" : district,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              Text(
                jobType,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // salary
          Text(
            _salaryText(salaryMin, salaryMax, salaryPeriod),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),

          const SizedBox(height: 10),

          // views + apps
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$apps applicants",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Icon(Icons.visibility_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$views views",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // posted + expiry
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Posted: ${_timeAgo(createdAt)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  expiresAt == null ? "" : "Expires: ${_dateShort(expiresAt)}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 12),

          // primary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openApplicants(
                    jobId: jobId,
                    companyId: companyId,
                  ),
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text(
                    "Applicants",
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
                  onPressed: () => _openPipeline(
                    jobId: jobId,
                    companyId: companyId,
                  ),
                  icon: const Icon(Icons.view_kanban_outlined, size: 18),
                  label: const Text(
                    "Pipeline",
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

          // secondary actions (edit / delete)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editJob(jobId),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    "Edit",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _text,
                    backgroundColor: Colors.white,
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
                  onPressed: () => _deleteJob(jobId),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text(
                    "Delete",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    backgroundColor: const Color(0xFFFFF1F2),
                    side: const BorderSide(color: Color(0xFFFECACA)),
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

          // status actions
          _statusActions(jobId, status),
        ],
      ),
    );
  }

  Widget _statusActions(String jobId, String status) {
    final isActive = status == 'active';
    final isPaused = status == 'paused';
    final isClosed = status == 'closed';
    final isExpired = status == 'expired';

    if (isExpired) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _confirmAndChange(
            jobId: jobId,
            newStatus: 'active',
            title: "Reactivate Job?",
            body: "This will make the job visible again to job seekers.",
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
          child: const Text(
            "Reactivate",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    if (isClosed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _confirmAndChange(
            jobId: jobId,
            newStatus: 'active',
            title: "Reopen Job?",
            body: "This will reopen the job and allow new applications.",
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
          child: const Text(
            "Reopen Job",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isActive
                ? () => _confirmAndChange(
                      jobId: jobId,
                      newStatus: 'paused',
                      title: "Pause Job?",
                      body:
                          "Job will stop showing in feeds, but applicants remain.",
                    )
                : isPaused
                    ? () => _confirmAndChange(
                          jobId: jobId,
                          newStatus: 'active',
                          title: "Resume Job?",
                          body:
                              "Job will become visible again to job seekers.",
                        )
                    : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: _text,
              backgroundColor: const Color(0xFFF8FAFC),
              side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isActive ? "Pause" : "Resume",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmAndChange(
              jobId: jobId,
              newStatus: 'closed',
              title: "Close Job?",
              body: "This will stop applications unless reopened.",
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              backgroundColor: const Color(0xFFFFF1F2),
              side: const BorderSide(color: Color(0xFFFECACA)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Close",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;

    if (status == 'active') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Active';
    } else if (status == 'paused') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Paused';
    } else if (status == 'expired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      label = 'Expired';
    } else {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Closed';
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

  String _salaryText(int min, int max, String period) {
    if (min <= 0 && max <= 0) return "Salary not specified";
    if (min > 0 && max <= 0) return "₹$min / $period";
    if (min <= 0 && max > 0) return "Up to ₹$max / $period";
    if (min == max) return "₹$min / $period";
    return "₹$min - ₹$max / $period";
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

  String _dateShort(dynamic date) {
    final d = DateTime.tryParse(date.toString());
    if (d == null) return '';
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }
} // closes _EmployerJobListScreenState