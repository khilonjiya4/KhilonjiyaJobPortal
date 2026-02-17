import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobsPostedTodayPage extends StatefulWidget {
  const JobsPostedTodayPage({Key? key}) : super(key: key);

  @override
  State<JobsPostedTodayPage> createState() => _JobsPostedTodayPageState();
}

class _JobsPostedTodayPageState extends State<JobsPostedTodayPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingMore = false;
  bool _isDisposed = false;

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
    _isDisposed = true;
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
  // LOAD FIRST PAGE
  // ------------------------------------------------------------
  Future<void> _loadFirstPage() async {
    if (_isDisposed) return;

    setState(() {
      _loading = true;
      _loadingMore = false;
      _jobs = [];
      _hasMore = true;
      _offset = 0;
    });

    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    try {
      final first = await _homeService.fetchJobsPostedToday(
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

    if (_isDisposed) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // LOAD MORE
  // ------------------------------------------------------------
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);

    try {
      final more = await _homeService.fetchJobsPostedToday(
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

    if (_isDisposed) return;
    setState(() => _loadingMore = false);
  }

  // ------------------------------------------------------------
  // SAVE / UNSAVE
  // ------------------------------------------------------------
  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _homeService.toggleSaveJob(jobId);
      if (_isDisposed) return;

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
    if (jobId.isEmpty) return;

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

    if (_isDisposed) return;
    setState(() {});
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: KhilonjiyaUI.text,
        title: const Text(
          "Jobs posted today",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadFirstPage,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_jobs.isEmpty
              ? Center(
                  child: Text(
                    "No jobs posted today",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFirstPage,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _jobs.length + 1,
                    itemBuilder: (_, i) {
                      // bottom loader
                      if (i == _jobs.length) {
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

                      final job = _jobs[i];
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
                )),
    );
  }
}