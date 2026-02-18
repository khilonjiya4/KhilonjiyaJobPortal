import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';
import '../../../services/employer_dashboard_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final EmployerDashboardService _service = EmployerDashboardService();

  bool _loading = true;
  bool _refreshing = false;

  // REAL DATA
  Map<String, dynamic> _company = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _recentApplicants = [];
  List<Map<String, dynamic>> _todayInterviews = [];
  Map<String, dynamic> _perf7d = {};
  List<Map<String, dynamic>> _topJobs = [];

  int _unreadNotifications = 0;

  // Bottom nav
  int _bottomIndex = 0;

  // ------------------------------------------------------------
  // UI TOKENS (Minimal, Elegant)
  // ------------------------------------------------------------
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  static const double _r16 = 16;
  static const double _r20 = 20;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  User _requireUser() {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) setState(() => _loading = true);
    if (silent) setState(() => _refreshing = true);

    try {
      final user = _requireUser();

      // Resolve company first (needed for interviews)
      final company = await _service.resolveMyCompany();
      final companyId = (company['id'] ?? '').toString();

      final results = await Future.wait([
        _service.fetchEmployerJobs(),
        _service.fetchEmployerDashboardStats(),
        _service.fetchRecentApplicants(limit: 6),
        _service.fetchTopJobs(limit: 6),
        _service.fetchTodayInterviews(companyId: companyId, limit: 10),
        _service.fetchLast7DaysPerformance(employerId: user.id),
        _service.fetchUnreadNotificationsCount(),
      ]);

      _company = Map<String, dynamic>.from(company);
      _jobs = List<Map<String, dynamic>>.from(results[0] as List);
      _stats = Map<String, dynamic>.from(results[1] as Map);
      _recentApplicants = List<Map<String, dynamic>>.from(results[2] as List);
      _topJobs = List<Map<String, dynamic>>.from(results[3] as List);
      _todayInterviews = List<Map<String, dynamic>>.from(results[4] as List);
      _perf7d = Map<String, dynamic>.from(results[5] as Map);
      _unreadNotifications = (results[6] as int);
    } catch (_) {
      _company = {};
      _jobs = [];
      _stats = {};
      _recentApplicants = [];
      _topJobs = [];
      _todayInterviews = [];
      _perf7d = {};
      _unreadNotifications = 0;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _refreshing = false;
    });
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------
  Future<void> _logout() async {
    await MobileAuthService().logout();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // SAFE STATS
  // ------------------------------------------------------------
  int _s(String key) => _toInt(_stats[key]);

  int get _totalJobs => _s('total_jobs');
  int get _activeJobs => _s('active_jobs');
  int get _pausedJobs => _s('paused_jobs');
  int get _closedJobs => _s('closed_jobs');
  int get _expiredJobs => _s('expired_jobs');

  int get _totalApplicants => _s('total_applicants');
  int get _totalViews => _s('total_views');
  int get _applicants24h => _s('applicants_last_24h');

  // ------------------------------------------------------------
  // COMPANY SAFE
  // ------------------------------------------------------------
  String get _companyName => (_company['name'] ?? 'Company').toString();
  String get _companyLogo => (_company['logo_url'] ?? '').toString();
  bool get _companyVerified => (_company['is_verified'] ?? false) == true;

  String get _companyLocation {
    final city = (_company['headquarters_city'] ?? '').toString().trim();
    final state = (_company['headquarters_state'] ?? '').toString().trim();

    if (city.isNotEmpty && state.isNotEmpty) return "$city, $state";
    if (state.isNotEmpty) return state;
    if (city.isNotEmpty) return city;
    return "India";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      drawer: _newEmployerDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (scaffoldContext) {
                return _buildTopHeader(scaffoldContext);
              },
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadDashboard(silent: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildCompanyProfileRow(),
                      const SizedBox(height: 14),

                      _sectionHeader(
                        title: "Quick Stats",
                        ctaText: _refreshing ? "Refreshing..." : "Refresh",
                        onTap: _refreshing
                            ? null
                            : () => _loadDashboard(silent: true),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickStatsRow(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Primary Actions"),
                      const SizedBox(height: 10),
                      _buildPrimaryActionsGrid(),

                      const SizedBox(height: 18),

                      _sectionHeader(
                        title: "Recent Applicants",
                        ctaText: "View all",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.employerJobs);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildRecentApplicantsCard(),

                      const SizedBox(height: 18),

                      _sectionHeader(
                        title: "Your Active Jobs",
                        ctaText: "View all",
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.employerJobs);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildActiveJobsList(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Today’s Interviews"),
                      const SizedBox(height: 10),
                      _buildTodayInterviewsReal(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Performance (Last 7 days)"),
                      const SizedBox(height: 10),
                      _buildPerformanceReal(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Top Jobs"),
                      const SizedBox(height: 10),
                      _buildTopJobsReal(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Action Needed"),
                      const SizedBox(height: 10),
                      _buildActionNeededReal(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.pushNamed(context, AppRoutes.createJob);
          if (res == true) await _loadDashboard(silent: true);
        },
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 1,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Post a Job",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ------------------------------------------------------------
  // TOP HEADER (REAL NOTIFICATIONS)
  // ------------------------------------------------------------
  Widget _buildTopHeader(BuildContext scaffoldContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.menu, size: 22, color: _text),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Employer Dashboard",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: _text,
                letterSpacing: -0.2,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.employerNotifications);
              await _loadDashboard(silent: true);
            },
            child: Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    size: 22,
                    color: Color(0xFF334155),
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _unreadNotifications > 99
                            ? "99+"
                            : _unreadNotifications.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
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
  // COMPANY PROFILE ROW (REAL)
  // ------------------------------------------------------------
  Widget _buildCompanyProfileRow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Row(
        children: [
          _companyAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _companyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: _text,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_companyVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: _primary),
                            SizedBox(width: 6),
                            Text(
                              "Verified",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: _muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _companyLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w800,
                          color: _muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyAvatar() {
    if (_companyLogo.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDBEAFE)),
            color: const Color(0xFFEFF6FF),
          ),
          child: Image.network(
            _companyLogo,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.apartment_rounded,
              color: _primary,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: const Icon(Icons.apartment_rounded, color: _primary),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------
  Widget _sectionHeader({
    required String title,
    String? ctaText,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: _text,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (ctaText != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                ctaText,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: onTap == null ? const Color(0xFF94A3B8) : _primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // QUICK STATS (REAL)
  // ------------------------------------------------------------
  Widget _buildQuickStatsRow() {
    return SizedBox(
      height: 122,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickStatCard(
            icon: Icons.work_outline,
            value: _activeJobs.toString(),
            label: "Active Jobs",
            hint: "$_totalJobs total",
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.people_outline,
            value: _totalApplicants.toString(),
            label: "Applicants",
            hint: "+$_applicants24h in 24h",
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.visibility_outlined,
            value: _totalViews.toString(),
            label: "Views",
            hint: "All time",
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String hint,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PRIMARY ACTIONS (REAL NAV)
  // ------------------------------------------------------------
  Widget _buildPrimaryActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _actionTile(
          icon: Icons.add_circle_outline,
          label: "Post a Job",
          onTap: () async {
            final res = await Navigator.pushNamed(context, AppRoutes.createJob);
            if (res == true) await _loadDashboard(silent: true);
          },
        ),
        _actionTile(
          icon: Icons.work_outline,
          label: "Manage Jobs",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        _actionTile(
          icon: Icons.people_outline,
          label: "Applicants",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
        _actionTile(
          icon: Icons.notifications_none_outlined,
          label: "Notifications",
          onTap: () async {
            await Navigator.pushNamed(context, AppRoutes.employerNotifications);
            await _loadDashboard(silent: true);
          },
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_r20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(radius: _r20, shadow: false),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Icon(icon, color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RECENT APPLICANTS (REAL)
  // ------------------------------------------------------------
  Widget _buildRecentApplicantsCard() {
    if (_recentApplicants.isEmpty) {
      return _softEmptyCard(
        icon: Icons.people_outline,
        title: "No applicants yet",
        subtitle: "When candidates apply, they will appear here.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          for (int i = 0; i < _recentApplicants.length; i++) ...[
            _recentApplicantTile(_recentApplicants[i]),
            if (i != _recentApplicants.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _border),
              ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.employerJobs);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "View All",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentApplicantTile(Map<String, dynamic> row) {
    final listing = (row['job_listings'] ?? {}) as Map;
    final app = (row['job_applications'] ?? {}) as Map;

    final listingId = (row['listing_id'] ?? '').toString();
    final status = (row['application_status'] ?? 'applied').toString();
    final appliedAt = row['applied_at'];

    final name = (app['name'] ?? 'Candidate').toString();
    final jobTitle = (listing['job_title'] ?? 'Job').toString();

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.pushNamed(
          context,
          AppRoutes.jobApplicants,
          arguments: listingId,
        );
        await _loadDashboard(silent: true);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _avatarLetter(name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$jobTitle • ${_timeAgo(appliedAt)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _applicationStatusChip(status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _avatarLetter(String name) {
    final ch = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      alignment: Alignment.center,
      child: Text(
        ch,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: _text,
        ),
      ),
    );
  }

  Widget _applicationStatusChip(String status) {
    final s = status.toLowerCase();

    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);
    String label = 'Applied';

    if (s == 'viewed') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF334155);
      label = 'Viewed';
    } else if (s == 'shortlisted') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Shortlisted';
    } else if (s == 'interview_scheduled') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interview';
    } else if (s == 'interviewed') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Interviewed';
    } else if (s == 'selected') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF14532D);
      label = 'Selected';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTIVE JOB POSTS (REAL)
  // ------------------------------------------------------------
  Widget _buildActiveJobsList() {
    if (_jobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.work_outline,
        title: "No jobs posted yet",
        subtitle: "Post your first job to start receiving applications.",
      );
    }

    final activeJobs = _jobs
        .where((j) =>
            (j['status'] ?? 'active').toString().toLowerCase() == 'active')
        .toList();

    final list = activeJobs.isNotEmpty ? activeJobs : _jobs;

    return Column(
      children: list.take(4).map((job) => _activeJobCard(job)).toList(),
    );
  }

  Widget _activeJobCard(Map<String, dynamic> job) {
    final jobId = (job['id'] ?? '').toString();
    final title = (job['job_title'] ?? 'Job').toString();
    final status = (job['status'] ?? 'active').toString();

    final district = (job['district'] ?? '').toString();
    final jobType = (job['job_type'] ?? 'Full-time').toString();
    final postedAt = job['created_at'];

    final applicants = _toInt(job['applications_count']);
    final views = _toInt(job['views_count']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _jobStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  district.isEmpty ? "Assam" : district,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                  ),
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              Text(
                jobType,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                postedAt == null ? "Recently posted" : _timeAgo(postedAt),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Icon(Icons.people_outline, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$applicants applicants",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const Icon(Icons.visibility_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$views views",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Edit Job will be added after Applicants Pipeline",
                        ),
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
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: jobId,
                    );
                    await _loadDashboard(silent: true);
                  },
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: const Text(
                    "Applicants",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _jobStatusChip(String status) {
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    String label;

    if (s == 'active') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF166534);
      label = 'Active';
    } else if (s == 'paused') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFF7C2D12);
      label = 'Paused';
    } else if (s == 'expired') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
      label = 'Expired';
    } else {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFF9F1239);
      label = 'Closed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TODAY INTERVIEWS (REAL)
  // ------------------------------------------------------------
  Widget _buildTodayInterviewsReal() {
    if (_todayInterviews.isEmpty) {
      return _softEmptyCard(
        icon: Icons.calendar_month_outlined,
        title: "No interviews scheduled today",
        subtitle: "When you schedule interviews, they will appear here.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          for (int i = 0; i < _todayInterviews.length; i++) ...[
            _interviewTile(_todayInterviews[i]),
            if (i != _todayInterviews.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _border),
              ),
          ],
        ],
      ),
    );
  }

  Widget _interviewTile(Map<String, dynamic> row) {
    final scheduledAt = DateTime.tryParse((row['scheduled_at'] ?? '').toString());
    final type = (row['interview_type'] ?? 'video').toString().toLowerCase();
    final duration = _toInt(row['duration_minutes']);
    final meetingLink = (row['meeting_link'] ?? '').toString();
    final location = (row['location_address'] ?? '').toString();

    final listingWrap = (row['job_applications_listings'] ?? {}) as Map;
    final jobWrap = (listingWrap['job_listings'] ?? {}) as Map;
    final appWrap = (listingWrap['job_applications'] ?? {}) as Map;

    final candidateName = (appWrap['name'] ?? 'Candidate').toString();
    final jobTitle = (jobWrap['job_title'] ?? 'Job').toString();

    final isOnline = type.contains('video') || meetingLink.trim().isNotEmpty;

    final timeText = scheduledAt == null
        ? "Today"
        : "${_hhmm(scheduledAt)} • ${duration <= 0 ? 30 : duration} min";

    final modeText = isOnline ? "Online" : "In-person";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Icon(
            isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
            color: _primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: Text(
                      modeText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                candidateName,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                jobTitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 10),
              if (isOnline && meetingLink.trim().isNotEmpty)
                _smallInfo("Meeting link saved")
              else if (!isOnline && location.trim().isNotEmpty)
                _smallInfo("Location saved"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallInfo(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Text(
        t,
        style: const TextStyle(
          color: _muted,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PERFORMANCE (REAL)
  // ------------------------------------------------------------
  Widget _buildPerformanceReal() {
    final days = (_perf7d['days'] ?? []) as List;

    if (days.isEmpty) {
      return _softEmptyCard(
        icon: Icons.insights_outlined,
        title: "No data yet",
        subtitle: "Views and applications will appear after your jobs get traffic.",
      );
    }

    int totalViews = _toInt(_perf7d['total_views']);
    int totalApps = _toInt(_perf7d['total_applications']);

    // simple bars
    int maxV = 1;
    int maxA = 1;
    for (final d in days) {
      if (d is! Map) continue;
      maxV = (d['views'] as int) > maxV ? (d['views'] as int) : maxV;
      maxA = (d['applications'] as int) > maxA ? (d['applications'] as int) : maxA;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _miniMetricsRow(
            leftLabel: "Views",
            leftValue: totalViews.toString(),
            rightLabel: "Applications",
            rightValue: totalApps.toString(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Last 7 days",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: const Text(
                  "Views vs Apps",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _muted,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final d = days[i] as Map;
                final date = DateTime.tryParse((d['date'] ?? '').toString());
                final views = _toInt(d['views']);
                final apps = _toInt(d['applications']);

                final vH = (views / maxV) * 90;
                final aH = (apps / maxA) * 90;

                final label = date == null ? "" : "${date.day}/${date.month}";

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                height: vH < 6 ? 6 : vH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Container(
                                height: aH < 6 ? 6 : aH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF93C5FD),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricsRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    return Row(
      children: [
        Expanded(child: _metricMini(label: leftLabel, value: leftValue)),
        const SizedBox(width: 12),
        Expanded(child: _metricMini(label: rightLabel, value: rightValue)),
      ],
    );
  }

  Widget _metricMini({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: _muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP JOBS (REAL)
  // ------------------------------------------------------------
  Widget _buildTopJobsReal() {
    if (_topJobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.star_outline,
        title: "No job performance yet",
        subtitle: "Once applicants start applying, top jobs will appear here.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          for (int i = 0; i < _topJobs.length; i++) ...[
            _topJobTile(_topJobs[i]),
            if (i != _topJobs.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: _border),
              ),
          ],
        ],
      ),
    );
  }

  Widget _topJobTile(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    final title = (j['job_title'] ?? 'Job').toString();
    final apps = _toInt(j['applications_count']);
    final views = _toInt(j['views_count']);
    final status = (j['status'] ?? 'active').toString();

    return InkWell(
      onTap: () async {
        await Navigator.pushNamed(context, AppRoutes.jobApplicants, arguments: id);
        await _loadDashboard(silent: true);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.work_outline, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$apps applicants • $views views • ${status.toUpperCase()}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ACTION NEEDED (REAL COMPUTED)
  // ------------------------------------------------------------
  Widget _buildActionNeededReal() {
    final waitingReview = _recentApplicants
        .where((a) =>
            (a['application_status'] ?? 'applied')
                .toString()
                .toLowerCase() ==
            'applied')
        .length;

    final expiringSoon = _jobs.where((j) {
      final exp = DateTime.tryParse((j['expires_at'] ?? '').toString());
      if (exp == null) return false;
      final diff = exp.difference(DateTime.now()).inHours;
      return diff >= 0 && diff <= 48;
    }).length;

    final paused = _pausedJobs;

    final List<Widget> cards = [];

    if (waitingReview > 0) {
      cards.add(
        _actionNeededCard(
          icon: Icons.people_outline,
          title: "$waitingReview applicants waiting for review",
          buttonText: "Review",
          onTap: () => Navigator.pushNamed(context, AppRoutes.employerJobs),
        ),
      );
    }

    if (expiringSoon > 0) {
      cards.add(
        _actionNeededCard(
          icon: Icons.warning_amber_outlined,
          title: "$expiringSoon job posts expiring soon",
          buttonText: "Manage jobs",
          onTap: () => Navigator.pushNamed(context, AppRoutes.employerJobs),
        ),
      );
    }

    if (paused > 0) {
      cards.add(
        _actionNeededCard(
          icon: Icons.pause_circle_outline,
          title: "$paused jobs are paused",
          buttonText: "Resume",
          onTap: () => Navigator.pushNamed(context, AppRoutes.employerJobs),
        ),
      );
    }

    if (cards.isEmpty) {
      return _softEmptyCard(
        icon: Icons.check_circle_outline,
        title: "All good",
        subtitle: "No pending actions right now.",
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 12),
        ]
      ],
    );
  }

  Widget _actionNeededCard({
    required IconData icon,
    required String title,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                backgroundColor: const Color(0xFFF8FAFC),
                side: const BorderSide(color: _border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DRAWER (REAL NAV)
  // ------------------------------------------------------------
  Widget _newEmployerDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  _companyAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: _text,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          "Employer Account",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                children: [
                  _drawerItem(
                    icon: Icons.dashboard_outlined,
                    title: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.work_outline,
                    title: "My Jobs",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.employerJobs);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.add_circle_outline,
                    title: "Post a Job",
                    onTap: () async {
                      Navigator.pop(context);
                      final res = await Navigator.pushNamed(
                        context,
                        AppRoutes.createJob,
                      );
                      if (res == true) await _loadDashboard(silent: true);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.people_outline,
                    title: "Applicants",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.employerJobs);
                    },
                  ),
                  _drawerItem(
                    icon: Icons.notifications_none_outlined,
                    title: "Notifications",
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.employerNotifications,
                      );
                      await _loadDashboard(silent: true);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Divider(height: 1, color: _border),
                  ),
                  _drawerItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    destructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await _logout();
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: Column(
                children: [
                  Text(
                    "Made in Assam",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF475569),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "© Khilonjiya",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final fg = destructive ? const Color(0xFFEF4444) : _text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAV (REAL FOR FIRST 3, MESSAGES MOCK)
  // ------------------------------------------------------------
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) {
          setState(() => _bottomIndex = i);

          if (i == 0) {
            // dashboard (stay)
          } else if (i == 1) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          } else if (i == 2) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          } else if (i == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Messages will be added next")),
            );
          } else if (i == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Employer profile will be added next")),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "Jobs",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Applicants",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
  BoxDecoration _cardDeco({double radius = 16, bool shadow = true}) {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _border),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : [],
    );
  }

  Widget _softEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Icon(icon, color: _text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: _muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'recent';

    final d = DateTime.tryParse(date.toString());
    if (d == null) return 'recent';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }

  String _hhmm(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');

    final ampm = h >= 12 ? "PM" : "AM";
    final hh = (h % 12 == 0) ? 12 : (h % 12);

    return "$hh:$m $ampm";
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}