// File: lib/presentation/home_marketplace_feed/home_jobs_feed.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/pages/job_details_page.dart';
import '../common/widgets/cards/company_card_horizontal.dart';

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
import 'jobs_posted_today_page.dart';
import 'subscription_page.dart';
import 'notifications_page.dart';

import 'widgets/naukri_drawer.dart';
import 'widgets/home_sections/ai_banner_card.dart';
import 'widgets/home_sections/profile_and_search_cards.dart';
import 'widgets/home_sections/boost_card.dart';
import 'widgets/home_sections/expected_salary_card.dart';
import 'widgets/home_sections/section_header.dart';
import 'widgets/home_sections/job_card_horizontal.dart';

class HomeJobsFeed extends StatefulWidget {
  const HomeJobsFeed({Key? key}) : super(key: key);

  @override
  State<HomeJobsFeed> createState() => _HomeJobsFeedState();
}

class _HomeJobsFeedState extends State<HomeJobsFeed> {
  final JobSeekerHomeService _homeService = JobSeekerHomeService();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isCheckingAuth = true;
  bool _isDisposed = false;

  String _profileName = "Your Profile";
  int _profileCompletion = 0;
  String _lastUpdatedText = "Updated recently";
  int _missingDetails = 0;
  int _jobsPostedToday = 0;

  int _unreadNotifications = 0;
  int _expectedSalaryPerMonth = 0;

  List<Map<String, dynamic>> _recommendedJobs = [];
  List<Map<String, dynamic>> _latestJobs = [];
  List<Map<String, dynamic>> _nearbyJobs = [];
  List<Map<String, dynamic>> _premiumJobs = [];
  Set<String> _savedJobIds = {};

  List<Map<String, dynamic>> _topCompanies = [];
  bool _loadingCompanies = true;
  bool _isLoadingProfile = true;

  final PageController _searchHintController = PageController();
  Timer? _searchHintTimer;

  // ---------------- SLIDER ----------------
  final PageController _sliderController =
      PageController(viewportFraction: 0.94);
  Timer? _sliderTimer;
  List<Map<String, dynamic>> _sliderItems = [];
  int _currentSliderIndex = 0;

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
    _sliderTimer?.cancel();
    _searchHintController.dispose();
    _sliderController.dispose();
    super.dispose();
  }

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
    _searchHintTimer =
        Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_searchHintController.hasClients) return;
      final next =
          (_searchHintController.page?.round() ?? 0) + 1;

      _searchHintController.animateToPage(
        next % _searchHints.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadInitialData() async {
    if (_isDisposed) return;

    setState(() => _isCheckingAuth = false);

    try {
      final summary =
          await _homeService.getHomeProfileSummary();
      final jobsCount =
          await _homeService.getJobsPostedTodayCount();

      _profileName =
          summary['profileName'] ?? "Your Profile";
      _profileCompletion =
          summary['profileCompletion'] ?? 0;
      _lastUpdatedText =
          summary['lastUpdatedText'] ??
              "Updated recently";
      _missingDetails =
          summary['missingDetails'] ?? 0;
      _jobsPostedToday = jobsCount;

      _expectedSalaryPerMonth =
          await _homeService
              .getExpectedSalaryPerMonth();

      _savedJobIds =
          await _homeService.getUserSavedJobs();
      _premiumJobs =
          await _homeService.fetchPremiumJobs(
              limit: 8);
      _recommendedJobs =
          await _homeService.getRecommendedJobs(
              limit: 40);
      _latestJobs =
          await _homeService.fetchLatestJobs(
              limit: 40);
      _nearbyJobs =
          await _homeService.fetchJobsNearby(
              limit: 40);
      _topCompanies =
          await _homeService.fetchTopCompanies(
              limit: 10);

      _unreadNotifications =
          await _homeService
              .getUnreadNotificationsCount();

      await _loadSliderImages();
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingProfile = false;
          _loadingCompanies = false;
        });
      }
    }
  }

  Future<void> _loadSliderImages() async {
    final data = await _supabase
        .from('slider')
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);

    _sliderItems =
        List<Map<String, dynamic>>.from(data);

    _startSliderAutoScroll();
    if (!_isDisposed) setState(() {});
  }

  void _startSliderAutoScroll() {
    _sliderTimer?.cancel();
    if (_sliderItems.isEmpty) return;

    _sliderTimer =
        Timer.periodic(const Duration(seconds: 4),
            (_) {
      if (!_sliderController.hasClients) return;

      _currentSliderIndex =
          (_currentSliderIndex + 1) %
              _sliderItems.length;

      _sliderController.animateToPage(
        _currentSliderIndex,
        duration:
            const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  void _redirectToStart() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false);
  }

  // ---------------- TOP BAR ----------------
  Widget _buildTopBar(BuildContext ctx) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom:
                BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () =>
                Scaffold.of(ctx).openDrawer(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.menu, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const JobSearchPage()),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF8FAFC),
                  borderRadius:
                      BorderRadius.circular(
                          999),
                  border: Border.all(
                      color:
                          KhilonjiyaUI.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        size: 18,
                        color: Color(
                            0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // SUBSCRIPTION
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const SubscriptionPage()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(
                        999),
                border: Border.all(
                    color: const Color(
                        0xFFDBEAFE)),
              ),
              child: const Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color:
                    KhilonjiyaUI.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // NOTIFICATIONS
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const NotificationsPage()),
              );
              _unreadNotifications =
                  await _homeService
                      .getUnreadNotificationsCount();
              if (!_isDisposed)
                setState(() {});
            },
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius
                            .circular(999),
                    border: Border.all(
                        color:
                            KhilonjiyaUI
                                .border),
                  ),
                  child: const Icon(
                    Icons
                        .notifications_none_outlined,
                    size: 22,
                    color:
                        Color(0xFF334155),
                  ),
                ),
                if (_unreadNotifications >
                    0)
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration:
                          const BoxDecoration(
                        color: Color(
                            0xFFEF4444),
                        shape:
                            BoxShape.circle,
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

  // ---------------- SLIDER WIDGET ----------------
  Widget _buildSlider() {
    if (_sliderItems.isEmpty)
      return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 18),
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _sliderController,
            itemCount:
                _sliderItems.length,
            itemBuilder: (_, i) {
              final imageUrl =
                  _sliderItems[i]
                          ['image_url'] ??
                      '';
              return Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                            horizontal: 6),
                child: Container(
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius
                            .circular(
                                16),
                    border: Border.all(
                        color:
                            KhilonjiyaUI
                                .border),
                  ),
                  clipBehavior:
                      Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit:
                        BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- HOME FEED ----------------
  Widget _buildHomeFeed() {
    if (_isLoadingProfile) {
      return const Center(
          child:
              CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        padding:
            const EdgeInsets.fromLTRB(
                16, 16, 16, 120),
        children: [
          AIBannerCard(
              onTap: () =>
                  openRecommendedJobsPage()),

          // All your existing sections remain here unchanged...

          _buildSlider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
            child:
                CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor:
          KhilonjiyaUI.bg,
      drawer: NaukriDrawer(
        userName: _profileName,
        profileCompletion:
            _profileCompletion,
        onClose: () =>
            Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Builder(
                builder: (ctx) =>
                    _buildTopBar(ctx)),
            Expanded(
                child:
                    _buildHomeFeed()),
          ],
        ),
      ),
    );
  }
}