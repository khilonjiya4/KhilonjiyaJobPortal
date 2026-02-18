// File: lib/presentation/home_marketplace_feed/widgets/naukri_drawer.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/app_links.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';
import '../../../services/subscription_service.dart';

// Pages (direct open)
import '../job_search_page.dart';
import '../recommended_jobs_page.dart';
import '../saved_jobs_page.dart';
import '../profile_performance_page.dart';
import '../subscription_page.dart';

class NaukriDrawer extends StatefulWidget {
  final String userName;
  final int profileCompletion;
  final VoidCallback onClose;

  const NaukriDrawer({
    Key? key,
    required this.userName,
    required this.profileCompletion,
    required this.onClose,
  }) : super(key: key);

  @override
  State<NaukriDrawer> createState() => _NaukriDrawerState();
}

class _NaukriDrawerState extends State<NaukriDrawer> {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _loadingPro = true;
  bool _isProActive = false;

  @override
  void initState() {
    super.initState();
    _loadProStatus();
  }

  Future<void> _loadProStatus() async {
    try {
      final active = await _subscriptionService.isProActive();
      if (!mounted) return;

      setState(() {
        _isProActive = active;
        _loadingPro = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isProActive = false;
        _loadingPro = false;
      });
    }
  }

  // ------------------------------------------------------------
  // NAME LOGIC
  // ------------------------------------------------------------
  bool _isFakeUserName(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return true;

    // Supabase default: user<mobile>
    if (n.startsWith("user")) return true;

    // numeric only
    if (RegExp(r'^\d+$').hasMatch(n)) return true;

    return false;
  }

  String _displayName(String rawName) {
    final name = rawName.trim();
    if (_isFakeUserName(name)) return "Your Profile";

    final firstName = name.split(" ").first.trim();
    if (firstName.isEmpty) return "Your Profile";

    return "$firstName's Profile";
  }

  // ------------------------------------------------------------
  // NAV HELPERS
  // ------------------------------------------------------------
  void _closeDrawer() {
    Navigator.pop(context);
  }

  Future<void> _pushNamed(String routeName, {Object? args}) async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(routeName, arguments: args);
  }

  Future<void> _pushPage(Widget page) async {
    _closeDrawer();
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout() async {
    try {
      await MobileAuthService().logout();
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // PLAYSTORE LIKE
  // ------------------------------------------------------------
  Future<void> _openPlayStore() async {
    final url = AppLinks.playStoreUrl.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  // ------------------------------------------------------------
  // PRO CARD
  // ------------------------------------------------------------
  Future<void> _openSubscription() async {
    await _pushPage(const SubscriptionPage());

    // refresh pro status when user comes back
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _loadProStatus();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profileCompletion.clamp(0, 100);
    final value = p / 100;

    final headerName = _displayName(widget.userName);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------------
            // HEADER
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 4,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  KhilonjiyaUI.primary,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "$p%",
                                style: KhilonjiyaUI.sub.copyWith(
                                  color: KhilonjiyaUI.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: InkWell(
                          onTap: () => _pushNamed(AppRoutes.profileEdit),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  headerName,
                                  style: KhilonjiyaUI.hTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Update profile",
                                  style: KhilonjiyaUI.link.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ------------------------------------------------------------
                  // PRO CARD
                  // ------------------------------------------------------------
                  if (_loadingPro)
                    Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: KhilonjiyaUI.r16,
                        border: Border.all(color: KhilonjiyaUI.border),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: _openSubscription,
                      borderRadius: KhilonjiyaUI.r16,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isProActive
                                ? const [
                                    Color(0xFFECFDF5),
                                    Color(0xFFF0FDF4),
                                  ]
                                : const [
                                    Color(0xFFEFF6FF),
                                    Color(0xFFF5F3FF),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: KhilonjiyaUI.r16,
                          border: Border.all(
                            color: _isProActive
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFDBEAFE),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: KhilonjiyaUI.border),
                              ),
                              child: Icon(
                                _isProActive
                                    ? Icons.verified_rounded
                                    : Icons.workspace_premium_outlined,
                                color: _isProActive
                                    ? const Color(0xFF16A34A)
                                    : KhilonjiyaUI.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isProActive
                                        ? "Khilonjiya Pro"
                                        : "Upgrade to Khilonjiya Pro",
                                    style: KhilonjiyaUI.body.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isProActive
                                        ? "Subscription Active"
                                        : "Unlock premium jobs",
                                    style: KhilonjiyaUI.sub.copyWith(
                                      fontSize: 12.2,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: KhilonjiyaUI.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // MENU
            // ------------------------------------------------------------
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),

                  _menuItem(
                    icon: Icons.search,
                    title: "Search jobs",
                    onTap: () => _pushPage(const JobSearchPage()),
                  ),

                  _menuItem(
                    icon: Icons.star_outline,
                    title: "Recommended jobs",
                    onTap: () => _pushPage(const RecommendedJobsPage()),
                  ),

                  _menuItem(
                    icon: Icons.bookmark_outline,
                    title: "Saved jobs",
                    onTap: () => _pushPage(const SavedJobsPage()),
                  ),

                  _menuItem(
                    icon: Icons.person_outline,
                    title: "Profile performance",
                    onTap: () => _pushPage(const ProfilePerformancePage()),
                  ),

                  const SizedBox(height: 8),
                  Container(height: 10, color: const Color(0xFFF7F8FA)),
                  const SizedBox(height: 8),

                  _menuItem(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () => _pushNamed(AppRoutes.settings),
                  ),

                  // You DO NOT have AppRoutes.help in your routes.
                  // So we open Contact & Support (real page you already have).
                  _menuItem(
                    icon: Icons.help_outline_rounded,
                    title: "Help",
                    onTap: () => _pushNamed(AppRoutes.contactSupport),
                  ),

                  const SizedBox(height: 8),
                  Container(height: 10, color: const Color(0xFFF7F8FA)),
                  const SizedBox(height: 8),

                  _menuItem(
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    titleColor: const Color(0xFFEF4444),
                    iconColor: const Color(0xFFEF4444),
                    trailing: const SizedBox.shrink(),
                    onTap: _logout,
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ------------------------------------------------------------
            // FEEDBACK STRIP
            // ------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Finding this app useful?",
                      style: KhilonjiyaUI.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _openPlayStore,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: KhilonjiyaUI.border),
                      ),
                      child: const Icon(
                        Icons.thumb_up_outlined,
                        size: 20,
                        color: Color(0xFF475569),
                      ),
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

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _menuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? badge,
    Widget? trailing,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? badgeBorderColor,
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: KhilonjiyaUI.r16,
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: iconColor ?? const Color(0xFF334155),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? KhilonjiyaUI.text,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: badgeBorderColor ?? const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w900,
                      color: badgeTextColor ?? KhilonjiyaUI.primary,
                    ),
                  ),
                )
              else
                (trailing ??
                    const Icon(
                      Icons.chevron_right,
                      color: KhilonjiyaUI.muted,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}