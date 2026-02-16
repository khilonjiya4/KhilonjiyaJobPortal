// File: lib/presentation/home_marketplace_feed/home_jobs_feed.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/pages/job_details_page.dart';

import 'company_details_page.dart';
import 'top_companies_page.dart';

import 'recommended_jobs_page.dart';
import 'job_search_page.dart';

import 'expected_salary_edit_page.dart';
import 'jobs_by_salary_page.dart';

import 'latest_jobs_page.dart';
import 'jobs_nearby_page.dart';

import 'construction_services_home_page.dart';

import 'profile_edit_page.dart';

import 'widgets/naukri_drawer.dart';

import 'widgets/home_sections/ai_banner_card.dart';
import 'widgets/home_sections/profile_and_search_cards.dart';
import 'widgets/home_sections/boost_card.dart';
import 'widgets/home_sections/expected_salary_card.dart';
import 'widgets/home_sections/section_header.dart';
import 'widgets/home_sections/job_card_horizontal.dart';

// ✅ NEW IMPORT
import '../common/widgets/cards/company_card_horizontal.dart';

// ✅ NEW IMPORTS (for drawer)
import '../../services/subscription_service.dart';
import 'subscription_page.dart';

// ✅ NEW PAGE (created in File 4/4)
import 'jobs_posted_today_page.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // ✅ subscription service (to show Pro / Upgrade in drawer)
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isCheckingAuth = true;
  bool _isDisposed = false;

  // ------------------------------------------------------------
  // HOME SUMMARY
  // ------------------------------------------------------------
  String _profileName = "Your Profile";
  int _profileCompletion = 0;
  String _lastUpdatedText = "Updated recently";
  int _missingDetails = 0;
  int _jobsPostedToday = 0;

  // ------------------------------------------------------------
  // PRO STATUS (for drawer UI)
  // ------------------------------------------------------------
  bool _isProActive = false;

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------
  int _unreadNotifications = 0;

  // ------------------------------------------------------------
  // EXPECTED SALARY
  // ------------------------------------------------------------
  int _expectedSalaryPerMonth = 0;

  // ------------------------------------------------------------
  // JOBS + SAVED
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _recommendedJobs = [];
  List<Map<String, dynamic>> _latestJobs = [];
  List<Map<String, dynamic>> _nearbyJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  // ------------------------------------------------------------
  // COMPANIES
  // ------------------------------------------------------------
  List<Map<String, dynamic>> _topCompanies = [];
  bool _loadingCompanies = true;

  bool _isLoadingProfile = true;

  // ------------------------------------------------------------
  // Search hint slider
  // ------------------------------------------------------------
  final PageController _searchHintController = PageController();
  Timer? _searchHintTimer;

  final List<String> _searchHints = const [
    "Search jobs",
    "Find employers",
    "Search by district",
    "Search electrician jobs",
    "Search plumber jobs",
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _isDisposed = true;

    _searchHintTimer?.cancel();
    _searchHintController.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  Future<void> _initialize() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        _redirectToStart();
        return;
      }

      await _loadInitialData();
      _startSearchHintAutoSlide();
    } catch (_) {
      _redirectToStart();
    }
  }

  void _startSearchHintAutoSlide() {
    _searchHintTimer?.cancel();

    _searchHintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isDisposed) return;
      if (!_searchHintController.hasClients) return;

      final next = (_searchHintController.page?.round() ?? 0) + 1;

      _searchHintController.animateToPage(
        next % _searchHints.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    if (!_isDisposed) {
      setState(() => _isCheckingAuth = false);
    }

    try {
      // 1) Home summary
      final summary = await _homeService.getHomeProfileSummary();
      final jobsCount = await _homeService.getJobsPostedTodayCount();

      _profileName = (summary['profileName'] ?? "Your Profile").toString();
      _profileCompletion = (summary['profileCompletion'] ?? 0) as int;
      _lastUpdatedText =
          (summary['lastUpdatedText'] ?? "Updated recently").toString();
      _missingDetails = (summary['missingDetails'] ?? 0) as int;
      _jobsPostedToday = jobsCount;

      // 2) Expected salary
      _expectedSalaryPerMonth = await _homeService.getExpectedSalaryPerMonth();

      // 3) Saved jobs
      _savedJobIds = await _homeService.getUserSavedJobs();

      // 4) Premium jobs
      _premiumJobs = await _homeService.fetchPremiumJobs(limit: 8);

      // 5) Jobs for sections
      _recommendedJobs = await _homeService.getRecommendedJobs(limit: 40);
      _latestJobs = await _homeService.fetchLatestJobs(limit: 40);
      _nearbyJobs = await _homeService.fetchJobsNearby(limit: 40);

      // 6) Top companies
      _topCompanies = await _homeService.fetchTopCompanies(limit: 10);

      // 7) Notifications count
      try {
        _unreadNotifications = await _homeService.getUnreadNotificationsCount();
      } catch (_) {
        _unreadNotifications = 0;
      }

      // ✅ 8) Pro subscription check (for drawer)
      try {
        _isProActive = await _subscriptionService.isProActive();
      } catch (_) {
        _isProActive = false;
      }
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingProfile = false;
          _loadingCompanies = false;
        });
      }
    }
  }

  Future<void> _refreshHome() async {
    if (_isDisposed) return;

    setState(() {
      _isLoadingProfile = true;
      _loadingCompanies = true;
    });

    await _loadInitialData();
  }

  // ------------------------------------------------------------
  // ROUTING
  // ------------------------------------------------------------
  void _redirectToStart() {
    if (_isDisposed) return;
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // UI EVENTS
  // ------------------------------------------------------------
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

  void _openRecommendedJobsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecommendedJobsPage(),
      ),
    );
  }

  void _openLatestJobsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LatestJobsPage(),
      ),
    );
  }

  void _openJobsNearbyPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsNearbyPage(),
      ),
    );
  }

  void _openSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobSearchPage(),
      ),
    );
  }

  void _openTopCompaniesPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TopCompaniesPage(),
      ),
    );
  }

  void _openCompanyDetails(String companyId) {
    if (companyId.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: companyId),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE EDIT
  // ------------------------------------------------------------
  Future<void> _openProfileEditPage() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );

    if (updated == true) {
      await _refreshHome();
    }
  }

  // ------------------------------------------------------------
  // SUBSCRIPTION PAGE (DRAWER)
  // ------------------------------------------------------------
  Future<void> _openSubscriptionPage() async {
    final _ = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPage()),
    );

    // When returning, refresh Pro status (and drawer UI)
    if (_isDisposed) return;

    try {
      final active = await _subscriptionService.isProActive();
      if (!_isDisposed && mounted) {
        setState(() => _isProActive = active);
      }
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // JOBS POSTED TODAY PAGE (RIGHT CARD VIEW ALL)
  // ------------------------------------------------------------
  void _openJobsPostedTodayPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsPostedTodayPage(),
      ),
    );
  }

  // ------------------------------------------------------------
  // EXPECTED SALARY FLOW
  // ------------------------------------------------------------
  Future<void> _openExpectedSalaryEditPage() async {
    if (!mounted) return;

    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpectedSalaryEditPage(
          initialSalaryPerMonth: _expectedSalaryPerMonth,
        ),
      ),
    );

    if (result == null) return;
    if (!mounted) return;

    setState(() => _expectedSalaryPerMonth = result);

    try {
      final fresh = await _homeService.getExpectedSalaryPerMonth();
      if (!_isDisposed && mounted) {
        setState(() => _expectedSalaryPerMonth = fresh);
      }
    } catch (_) {}
  }

  void _openJobsBySalary() {
    if (_expectedSalaryPerMonth <= 0) {
      _openExpectedSalaryEditPage();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobsBySalaryPage(
          minMonthlySalary: _expectedSalaryPerMonth,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------
  Widget _buildTopBar(BuildContext scaffoldContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.menu, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _openSearchPage,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 18,
                        child: PageView.builder(
                          controller: _searchHintController,
                          itemCount: _searchHints.length,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (_, i) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _searchHints[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KhilonjiyaUI.sub.copyWith(
                                  fontSize: 13.0,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 20,
              color: KhilonjiyaUI.primary,
            ),
          ),
          const SizedBox(width: 8),

          // Notifications
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    size: 22,
                    color: Color(0xFF334155),
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
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
  // HOME FEED
  // ------------------------------------------------------------
  Widget _buildHomeFeed() {
    if (_isLoadingProfile) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        ),
      );
    }

    final earlyAccessList =
        (_premiumJobs.isNotEmpty ? _premiumJobs : _recommendedJobs);

    final jobsForRecommendedHorizontal = earlyAccessList.take(10).toList();
    final jobsForLatestHorizontal = _latestJobs.take(10).toList();
    final jobsForNearbyHorizontal = _nearbyJobs.take(10).toList();

    return RefreshIndicator(
      onRefresh: _refreshHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          AIBannerCard(onTap: _openRecommendedJobsPage),
          const SizedBox(height: 14),

          ProfileAndSearchCards(
            profileName: _profileName,
            profileCompletion: _profileCompletion,
            lastUpdatedText: _lastUpdatedText,
            missingDetails: _missingDetails,
            jobsPostedToday: _jobsPostedToday,

            // left card
            onProfileTap: _openProfileEditPage,
            onProfileViewAllTap: _openProfileEditPage,

            // right card
            onJobsTodayViewAllTap: _openJobsPostedTodayPage,
          ),
          const SizedBox(height: 14),

          BoostCard(
            label: "Construction",
            title: "Khilonjiya Construction Service",
            subtitle: "Your trusted construction partner",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConstructionServicesHomePage(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          ExpectedSalaryCard(
            expectedSalaryPerMonth: _expectedSalaryPerMonth,
            onTap: _openExpectedSalaryEditPage,
            onIconTap: _openJobsBySalary,
          ),
          const SizedBox(height: 18),

          // ============================================================
          // RECOMMENDED
          // ============================================================
          SectionHeader(
            title: "Recommended jobs",
            ctaText: "View all",
            onTap: _openRecommendedJobsPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForRecommendedHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForRecommendedHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ============================================================
          // LATEST
          // ============================================================
          SectionHeader(
            title: "Latest jobs",
            ctaText: "View all",
            onTap: _openLatestJobsPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForLatestHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForLatestHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ============================================================
          // NEARBY
          // ============================================================
          SectionHeader(
            title: "Jobs nearby",
            ctaText: "View all",
            onTap: _openJobsNearbyPage,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jobsForNearbyHorizontal.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final job = jobsForNearbyHorizontal[i];

                return JobCardHorizontal(
                  job: job,
                  onTap: () => _openJobDetails(job),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ============================================================
          // TOP COMPANIES
          // ============================================================
          SectionHeader(
            title: "Top companies",
            ctaText: "View all",
            onTap: _openTopCompaniesPage,
          ),
          const SizedBox(height: 10),

          if (_loadingCompanies)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) {
                  return Container(
                    width: 320,
                    decoration: KhilonjiyaUI.cardDecoration(radius: 16),
                  );
                },
              ),
            )
          else if (_topCompanies.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "No companies found",
                style: KhilonjiyaUI.sub,
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _topCompanies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final c = _topCompanies[i];
                  final companyId = c['id']?.toString() ?? '';

                  return CompanyCardHorizontal(
                    company: c,
                    onTap: () => _openCompanyDetails(companyId),
                  );
                },
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      drawer: NaukriDrawer(
        userName: _profileName,
        profileCompletion: _profileCompletion,
        isProActive: _isProActive, // ✅ NEW
        onUpgradeTap: _openSubscriptionPage, // ✅ NEW
        onClose: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(builder: (scaffoldContext) => _buildTopBar(scaffoldContext)),
            Expanded(child: _buildHomeFeed()),
          ],
        ),
      ),
    );
  }
}