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

  Map<String, dynamic>? _company;
  List<Map<String, dynamic>> _jobs = [];
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
      final company =
          await _service.fetchCompanyDetails(widget.companyId);

      final saved = await _service.getUserSavedJobs();

      final jobs = await _service.fetchCompanyJobs(
        companyId: widget.companyId,
        limit: 50,
      );

      if (!mounted) return;

      setState(() {
        _company = company;
        _savedJobIds = saved;
        _jobs = jobs;
      });
    } catch (_) {} finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingJobs = false;
      });
    }
  }

  Future<void> _toggleSaveJob(String jobId) async {
    try {
      final isSaved = await _service.toggleSaveJob(jobId);
      if (!mounted) return;

      setState(() {
        isSaved
            ? _savedJobIds.add(jobId)
            : _savedJobIds.remove(jobId);
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
          isSaved:
              _savedJobIds.contains(job['id'].toString()),
          onSaveToggle: () =>
              _toggleSaveJob(job['id'].toString()),
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
          iconTheme:
              const IconThemeData(color: Color(0xFF0F172A)),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final c = _company;
    if (c == null || c.isEmpty) {
      return Scaffold(
        backgroundColor: KhilonjiyaUI.bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Color(0xFF0F172A)),
        ),
        body: Center(
          child: Text(
            "Company not found",
            style: KhilonjiyaUI.sub,
          ),
        ),
      );
    }

    final name =
        (c['name'] ?? 'Company').toString().trim();
    final logoUrl =
        (c['logo_url'] ?? '').toString().trim();
    final industry =
        (c['industry'] ?? '').toString().trim();
    final size =
        (c['company_size'] ?? '').toString().trim();
    final website =
        (c['website'] ?? '').toString().trim();
    final description =
        (c['description'] ?? '').toString().trim();

    final rating = _toDouble(c['rating']);
    final totalJobs = _toInt(c['total_jobs']);

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          name,
          style: KhilonjiyaUI.cardTitle,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ================= HEADER (Slim like Job Card)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: KhilonjiyaUI.cardDecoration(),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _CompanyLogoSquare(
                    logoUrl: logoUrl,
                    name: name,
                    size: 46,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              KhilonjiyaUI.cardTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(
                            industry,
                            size,
                            website,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              KhilonjiyaUI.company,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _infoRow(
                              Icons.star_rounded,
                              const Color(0xFFF59E0B),
                              rating <= 0
                                  ? "New"
                                  : rating
                                      .toStringAsFixed(
                                          1),
                            ),
                            const SizedBox(width: 12),
                            _infoRow(
                              Icons.work_outline_rounded,
                              const Color(
                                  0xFF2563EB),
                              "$totalJobs jobs",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ================= ABOUT (Slim)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: KhilonjiyaUI.cardDecoration(),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    "About company",
                    style:
                        KhilonjiyaUI.cardTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? "No description added yet."
                        : description,
                    style:
                        KhilonjiyaUI.body,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Open jobs",
              style: KhilonjiyaUI.cardTitle,
            ),
            const SizedBox(height: 10),

            if (_loadingJobs)
              const Center(
                  child:
                      CircularProgressIndicator())
            else if (_jobs.isEmpty)
              Container(
                padding:
                    const EdgeInsets.all(12),
                decoration:
                    KhilonjiyaUI.cardDecoration(),
                child: Text(
                  "No active jobs right now.",
                  style:
                      KhilonjiyaUI.sub,
                ),
              )
            else
              ..._jobs.map((job) {
                final id =
                    job['id']?.toString() ?? '';
                return JobCardWidget(
                  job: job,
                  isSaved:
                      _savedJobIds.contains(id),
                  onSaveToggle: () =>
                      _toggleSaveJob(id),
                  onTap: () =>
                      _openJobDetails(job),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      Color color,
      String text) {
    return Row(
      children: [
        Icon(icon,
            size: 16,
            color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style:
              KhilonjiyaUI.body,
        ),
      ],
    );
  }

  String _subtitle(
      String industry,
      String size,
      String website) {
    final parts = <String>[];
    if (industry.isNotEmpty)
      parts.add(industry);
    if (size.isNotEmpty)
      parts.add(size);
    if (website.isNotEmpty)
      parts.add(website);
    return parts.join(" • ");
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
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
    final letter = name.isNotEmpty
        ? name[0].toUpperCase()
        : "C";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            const Color(0xFFF1F5F9),
        borderRadius:
            BorderRadius.circular(12),
      ),
      clipBehavior:
          Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style:
                    KhilonjiyaUI.cardTitle,
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
            ),
    );
  }
}