import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class JobsNearbyPage extends StatefulWidget {
  const JobsNearbyPage({Key? key}) : super(key: key);

  @override
  State<JobsNearbyPage> createState() => _JobsNearbyPageState();
}

class _JobsNearbyPageState extends State<JobsNearbyPage> {
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

    // load more when close to bottom
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  // ============================================================
  // LOAD: FIRST PAGE
  // ============================================================
  Future<void> _loadFirstPage() async {
    if (!_disposed) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _hasMore = true;
        _offset = 0;
        _jobs = [];
      });
    }

    try {
      _savedJobIds = await _homeService.getUserSavedJobs();

      final first = await _homeService.fetchJobsNearby(
        offset: 0,
        limit: _pageSize,
      );

      _jobs = first;
      _offset = _jobs.length;
      _hasMore = first.length >= _pageSize;
    } catch (_) {
      _jobs = [];
      _savedJobIds = {};
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
      final more = await _homeService.fetchJobsNearby(
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
      // stop pagination on error
      _hasMore = false;
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

  // ============================================================
  // UI
  // ============================================================
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
                      "Nearby Jobs",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
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
                                  Icons.near_me_outlined,
                                  size: 44,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    "No nearby jobs found",
                                    style: KhilonjiyaUI.hTitle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(
                                  child: Text(
                                    "Update your profile location to get nearby jobs.",
                                    style: KhilonjiyaUI.sub,
                                    textAlign: TextAlign.center,
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
                                // bottom loader
                                if (i == _jobs.length) {
                                  if (!_hasMore) {
                                    return const SizedBox(height: 30);
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Center(
                                      child: _loadingMore
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child:
                                                  CircularProgressIndicator(),
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