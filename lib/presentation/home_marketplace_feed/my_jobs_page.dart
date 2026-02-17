import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({Key? key}) : super(key: key);

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingMore = false;
  bool _disposed = false;

  bool _hasMore = true;
  int _offset = 0;

  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _appliedJobs = [];
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

  // ============================================================
  // LOAD: FIRST PAGE
  // ============================================================
  Future<void> _loadFirstPage() async {
    if (_disposed) return;

    setState(() {
      _loading = true;
      _loadingMore = false;
      _appliedJobs = [];
      _hasMore = true;
      _offset = 0;
    });

    // 1) saved jobs
    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    // 2) applied jobs first page
    try {
      final first = await _homeService.fetchAppliedJobs(
        offset: 0,
        limit: _pageSize,
      );

      _appliedJobs = first;
      _offset = _appliedJobs.length;
      _hasMore = first.length >= _pageSize;
    } catch (_) {
      _appliedJobs = [];
      _hasMore = false;
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ============================================================
  // LOAD: MORE
  // ============================================================
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final more = await _homeService.fetchAppliedJobs(
        offset: _offset,
        limit: _pageSize,
      );

      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _appliedJobs.addAll(more);
        _offset = _appliedJobs.length;

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

  // ============================================================
  // SAVE / UNSAVE
  // ============================================================
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

  // ============================================================
  // OPEN JOB DETAILS
  // ============================================================
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

  // ============================================================
  // UI
  // ============================================================
  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.description_outlined,
                size: 52,
                color: Colors.black.withOpacity(0.35),
              ),
              const SizedBox(height: 14),
              Text(
                "No applied jobs yet",
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "When you apply to jobs, they will appear here.\nYou can track everything from one place.",
                style: KhilonjiyaUI.sub,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: KhilonjiyaUI.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tip: Apply to jobs from Home to start tracking.",
                        style: KhilonjiyaUI.body.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appliedList() {
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _appliedJobs.length + 1,
        itemBuilder: (_, i) {
          // bottom loader
          if (i == _appliedJobs.length) {
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

          final job = _appliedJobs[i];
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Applied Jobs",
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
                  : (_appliedJobs.isEmpty ? _emptyState() : _appliedList()),
            ),
          ],
        ),
      ),
    );
  }
}