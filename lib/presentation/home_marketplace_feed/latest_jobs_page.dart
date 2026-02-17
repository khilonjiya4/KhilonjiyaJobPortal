import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class LatestJobsPage extends StatefulWidget {
  const LatestJobsPage({Key? key}) : super(key: key);

  @override
  State<LatestJobsPage> createState() => _LatestJobsPageState();
}

class _LatestJobsPageState extends State<LatestJobsPage> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingMore = false;
  bool _disposed = false;

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
    if (_loadingMore || !_hasMore || _loading) return;
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
      _hasMore = true;
      _offset = 0;
      _jobs = [];
    });

    try {
      _savedJobIds = await _homeService.getUserSavedJobs();
    } catch (_) {
      _savedJobIds = {};
    }

    try {
      final first = await _homeService.fetchLatestJobs(
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
        _savedJobIds = {};
        _hasMore = false;
        _loading = false;
      });
    }
  }

  // ============================================================
  // LOAD: MORE
  // ============================================================
  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    if (_disposed) return;

    setState(() => _loadingMore = true);

    try {
      final more = await _homeService.fetchLatestJobs(
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

  // ============================================================
  // SAVE TOGGLE
  // ============================================================
  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _homeService.toggleSaveJob(jobId);
      if (_disposed) return;

      setState(() {
        isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
      });
    } catch (_) {}
  }

  // ============================================================
  // OPEN DETAILS
  // ============================================================
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

    if (_disposed) return;
    setState(() {});
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
                      "Latest Jobs",
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
                  : RefreshIndicator(
                      onRefresh: _loadFirstPage,
                      child: _jobs.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.work_outline_rounded,
                                  size: 44,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    "No jobs found",
                                    style: KhilonjiyaUI.hTitle,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: _jobs.length + 1,
                              itemBuilder: (_, i) {
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}