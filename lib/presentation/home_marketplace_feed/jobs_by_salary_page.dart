import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobsBySalaryPage extends StatefulWidget {
  /// Optional: if passed, page will auto-run once using this salary
  /// BUT we still will not save anything to DB.
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

  bool _loading = false;
  bool _loadingMore = false;
  bool _disposed = false;

  bool _hasMore = true;
  int _offset = 0;

  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _jobs = [];
  Set<String> _savedJobIds = {};

  // salary input (always blank initially)
  final TextEditingController _salaryCtrl = TextEditingController();

  // current active salary filter
  int _activeSalary = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // If passed from previous screen, auto-run once
    if (widget.minMonthlySalary != null && widget.minMonthlySalary! > 0) {
      _activeSalary = widget.minMonthlySalary!;
      _salaryCtrl.text = _activeSalary.toString();
      _loadFirstPage();
    } else {
      _loadSavedJobsOnly();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    _salaryCtrl.dispose();
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

  int _parseSalary(String raw) {
    final clean = raw.trim().replaceAll(',', '');
    if (clean.isEmpty) return 0;
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _loadSavedJobsOnly() async {
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    if (_disposed) return;
    setState(() {});
  }

  // ------------------------------------------------------------
  // APPLY FILTER (user clicks button)
  // ------------------------------------------------------------
  Future<void> _applySalaryFilter() async {
    final v = _parseSalary(_salaryCtrl.text);

    if (v <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid salary amount")),
      );
      return;
    }

    _activeSalary = v;
    await _loadFirstPage();
  }

  // ------------------------------------------------------------
  // LOAD FIRST PAGE
  // ------------------------------------------------------------
  Future<void> _loadFirstPage() async {
    if (_activeSalary <= 0) return;

    if (_disposed) return;

    setState(() {
      _loading = true;
      _loadingMore = false;
      _jobs = [];
      _hasMore = true;
      _offset = 0;
    });

    // saved jobs
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    // first page
    try {
      final first = await _homeService.fetchJobsByMinSalaryMonthly(
        minMonthlySalary: _activeSalary,
        offset: 0,
        limit: _pageSize,
      );

      if (_disposed) return;

      setState(() {
        _jobs = first;
        _offset = _jobs.length;
        _hasMore = first.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (_disposed) return;

      setState(() {
        _jobs = [];
        _hasMore = false;
        _loading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // LOAD MORE
  // ------------------------------------------------------------
  Future<void> _loadMore() async {
    if (_activeSalary <= 0) return;
    if (_loadingMore || !_hasMore) return;
    if (_disposed) return;

    setState(() => _loadingMore = true);

    try {
      final more = await _homeService.fetchJobsByMinSalaryMonthly(
        minMonthlySalary: _activeSalary,
        offset: _offset,
        limit: _pageSize,
      );

      if (_disposed) return;

      setState(() {
        if (more.isEmpty) {
          _hasMore = false;
        } else {
          _jobs.addAll(more);
          _offset = _jobs.length;

          if (more.length < _pageSize) {
            _hasMore = false;
          }
        }
      });
    } catch (_) {
      if (_disposed) return;
      setState(() => _hasMore = false);
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
    } catch (_) {}
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

    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {}

    if (_disposed) return;
    setState(() {});
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  Widget _salaryInputCard() {
    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Filter by salary", style: KhilonjiyaUI.hTitle),
          const SizedBox(height: 6),
          Text(
            "Enter expected monthly salary. We will show jobs with salary ≥ this amount.",
            style: KhilonjiyaUI.sub,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _salaryCtrl,
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
              onPressed: _loading ? null : _applySalaryFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                "Show Jobs",
                style: TextStyle(fontWeight: FontWeight.w900),
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
        _salaryInputCard(),
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
                _activeSalary <= 0
                    ? "Enter salary to see jobs"
                    : "No matching jobs found",
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _activeSalary <= 0
                    ? "Add expected salary to fetch matching jobs."
                    : "Try a lower salary amount.",
                style: KhilonjiyaUI.sub,
                textAlign: TextAlign.center,
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
                _salaryInputCard(),
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
                    onPressed: _loading ? null : _loadFirstPage,
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