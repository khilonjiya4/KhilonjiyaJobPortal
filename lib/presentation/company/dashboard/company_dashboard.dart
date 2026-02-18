import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../routes/app_routes.dart';
import '../../../services/employer_job_service.dart';
import '../../../services/mobile_auth_service.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  final SupabaseClient _db = Supabase.instance.client;
  final EmployerJobService _service = EmployerJobService();

  bool _loading = true;

  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentApplicants = [];
  List<Map<String, dynamic>> _topJobs = [];

  // REAL extras
  Map<String, dynamic>? _company;
  int _unreadNotifications = 0;

  // interviews today
  bool _loadingInterviews = true;
  List<Map<String, dynamic>> _todayInterviews = [];

  // performance last 7 days
  bool _loadingPerformance = true;
  List<Map<String, dynamic>> _perfDays = []; // [{date, views, applicants}]
  int _views7d = 0;
  int _apps7d = 0;

  // action needed
  int _pendingReviewCount = 0;
  int _expiringJobsCount = 0;

  // Bottom nav
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ------------------------------------------------------------
  // LOAD DASHBOARD
  // ------------------------------------------------------------
  Future<void> _loadDashboard() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _service.fetchEmployerJobs(),
        _service.fetchEmployerDashboardStats(),
        _service.fetchRecentApplicants(limit: 6),
        _service.fetchTopJobs(limit: 6),
      ]);

      _jobs = List<Map<String, dynamic>>.from(results[0] as List);
      _stats = Map<String, dynamic>.from(results[1] as Map);
      _recentApplicants = List<Map<String, dynamic>>.from(results[2] as List);
      _topJobs = List<Map<String, dynamic>>.from(results[3] as List);

      // Load real company from first job (since every job has company_id)
      _company = await _fetchEmployerCompanyFromJobs(_jobs);

      // Load unread notifications
      _unreadNotifications = await _fetchUnreadNotificationsCount();

      // Interviews + performance + action needed
      await Future.wait([
        _loadTodayInterviews(),
        _loadPerformance7Days(),
        _computeActionNeeded(),
      ]);
    } catch (_) {
      _jobs = [];
      _stats = {};
      _recentApplicants = [];
      _topJobs = [];

      _company = null;
      _unreadNotifications = 0;

      _todayInterviews = [];
      _perfDays = [];
      _views7d = 0;
      _apps7d = 0;
      _pendingReviewCount = 0;
      _expiringJobsCount = 0;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // AUTH
  // ------------------------------------------------------------
  String _uid() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u.id;
  }

  // ------------------------------------------------------------
  // COMPANY (REAL)
  // ------------------------------------------------------------
  Future<Map<String, dynamic>?> _fetchEmployerCompanyFromJobs(
    List<Map<String, dynamic>> jobs,
  ) async {
    if (jobs.isEmpty) return null;

    final first = jobs.first;
    final companyObj = first['companies'];

    if (companyObj is Map) {
      return Map<String, dynamic>.from(companyObj);
    }

    final companyId = (first['company_id'] ?? '').toString().trim();
    if (companyId.isEmpty) return null;

    final res = await _db
        .from('companies')
        .select('id,name,logo_url,is_verified,headquarters_state,headquarters_city')
        .eq('id', companyId)
        .maybeSingle();

    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  // ------------------------------------------------------------
  // NOTIFICATIONS (REAL)
  // ------------------------------------------------------------
  Future<int> _fetchUnreadNotificationsCount() async {
    final uid = _uid();

    try {
      // NOTE: Supabase count works only with PostgREST count option.
      // This approach fetches small ids only, safe enough.
      final res = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false)
          .limit(50);

      return (res as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ------------------------------------------------------------
  // INTERVIEWS TODAY (REAL)
  // ------------------------------------------------------------
  Future<void> _loadTodayInterviews() async {
    if (!mounted) return;
    setState(() => _loadingInterviews = true);

    try {
      if (_company == null) {
        _todayInterviews = [];
        if (!mounted) return;
        setState(() => _loadingInterviews = false);
        return;
      }

      final companyId = (_company?['id'] ?? '').toString();
      if (companyId.trim().isEmpty) {
        _todayInterviews = [];
        if (!mounted) return;
        setState(() => _loadingInterviews = false);
        return;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end = start.add(const Duration(days: 1));

      final res = await _db
          .from('interviews')
          .select('''
            id,
            job_application_listing_id,
            interview_type,
            scheduled_at,
            duration_minutes,
            meeting_link,
            location_address,
            round_number,

            job_applications_listings (
              id,
              listing_id,
              application_status,

              job_listings (
                id,
                job_title
              ),

              job_applications (
                id,
                name,
                phone,
                district,
                education,
                experience_level
              )
            )
          ''')
          .eq('company_id', companyId)
          .gte('scheduled_at', start.toIso8601String())
          .lt('scheduled_at', end.toIso8601String())
          .order('scheduled_at', ascending: true)
          .limit(12);

      _todayInterviews = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _todayInterviews = [];
    }

    if (!mounted) return;
    setState(() => _loadingInterviews = false);
  }

  // ------------------------------------------------------------
  // PERFORMANCE LAST 7 DAYS (REAL)
  // - views from job_views
  // - applicants from job_applications_listings.applied_at
  // ------------------------------------------------------------
  Future<void> _loadPerformance7Days() async {
    if (!mounted) return;
    setState(() => _loadingPerformance = true);

    try {
      if (_jobs.isEmpty) {
        _perfDays = [];
        _views7d = 0;
        _apps7d = 0;
        if (!mounted) return;
        setState(() => _loadingPerformance = false);
        return;
      }

      final jobIds = _jobs.map((e) => (e['id'] ?? '').toString()).toList();
      if (jobIds.isEmpty) {
        _perfDays = [];
        _views7d = 0;
        _apps7d = 0;
        if (!mounted) return;
        setState(() => _loadingPerformance = false);
        return;
      }

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6)); // include today = 7 days

      // views
      final viewsRes = await _db
          .from('job_views')
          .select('job_id, viewed_at')
          .inFilter('job_id', jobIds)
          .gte('viewed_at', start.toIso8601String())
          .limit(5000);

      final viewsRows = List<Map<String, dynamic>>.from(viewsRes);

      // applicants
      final appsRes = await _db
          .from('job_applications_listings')
          .select('listing_id, applied_at')
          .inFilter('listing_id', jobIds)
          .gte('applied_at', start.toIso8601String())
          .limit(5000);

      final appsRows = List<Map<String, dynamic>>.from(appsRes);

      // bucket by day
      final Map<String, int> viewsByDay = {};
      final Map<String, int> appsByDay = {};

      String dayKey(DateTime d) =>
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      for (final r in viewsRows) {
        final dt = DateTime.tryParse((r['viewed_at'] ?? '').toString());
        if (dt == null) continue;
        final k = dayKey(dt.toLocal());
        viewsByDay[k] = (viewsByDay[k] ?? 0) + 1;
      }

      for (final r in appsRows) {
        final dt = DateTime.tryParse((r['applied_at'] ?? '').toString());
        if (dt == null) continue;
        final k = dayKey(dt.toLocal());
        appsByDay[k] = (appsByDay[k] ?? 0) + 1;
      }

      final List<Map<String, dynamic>> days = [];
      int totalViews = 0;
      int totalApps = 0;

      for (int i = 0; i < 7; i++) {
        final d = start.add(Duration(days: i));
        final k = dayKey(d);

        final v = viewsByDay[k] ?? 0;
        final a = appsByDay[k] ?? 0;

        totalViews += v;
        totalApps += a;

        days.add({
          'date': d,
          'views': v,
          'apps': a,
        });
      }

      _perfDays = days;
      _views7d = totalViews;
      _apps7d = totalApps;
    } catch (_) {
      _perfDays = [];
      _views7d = 0;
      _apps7d = 0;
    }

    if (!mounted) return;
    setState(() => _loadingPerformance = false);
  }

  // ------------------------------------------------------------
  // ACTION NEEDED (REAL)
  // - pending review = applicants with status = applied
  // - expiring jobs = expires_at within next 2 days and status=active
  // ------------------------------------------------------------
  Future<void> _computeActionNeeded() async {
    try {
      if (_jobs.isEmpty) {
        _pendingReviewCount = 0;
        _expiringJobsCount = 0;
        return;
      }

      final jobIds = _jobs.map((e) => (e['id'] ?? '').toString()).toList();

      // pending review
      final pendingRes = await _db
          .from('job_applications_listings')
          .select('id')
          .inFilter('listing_id', jobIds)
          .eq('application_status', 'applied')
          .limit(200);

      _pendingReviewCount = (pendingRes as List).length;

      // expiring jobs
      final now = DateTime.now();
      final soon = now.add(const Duration(days: 2));

      final expiringRes = await _db
          .from('job_listings')
          .select('id')
          .eq('employer_id', _uid())
          .eq('status', 'active')
          .lte('expires_at', soon.toIso8601String())
          .gte('expires_at', now.toIso8601String())
          .limit(200);

      _expiringJobsCount = (expiringRes as List).length;
    } catch (_) {
      _pendingReviewCount = 0;
      _expiringJobsCount = 0;
    }
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
  // DESIGN TOKENS (minimal, elegant)
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
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _buildCompanyProfileRow(),
                      const SizedBox(height: 14),

                      _sectionHeader(
                        title: "Quick Stats",
                        ctaText: "Refresh",
                        onTap: _loadDashboard,
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

                      _sectionHeader(
                        title: "Today’s Interviews",
                        ctaText: _todayInterviews.isEmpty ? null : "View",
                        onTap: _todayInterviews.isEmpty
                            ? null
                            : () {
                                // For now: open Applicants screen (you can create Interviews page later)
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.employerJobs,
                                );
                              },
                      ),
                      const SizedBox(height: 10),
                      _buildTodayInterviews(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Job Performance (Last 7 days)"),
                      const SizedBox(height: 10),
                      _buildPerformance(),

                      const SizedBox(height: 18),

                      _sectionHeader(title: "Action Needed"),
                      const SizedBox(height: 10),
                      _buildActionNeeded(),
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
          if (res == true) await _loadDashboard();
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
  // TOP HEADER
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

          // Notifications
          InkWell(
            onTap: () {
              // You can create a notifications page later.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Notifications page coming next"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(999),
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
                    right: 7,
                    top: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Text(
                        _unreadNotifications > 99
                            ? "99+"
                            : _unreadNotifications.toString(),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
    final company = _company;

    final name = (company?['name'] ?? 'Company').toString();
    final verified = company?['is_verified'] == true;

    final city = (company?['headquarters_city'] ?? '').toString().trim();
    final state = (company?['headquarters_state'] ?? '').toString().trim();
    final location = [city, state].where((e) => e.isNotEmpty).join(", ");

    final logoUrl = (company?['logo_url'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Row(
        children: [
          _companyAvatar(name: name, logoUrl: logoUrl),
          const SizedBox(width: 12),
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
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _text,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (verified)
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
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: _primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Verified",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
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
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: _muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location.isEmpty ? "Assam, India" : location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
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

  Widget _companyAvatar({required String name, required String logoUrl}) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border),
          ),
          child: Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(letter),
          ),
        ),
      );
    }

    return _fallbackAvatar(letter);
  }

  Widget _fallbackAvatar(String letter) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _primary,
        ),
      ),
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
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (ctaText != null && onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                ctaText,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: _primary,
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
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickStatCard(
            icon: Icons.work_outline,
            value: _activeJobs.toString(),
            label: "Active Jobs",
            hint: "Total: $_totalJobs",
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.people_outline,
            value: _totalApplicants.toString(),
            label: "Applicants",
            hint: "Last 24h: $_applicants24h",
          ),
          const SizedBox(width: 12),
          _quickStatCard(
            icon: Icons.visibility_outlined,
            value: _totalViews.toString(),
            label: "Total Views",
            hint: "Last 7d: $_views7d",
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
      width: 168,
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8)),
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
          const SizedBox(height: 8),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PRIMARY ACTIONS
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
            if (res == true) await _loadDashboard();
          },
        ),
        _actionTile(
          icon: Icons.people_outline,
          label: "View Applicants",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
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
          icon: Icons.star_border_rounded,
          label: "Top Jobs",
          onTap: () {
            _showTopJobsBottomSheet();
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
                  fontWeight: FontWeight.w800,
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
                child: Divider(height: 1, color: Color(0xFFE6E8EC)),
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
                "View All Applicants",
                style: TextStyle(fontWeight: FontWeight.w800),
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
        await _loadDashboard();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _circleLetterAvatar(name),
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
                      fontWeight: FontWeight.w700,
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

  Widget _circleLetterAvatar(String name) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

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
        letter,
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

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

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

          // location + type
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
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              Text(
                jobType,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // salary
          Row(
            children: [
              const Icon(Icons.currency_rupee_rounded,
                  size: 16, color: _muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _salaryText(salaryMin, salaryMax),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // posted + applicants + views
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                postedAt == null ? "Recently posted" : _timeAgo(postedAt),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Icon(Icons.people_outline, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$applicants applicants",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Text(
                " • ",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const Icon(Icons.visibility_outlined, size: 16, color: _muted),
              const SizedBox(width: 6),
              Text(
                "$views views",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: jobId,
                    );
                    await _loadDashboard();
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.employerJobs);
                  },
                  icon: const Icon(Icons.work_outline, size: 18),
                  label: const Text(
                    "Manage",
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
  // TODAY'S INTERVIEWS (REAL)
  // ------------------------------------------------------------
  Widget _buildTodayInterviews() {
    if (_loadingInterviews) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(radius: _r20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_todayInterviews.isEmpty) {
      return _softEmptyCard(
        icon: Icons.calendar_month_outlined,
        title: "No interviews today",
        subtitle: "Scheduled interviews will appear here automatically.",
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
                child: Divider(height: 1, color: Color(0xFFE6E8EC)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _interviewTile(Map<String, dynamic> row) {
    final scheduledAt = DateTime.tryParse((row['scheduled_at'] ?? '').toString())
        ?.toLocal();

    final type = (row['interview_type'] ?? 'video').toString().toLowerCase();
    final isOnline = type == 'video';

    final duration = _toInt(row['duration_minutes']);
    final meetingLink = (row['meeting_link'] ?? '').toString().trim();
    final location = (row['location_address'] ?? '').toString().trim();

    final listingObj = (row['job_applications_listings'] ?? {}) as Map;
    final jobObj = (listingObj['job_listings'] ?? {}) as Map;
    final appObj = (listingObj['job_applications'] ?? {}) as Map;

    final candidate = (appObj['name'] ?? 'Candidate').toString();
    final jobTitle = (jobObj['job_title'] ?? 'Job').toString();

    final timeText = scheduledAt == null
        ? "Scheduled"
        : _formatTime(scheduledAt);

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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    icon: Icons.schedule_rounded,
                    text: timeText,
                    bg: const Color(0xFFEFF6FF),
                    fg: _primary,
                  ),
                  _pill(
                    icon: isOnline
                        ? Icons.wifi_tethering_rounded
                        : Icons.place_outlined,
                    text: modeText,
                    bg: const Color(0xFFF1F5F9),
                    fg: const Color(0xFF334155),
                  ),
                  if (duration > 0)
                    _pill(
                      icon: Icons.timelapse_rounded,
                      text: "${duration}m",
                      bg: const Color(0xFFF8FAFC),
                      fg: const Color(0xFF475569),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                candidate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                jobTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              if (isOnline && meetingLink.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Open meeting link (url_launcher) coming next",
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text(
                      "Open Link",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
              if (!isOnline && location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PERFORMANCE (REAL)
  // ------------------------------------------------------------
  Widget _buildPerformance() {
    if (_loadingPerformance) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDeco(radius: _r20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfDays.isEmpty) {
      return _softEmptyCard(
        icon: Icons.insights_outlined,
        title: "No performance data yet",
        subtitle: "Views and applications will show here automatically.",
      );
    }

    final maxV = _perfDays
        .map((e) => _toInt(e['views']))
        .fold<int>(1, (a, b) => a > b ? a : b);

    final maxA = _perfDays
        .map((e) => _toInt(e['apps']))
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: _r20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // summary row
          Row(
            children: [
              Expanded(
                child: _metricMini(
                  label: "Views (7d)",
                  value: _views7d.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricMini(
                  label: "Applications (7d)",
                  value: _apps7d.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // minimal bars (no external chart lib)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: _perfDays.map((d) {
                final date = d['date'] as DateTime;
                final v = _toInt(d['views']);
                final a = _toInt(d['apps']);

                final vw = maxV == 0 ? 0.0 : (v / maxV);
                final aw = maxA == 0 ? 0.0 : (a / maxA);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(
                          _dayShort(date),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _miniBar(
                              label: "V $v",
                              fill: vw,
                              fg: _primary,
                            ),
                            const SizedBox(height: 6),
                            _miniBar(
                              label: "A $a",
                              fill: aw,
                              fg: const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBar({
    required String label,
    required double fill,
    required Color fg,
  }) {
    final f = fill.clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 8,
              color: const Color(0xFFE2E8F0),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: f,
                child: Container(color: fg),
              ),
            ),
          ),
        ),
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
              fontWeight: FontWeight.w800,
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
  // ACTION NEEDED (REAL)
  // ------------------------------------------------------------
  Widget _buildActionNeeded() {
    if (_jobs.isEmpty) {
      return _softEmptyCard(
        icon: Icons.check_circle_outline,
        title: "Nothing to review",
        subtitle: "Once you post jobs and get applicants, tasks appear here.",
      );
    }

    final items = <Widget>[];

    if (_pendingReviewCount > 0) {
      items.add(
        _actionNeededCard(
          icon: Icons.people_outline,
          title: "$_pendingReviewCount applicants waiting for review",
          buttonText: "Review now",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
      );
    }

    if (_expiringJobsCount > 0) {
      items.add(
        _actionNeededCard(
          icon: Icons.warning_amber_outlined,
          title: "$_expiringJobsCount job posts expiring soon",
          buttonText: "Manage jobs",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
      );
    }

    // Always show a small status card (clean UX)
    if (items.isEmpty) {
      items.add(
        _actionNeededCard(
          icon: Icons.check_circle_outline,
          title: "All caught up",
          buttonText: "View jobs",
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          },
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: 12),
        ],
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
  // TOP JOBS (REAL) - bottom sheet
  // ------------------------------------------------------------
  void _showTopJobsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Top Performing Jobs",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_topJobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      "No top jobs yet.",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _muted,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _topJobs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final j = _topJobs[i];
                        final title = (j['job_title'] ?? 'Job').toString();
                        final applicants = _toInt(j['applications_count']);
                        final views = _toInt(j['views_count']);
                        final status = (j['status'] ?? 'active').toString();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                          subtitle: Text(
                            "$applicants applicants • $views views • ${status.toUpperCase()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _muted,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.employerJobs,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DRAWER
  // ------------------------------------------------------------
  Widget _newEmployerDrawer() {
    final companyName = (_company?['name'] ?? 'Company').toString();

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
                  _companyAvatar(
                    name: companyName,
                    logoUrl: (_company?['logo_url'] ?? '').toString(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          companyName,
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
                            fontWeight: FontWeight.w700,
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
                      if (res == true) await _loadDashboard();
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
  // BOTTOM NAV (REAL ROUTES)
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

          if (i == 1) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          } else if (i == 2) {
            Navigator.pushNamed(context, AppRoutes.employerJobs);
          } else if (i == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Messages coming next")),
            );
          } else if (i == 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile coming next")),
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
                    fontWeight: FontWeight.w700,
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

  String _salaryText(dynamic min, dynamic max) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final mn = toInt(min);
    final mx = toInt(max);

    // Your requirement: show as "5000 - 10000 / month"
    if (mn != null && mx != null) return "$mn - $mx / month";
    if (mn != null) return "$mn / month";
    return "Salary not disclosed";
  }

  String _formatTime(DateTime d) {
    int h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');

    final ampm = h >= 12 ? "PM" : "AM";
    h = h % 12;
    if (h == 0) h = 12;

    return "$h:$m $ampm";
  }

  String _dayShort(DateTime d) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[(d.weekday - 1).clamp(0, 6)];
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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}