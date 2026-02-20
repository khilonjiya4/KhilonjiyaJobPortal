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
import 'jobs_posted_today_page.dart';
import 'construction_services_home_page.dart';
import 'profile_edit_page.dart';
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

  // ---------------- SLIDER ----------------
  List<Map<String, dynamic>> _sliderItems = [];
  final PageController _bottomSliderController = PageController();
  Timer? _bottomSliderTimer;

  // ---------------- SEARCH HINT ----------------
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
    _bottomSliderTimer?.cancel();
    _searchHintController.dispose();
    _bottomSliderController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------
  Future<void> _initialize() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _redirectToStart();
      return;
    }

    await _loadInitialData();
    _startSearchHintAutoSlide();
    _startBottomSlider();
  }

  void _startSearchHintAutoSlide() {
    _searchHintTimer?.cancel();
    _searchHintTimer =
        Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isDisposed) return;
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

  void _startBottomSlider() {
    _bottomSliderTimer?.cancel();
    _bottomSliderTimer =
        Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isDisposed) return;
      if (!_bottomSliderController.hasClients) return;
      if (_sliderItems.isEmpty) return;

      final next =
          (_bottomSliderController.page?.round() ?? 0) + 1;

      _bottomSliderController.animateToPage(
        next % _sliderItems.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isCheckingAuth = false);

    try {
      final summary =
          await _homeService.getHomeProfileSummary();
      final jobsCount =
          await _homeService.getJobsPostedTodayCount();

      _profileName =
          (summary['profileName'] ?? "").toString();
      _profileCompletion =
          (summary['profileCompletion'] ?? 0) as int;
      _lastUpdatedText =
          (summary['lastUpdatedText'] ?? "").toString();
      _missingDetails =
          (summary['missingDetails'] ?? 0) as int;
      _jobsPostedToday = jobsCount;

      _expectedSalaryPerMonth =
          await _homeService.getExpectedSalaryPerMonth();

      _savedJobIds =
          await _homeService.getUserSavedJobs();

      _premiumJobs =
          await _homeService.fetchPremiumJobs(limit: 8);

      _recommendedJobs =
          await _homeService.getRecommendedJobs(limit: 40);

      _latestJobs =
          await _homeService.fetchLatestJobs(limit: 40);

      _nearbyJobs =
          await _homeService.fetchJobsNearby(limit: 40);

      _topCompanies =
          await _homeService.fetchTopCompanies(limit: 10);

      _unreadNotifications =
          await _homeService.getUnreadNotificationsCount();

      // Load slider images from DB table: slider
      final sliders = await _supabase
          .from('slider')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _sliderItems =
          List<Map<String, dynamic>>.from(sliders);

    } finally {
      if (!_isDisposed) {
        setState(() {
          _isLoadingProfile = false;
          _loadingCompanies = false;
        });
      }
    }
  }

  void _redirectToStart() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // TOP BAR
  // ------------------------------------------------------------
  Widget _buildTopBar(BuildContext scaffoldContext) {
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
                Scaffold.of(scaffoldContext)
                    .openDrawer(),
            borderRadius:
                BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child:
                  Icon(Icons.menu, size: 22),
            ),
          ),
          const Spacer(),

          // PREMIUM ICON
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SubscriptionPage(),
                ),
              );
            },
            borderRadius:
                BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFEFF6FF),
                borderRadius:
                    BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons
                    .auto_awesome_outlined,
                size: 20,
                color:
                    KhilonjiyaUI.primary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // NOTIFICATIONS
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationsPage(),
                ),
              );
            },
            borderRadius:
                BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                            999),
                    border: Border.all(
                        color:
                            KhilonjiyaUI
                                .border),
                  ),
                  child: const Icon(
                      Icons
                          .notifications_none_outlined),
                ),
                if (_unreadNotifications >
                    0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFEF4444),
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

  // ------------------------------------------------------------
  // SLIDER
  // ------------------------------------------------------------
  Widget _buildBottomSlider() {
    if (_sliderItems.isEmpty)
      return const SizedBox();

    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller:
            _bottomSliderController,
        itemCount:
            _sliderItems.length,
        itemBuilder: (_, i) {
          final item =
              _sliderItems[i];
          final image =
              (item['image_url'] ?? '')
                  .toString();

          return Container(
            margin: const EdgeInsets
                .only(right: 12),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                      18),
              border: Border.all(
                  color:
                      KhilonjiyaUI
                          .border),
            ),
            clipBehavior:
                Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  image,
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.white
                      .withOpacity(
                          0.18),
                ),
              ],
            ),
          );
        },
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
                builder:
                    (scaffoldContext) =>
                        _buildTopBar(
                            scaffoldContext)),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                            16,
                            16,
                            16,
                            120),
                children: [
                  const SizedBox(
                      height: 20),

                  // YOUR EXISTING SECTIONS REMAIN AS THEY WERE

                  const SizedBox(
                      height: 20),

                  _buildBottomSlider(),

                  const SizedBox(
                      height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}