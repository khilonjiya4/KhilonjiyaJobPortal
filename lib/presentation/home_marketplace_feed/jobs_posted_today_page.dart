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
  bool _isDisposed = false;

  List<Map<String, dynamic>> _jobs = [];
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    if (_isDisposed) return;

    setState(() => _loading = true);

    try {
      // Reuse your existing logic
      // (We already have fetchLatestJobs in service)
      final jobs = await _homeService.fetchLatestJobs(limit: 80);

      // Filter: only jobs created today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayJobs = jobs.where((j) {
        final createdRaw = j['created_at']?.toString();
        final created = createdRaw == null ? null : DateTime.tryParse(createdRaw);
        if (created == null) return false;
        return created.isAfter(todayStart);
      }).toList();

      final saved = await _homeService.getUserSavedJobs();

      if (_isDisposed) return;

      setState(() {
        _jobs = todayJobs;
        _savedJobIds = saved;
        _loading = false;
      });
    } catch (_) {
      if (_isDisposed) return;

      setState(() {
        _jobs = [];
        _savedJobIds = {};
        _loading = false;
      });
    }
  }

  Future<void> _toggleSaveJob(String jobId) async {
    final isSaved = await _homeService.toggleSaveJob(jobId);
    if (_isDisposed) return;

    setState(() {
      isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
    });
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _homeService.trackJobView(job['id'].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsPage(
          job: job,
          isSaved: _savedJobIds.contains(job['id'].toString()),
          onSaveToggle: () => _toggleSaveJob(job['id'].toString()),
        ),
      ),
    );
  }

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
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
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
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _jobs.length,
                    itemBuilder: (_, i) {
                      final job = _jobs[i];

                      return JobCardWidget(
                        job: job,
                        isSaved: _savedJobIds.contains(job['id'].toString()),
                        onSaveToggle: () =>
                            _toggleSaveJob(job['id'].toString()),
                        onTap: () => _openJobDetails(job),
                      );
                    },
                  ),
                ),
    );
  }
}