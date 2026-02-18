// File: lib/presentation/company/jobs/employer_job_list_screen.dart

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';

class EmployerJobListScreen extends StatefulWidget {
  const EmployerJobListScreen({Key? key}) : super(key: key);

  @override
  State<EmployerJobListScreen> createState() => _EmployerJobListScreenState();
}

class _EmployerJobListScreenState extends State<EmployerJobListScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _jobs = [];

  // UI state
  final TextEditingController _searchCtrl = TextEditingController();

  String _statusFilter = 'all'; // all, active, paused, closed, expired
  String _sort = 'newest'; // newest, oldest, most_apps, most_views

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
    _loadJobs();
    _searchCtrl.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = "Session expired. Please login again.";
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final res = await _client
          .from('job_listings')
          .select('''
            id,
            company_id,
            job_title,
            district,
            job_type,
            salary_min,
            salary_max,
            salary_period,
            status,
            created_at,
            applications_count,
            views_count
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _jobs = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Failed to load jobs";
      });
    }
  }

  // ------------------------------------------------------------
  // FILTERED LIST
  // ------------------------------------------------------------
  List<Map<String, dynamic>> get _filteredJobs {
    final q = _searchCtrl.text.trim().toLowerCase();

    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(_jobs);

    // Status filter
    if (_statusFilter != 'all') {
      items = items.where((j) {
        final s = (j['status'] ?? 'active').toString().toLowerCase();
        return s == _statusFilter;
      }).toList();
    }

    // Search
    if (q.isNotEmpty) {
      items = items.where((j) {
        final title = (j['job_title'] ?? '').toString().toLowerCase();
        final district = (j['district'] ?? '').toString().toLowerCase();
        final jobType = (j['job_type'] ?? '').toString().toLowerCase();
        return title.contains(q) || district.contains(q) || jobType.contains(q);
      }).toList();
    }

    // Sort
    if (_sort == 'oldest') {
      items.sort((a, b) => _date(a['created_at']).compareTo(_date(b['created_at'])));
    } else if (_sort == 'most_apps') {
      items.sort((a, b) => _toInt(b['applications_count']).compareTo(_toInt(a['applications_count'])));
    } else if (_sort == 'most_views') {
      items.sort((a, b) => _toInt(b['views_count']).compareTo(_toInt(a['views_count'])));
    } else {
      // newest default
      items.sort((a, b) => _date(b['created_at']).compareTo(_date(a['created_at'])));
    }

    return items;
  }

  DateTime _date(dynamic v) {
    final d = DateTime.tryParse((v ?? '').toString());
    return d ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredJobs;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        titleSpacing: 4.w,
        title: const Text(
          'My Jobs',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: _text),
        actions: [
          IconButton(
            onPressed: _loadJobs,
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh_rounded),
          ),
          SizedBox(width: 1.w),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _loadJobs,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 12.h),
                    children: [
                      _headerCard(),
                      SizedBox(height: 2.2.h),

                      _searchAndSortRow(),
                      SizedBox(height: 1.4.h),

                      _statusFilters(),
                      SizedBox(height: 2.0.h),

                      if (_jobs.isEmpty) _emptyState(),

                      if (_jobs.isNotEmpty && filtered.isEmpty)
                        _noResultsState(),

                      if (filtered.isNotEmpty) ...[
                        _listSummary(filtered.length),
                        SizedBox(height: 1.2.h),
                        ...filtered.map(_jobCard).toList(),
                      ],
                    ],
                  ),
                ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, AppRoutes.createJob);
          if (res == true) await _loadJobs();
        },
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 1.5,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Create Job",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP HEADER CARD
  // ------------------------------------------------------------
  Widget _headerCard() {
    final total = _jobs.length;
    final active = _jobs
        .where((j) => (j['status'] ?? 'active').toString().toLowerCase() == 'active')
        .length;

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.0.h, 4.w, 2.0.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Manage your job posts",
                  style: TextStyle(
                    fontSize: 15.5,
                    color: _text,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$active active • $total total",
                  style: const TextStyle(
                    fontSize: 12.6,
                    color: _muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SEARCH + SORT
  // ------------------------------------------------------------
  Widget _searchAndSortRow() {
    return Row(
      children: [
        Expanded(child: _searchBox()),
        SizedBox(width: 3.w),
        _sortButton(),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _text,
      ),
      decoration: InputDecoration(
        hintText: "Search jobs, district, type...",
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchCtrl.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDBEAFE), width: 1.4),
        ),
      ),
    );
  }

  Widget _sortButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _openSortSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _line),
        ),
        child: const Icon(Icons.tune_rounded, color: _text),
      ),
    );
  }

  Future<void> _openSortSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 3.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Sort by",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                ),
                SizedBox(height: 1.6.h),
                _sortTile("Newest first", "newest"),
                _sortTile("Oldest first", "oldest"),
                _sortTile("Most applicants", "most_apps"),
                _sortTile("Most views", "most_views"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sortTile(String label, String key) {
    final selected = _sort == key;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
        color: selected ? _primary : const Color(0xFF94A3B8),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? _text : const Color(0xFF334155),
        ),
      ),
      onTap: () {
        setState(() => _sort = key);
        Navigator.pop(context);
      },
    );
  }

  // ------------------------------------------------------------
  // STATUS FILTERS
  // ------------------------------------------------------------
  Widget _statusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _chip("All", "all"),
          _chip("Active", "active"),
          _chip("Paused", "paused"),
          _chip("Closed", "closed"),
          _chip("Expired", "expired"),
        ],
      ),
    );
  }

  Widget _chip(String label, String key) {
    final selected = _statusFilter == key;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _statusFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? const Color(0xFFDBEAFE) : _line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? _primary : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY
  // ------------------------------------------------------------
  Widget _listSummary(int count) {
    return Text(
      "$count jobs",
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: _muted,
      ),
    );
  }

  // ------------------------------------------------------------
  // JOB CARD
  // ------------------------------------------------------------
  Widget _jobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final companyId = (job['company_id'] ?? '').toString();

    final title = (job['job_title'] ?? '').toString();
    final district = (job['district'] ?? '').toString();
    final jobType = (job['job_type'] ?? '').toString();
    final status = (job['status'] ?? 'active').toString();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final salaryPeriod = (job['salary_period'] ?? 'Monthly').toString();

    // safe
    final apps = _toInt(job['applications_count']);
    final views = _toInt(job['views_count']);

    final createdAt = job['created_at'];

    final salaryText = _salaryText(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      period: salaryPeriod,
    );

    final statusUi = _statusUi(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
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
          // TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "Untitled job" : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.8,
                        fontWeight: FontWeight.w800,
                        color: _text,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Posted ${_timeAgo(createdAt)}",
                      style: const TextStyle(
                        fontSize: 12.4,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _statusChip(statusUi.label, statusUi.bg, statusUi.fg),
            ],
          ),

          SizedBox(height: 1.6.h),

          // META
          if (district.trim().isNotEmpty)
            _metaRow(Icons.location_on_rounded, district),

          if (district.trim().isNotEmpty) SizedBox(height: 0.8.h),

          _metaRow(Icons.currency_rupee_rounded, salaryText),

          SizedBox(height: 1.2.h),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _smallPill(
                icon: Icons.badge_outlined,
                text: jobType.isEmpty ? "Job" : jobType,
              ),
              _smallPill(
                icon: Icons.people_alt_outlined,
                text: "$apps applicants",
              ),
              _smallPill(
                icon: Icons.visibility_outlined,
                text: "$views views",
              ),
            ],
          ),

          SizedBox(height: 1.6.h),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          SizedBox(height: 1.6.h),

          // ACTIONS (Applicants + Pipeline + Edit)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: jobId.trim().isEmpty
                      ? null
                      : () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.jobApplicants,
                            arguments: jobId,
                          );
                          await _loadJobs();
                        },
                  icon: const Icon(Icons.people_alt_outlined, size: 18),
                  label: const Text(
                    "Applicants",
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
              SizedBox(width: 2.6.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (jobId.trim().isEmpty || companyId.trim().isEmpty)
                      ? null
                      : () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.jobApplicantsPipeline,
                            arguments: {
                              "jobId": jobId,
                              "companyId": companyId,
                            },
                          );
                          await _loadJobs();
                        },
                  icon: const Icon(Icons.account_tree_outlined, size: 18),
                  label: const Text(
                    "Pipeline",
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
              SizedBox(width: 2.6.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Edit Job screen coming next"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    "Edit",
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
      ),
    );
  }

  // ------------------------------------------------------------
  // UI PARTS
  // ------------------------------------------------------------
  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallPill({required IconData icon, required String text}) {
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

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.10)),
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
  // STATUS UI
  // ------------------------------------------------------------
  _StatusUI _statusUi(String status) {
    final s = status.toLowerCase();

    if (s == 'active') {
      return _StatusUI(
        label: "Active",
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF14532D),
      );
    }
    if (s == 'paused') {
      return _StatusUI(
        label: "Paused",
        bg: const Color(0xFFFFFBEB),
        fg: const Color(0xFF7C2D12),
      );
    }
    if (s == 'expired') {
      return _StatusUI(
        label: "Expired",
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF475569),
      );
    }

    return _StatusUI(
      label: "Closed",
      bg: const Color(0xFFFFF1F2),
      fg: const Color(0xFF9F1239),
    );
  }

  // ------------------------------------------------------------
  // TEXT HELPERS
  // ------------------------------------------------------------
  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
    required String period,
  }) {
    final min = int.tryParse((salaryMin ?? '').toString());
    final max = int.tryParse((salaryMax ?? '').toString());

    if (min == null || max == null) return "Salary not disclosed";

    final per = period.isEmpty ? "Monthly" : period;
    return "₹$min - ₹$max / $per";
  }

  String _timeAgo(dynamic date) {
    if (date == null) return "recently";

    final d = DateTime.tryParse(date.toString());
    if (d == null) return "recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "1 day ago";
    return "${diff.inDays} days ago";
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ------------------------------------------------------------
  // EMPTY / ERROR
  // ------------------------------------------------------------
  Widget _noResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 7.h),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 2.4.h),
            const Text(
              'No results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _text,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Try changing filters or search keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 7.h),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                size: 34,
                color: Color(0xFF334155),
              ),
            ),
            SizedBox(height: 2.4.h),
            const Text(
              'No jobs posted yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _text,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Create your first job to start hiring.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
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
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFF9F1239),
              ),
            ),
            SizedBox(height: 2.4.h),
            Text(
              _error ?? "Something went wrong",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            SizedBox(height: 1.8.h),
            OutlinedButton.icon(
              onPressed: _loadJobs,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                "Try Again",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _line),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusUI {
  final String label;
  final Color bg;
  final Color fg;

  _StatusUI({
    required this.label,
    required this.bg,
    required this.fg,
  });
}