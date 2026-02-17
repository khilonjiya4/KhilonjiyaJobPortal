import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobsBySalaryPage extends StatefulWidget {
  /// If provided, page will show jobs with salary >= this value
  /// Otherwise it will auto-load from user_profiles.expected_salary_min
  final int? minMonthlySalary;

  const JobsBySalaryPage({
    Key? key,
    this.minMonthlySalary,
  }) : super(key: key);

  @override
  State<JobsBySalaryPage> createState() => _JobsBySalaryPageState();
}

class _JobsBySalaryPageState extends State<JobsBySalaryPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingMore = false;
  bool _disposed = false;

  int _expectedSalary = 0;

  bool _hasMore = true;
  int _offset = 0;

  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _jobs = [];
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || !_hasMore) return;
    if (!_scrollController.hasClients) return;

    final pos = _scrollController.position;

    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  // ------------------------------------------------------------
  // LOAD: FIRST PAGE
  // ------------------------------------------------------------
  Future<void> _loadFirstPage() async {
    if (!_disposed) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _jobs = [];
        _hasMore = true;
        _offset = 0;
      });
    }

    // 1) saved jobs
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    // 2) salary source:
    //    - if passed from Home -> use it
    //    - else load from profile
    if (widget.minMonthlySalary != null && widget.minMonthlySalary! > 0) {
      _expectedSalary = widget.minMonthlySalary!;
    } else {
      try {
        _expectedSalary = await _homeService.getExpectedSalaryPerMonth();
      } catch (_) {
        _expectedSalary = 0;
      }
    }

    // 3) if salary not set -> no jobs
    if (_expectedSalary <= 0) {
      _jobs = [];
      if (!_disposed) setState(() => _loading = false);
      return;
    }

    // 4) fetch jobs (first page)
    try {
      final first = await _homeService.fetchJobsByMinSalaryMonthly(
        minMonthlySalary: _expectedSalary,
        offset: 0,
        limit: _pageSize,
      );

      _jobs = first;
      _offset = _jobs.length;
      _hasMore = first.length >= _pageSize;
    } catch (_) {
      _jobs = [];
      _hasMore = false;
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // LOAD: MORE
  // ------------------------------------------------------------
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final more = await _homeService.fetchJobsByMinSalaryMonthly(
        minMonthlySalary: _expectedSalary,
        offset: _offset,
        limit: _pageSize,
      );

      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _jobs.addAll(more);
        _offset = _jobs.length;

        if (more.length < _pageSize) {
          _hasMore = false;
        }
      }
    } catch (_) {
      _hasMore = false;
    }

    if (_disposed) return;
    setState(() => _loadingMore = false);
  }

  // ------------------------------------------------------------
  // SAVE / UNSAVE
  // ------------------------------------------------------------
  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _homeService.toggleSaveJob(jobId);

      if (_disposed) return;
      setState(() {
        isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update saved job")),
      );
    }
  }

  // ------------------------------------------------------------
  // JOB DETAILS
  // ------------------------------------------------------------
  Future<void> _openJobDetails(Map<String, dynamic> job) async {
    final jobId = job['id']?.toString() ?? '';
    if (jobId.trim().isEmpty) return;

    _homeService.trackJobView(jobId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(jobId),
          onSaveToggle: () => _toggleSaveJob(jobId),
        ),
      ),
    );

    // refresh saved state after coming back
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {}

    if (_disposed) return;
    setState(() {});
  }

  // ------------------------------------------------------------
  // EDIT SALARY (updates profile + refresh)
  // ------------------------------------------------------------
  int _parseSalary(String raw) {
    final clean = raw.trim().replaceAll(',', '');
    if (clean.isEmpty) return 0;
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _editExpectedSalary() async {
    final ctrl = TextEditingController(
      text: _expectedSalary <= 0 ? '' : _expectedSalary.toString(),
    );

    final res = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Expected salary (per month)",
                        style: KhilonjiyaUI.hTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "We will show jobs with salary equal to or higher than this.",
                  style: KhilonjiyaUI.sub,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    hintText: "Example: 15000",
                    hintStyle: KhilonjiyaUI.sub,
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: KhilonjiyaUI.primary.withOpacity(0.6),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      final v = _parseSalary(ctrl.text);
                      Navigator.pop(context, v);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KhilonjiyaUI.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Save & Refresh Jobs",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    if (res == null) return;

    final clean = res < 0 ? 0 : res;

    if (clean <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid salary amount")),
      );
      return;
    }

    try {
      await _homeService.updateExpectedSalaryPerMonth(clean);

      if (_disposed) return;

      setState(() => _expectedSalary = clean);
      await _loadFirstPage();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update expected salary")),
      );
    }
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  String _salaryText(int v) {
    if (v <= 0) return "Not set";
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L / month";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(0)}k / month";
    return "₹$v / month";
  }

  Widget _headerCard() {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: KhilonjiyaUI.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.currency_rupee_rounded,
              color: KhilonjiyaUI.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your expected salary", style: KhilonjiyaUI.caption),
                const SizedBox(height: 4),
                Text(
                  _salaryText(_expectedSalary),
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Showing jobs with salary ≥ this amount",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _editExpectedSalary,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: Text(
                "Edit",
                style: KhilonjiyaUI.body.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        _headerCard(),
        const SizedBox(height: 14),
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.search_rounded,
                size: 46,
                color: Colors.black.withOpacity(0.35),
              ),
              const SizedBox(height: 12),
              Text(
                _expectedSalary <= 0
                    ? "Set your expected salary"
                    : "No matching jobs found",
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _expectedSalary <= 0
                    ? "Add expected salary to see jobs with salary equal or higher."
                    : "Try lowering expected salary or check later.",
                style: KhilonjiyaUI.sub,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _editExpectedSalary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhilonjiyaUI.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _expectedSalary <= 0 ? "Set Salary" : "Update Salary",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jobsList() {
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _jobs.length + 2,
        itemBuilder: (_, i) {
          // header
          if (i == 0) {
            return Column(
              children: [
                _headerCard(),
                const SizedBox(height: 14),
              ],
            );
          }

          // bottom loader
          if (i == _jobs.length + 1) {
            if (!_hasMore) return const SizedBox(height: 30);

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: _loadingMore
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    : const SizedBox(height: 10),
              ),
            );
          }

          final job = _jobs[i - 1];
          final jobId = job['id']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: JobCardWidget(
              job: job,
              isSaved: _savedJobIds.contains(jobId),
              onSaveToggle: () => _toggleSaveJob(jobId),
              onTap: () => _openJobDetails(job),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Jobs by salary",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadFirstPage,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_jobs.isEmpty ? _emptyState() : _jobsList()),
            ),
          ],
        ),
      ),
    );
  }
}