import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/job_card_widget.dart';
import '../common/widgets/pages/job_details_page.dart';

class CompanyDetailsPage extends StatefulWidget {
  final String companyId;

  const CompanyDetailsPage({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  bool _loadingJobs = true;

  bool _isFollowing = false;

  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _jobs = [];

  // Saved jobs (optional)
  Set<String> _savedJobIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadingJobs = true;
    });

    try {
      final company = await _service.fetchCompanyDetails(widget.companyId);
      final follow = await _service.isCompanyFollowed(widget.companyId);

      // optional saved jobs for job cards
      final saved = await _service.getUserSavedJobs();

      final jobs = await _service.fetchCompanyJobs(
        companyId: widget.companyId,
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _company = company;
        _isFollowing = follow;
        _savedJobIds = saved;
        _jobs = jobs;
      });
    } catch (_) {
      // ignore
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingJobs = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final newValue = await _service.toggleFollowCompany(widget.companyId);
      if (!mounted) return;
      setState(() => _isFollowing = newValue);
    } catch (_) {}
  }

  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _service.toggleSaveJob(jobId);
      if (!mounted) return;

      setState(() {
        isSaved ? _savedJobIds.add(jobId) : _savedJobIds.remove(jobId);
      });
    } catch (_) {}
  }

  void _openJobDetails(Map<String, dynamic> job) {
    _service.trackJobView(job['id'].toString());

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
    if (_loading) {
      return Scaffold(
        backgroundColor: KhilonjiyaUI.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text(
            "Company",
            style: KhilonjiyaUI.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final c = _company;
    if (c == null || c.isEmpty) {
      return Scaffold(
        backgroundColor: KhilonjiyaUI.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text(
            "Company",
            style: KhilonjiyaUI.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Center(
          child: Text(
            "Company not found",
            style: KhilonjiyaUI.sub,
          ),
        ),
      );
    }

    final name = (c['name'] ?? 'Company').toString().trim();
    final logoUrl = (c['logo_url'] ?? '').toString().trim();
    final website = (c['website'] ?? '').toString().trim();
    final description = (c['description'] ?? '').toString().trim();
    final industry = (c['industry'] ?? '').toString().trim();
    final size = (c['company_size'] ?? '').toString().trim();

    final isVerified = c['is_verified'] == true;

    final rating = _toDouble(c['rating']);
    final totalJobs = _toInt(c['total_jobs']);

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          name.isEmpty ? "Company" : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KhilonjiyaUI.cardTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ------------------------------------------------------------
            // HEADER CARD
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: KhilonjiyaUI.cardDecoration(radius: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogoSquare(
                    logoUrl: logoUrl,
                    name: name,
                    size: 62,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name.isEmpty ? "Company" : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KhilonjiyaUI.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: KhilonjiyaUI.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _subtitle(industry: industry, size: size, website: website),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: KhilonjiyaUI.sub.copyWith(
                            fontSize: 12.4,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            _statPill(
                              icon: Icons.star_rounded,
                              text: rating <= 0 ? "New" : rating.toStringAsFixed(1),
                              iconColor: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 10),
                            _statPill(
                              icon: Icons.work_rounded,
                              text: totalJobs <= 0 ? "0 jobs" : "$totalJobs jobs",
                              iconColor: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ------------------------------------------------------------
            // FOLLOW BUTTON
            // ------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _toggleFollow,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _isFollowing ? Colors.white : KhilonjiyaUI.primary,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isFollowing ? KhilonjiyaUI.border : KhilonjiyaUI.primary,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isFollowing ? "Following" : "Follow",
                        style: KhilonjiyaUI.body.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 13.8,
                          color: _isFollowing ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ------------------------------------------------------------
            // ABOUT
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: KhilonjiyaUI.cardDecoration(radius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About company",
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 14.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description.trim().isEmpty
                        ? "No description added yet."
                        : description,
                    style: KhilonjiyaUI.body.copyWith(
                      fontSize: 13.2,
                      height: 1.45,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ------------------------------------------------------------
            // OPEN JOBS
            // ------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Open jobs",
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _jobs.isEmpty ? "" : "${_jobs.length}",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_loadingJobs)
              Container(
                height: 80,
                decoration: KhilonjiyaUI.cardDecoration(radius: 18),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_jobs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: KhilonjiyaUI.cardDecoration(radius: 18),
                child: Text(
                  "No active jobs from this company right now.",
                  style: KhilonjiyaUI.sub,
                ),
              )
            else
              ..._jobs.map((job) {
                final id = job['id']?.toString() ?? '';

                return JobCardWidget(
                  job: job,
                  isSaved: _savedJobIds.contains(id),
                  onSaveToggle: () => _toggleSaveJob(id),
                  onTap: () => _openJobDetails(job),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _statPill({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.sub.copyWith(
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle({
    required String industry,
    required String size,
    required String website,
  }) {
    final parts = <String>[];

    if (industry.trim().isNotEmpty) parts.add(industry.trim());
    if (size.trim().isNotEmpty) parts.add(size.trim());
    if (website.trim().isNotEmpty) parts.add(website.trim());

    return parts.isEmpty ? "Company profile" : parts.join(" • ");
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class _CompanyLogoSquare extends StatelessWidget {
  final String logoUrl;
  final String name;
  final double size;

  const _CompanyLogoSquare({
    required this.logoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.trim().isEmpty
          ? Center(
              child: Text(
                letter,
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF334155),
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: KhilonjiyaUI.h1.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF334155),
                    ),
                  ),
                );
              },
            ),
    );
  }
}