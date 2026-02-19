import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/app_links.dart';
import '../../../core/ui/khilonjiya_ui.dart';
import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';
import '../../../services/subscription_service.dart';

// Pages
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

  bool _isFakeUserName(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return true;
    if (n.startsWith("user")) return true;
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

  Future<void> _openPlayStore() async {
    final url = AppLinks.playStoreUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openSubscription() async {
    await _pushPage(const SubscriptionPage());
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
            // ================= HEADER =================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 3,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  KhilonjiyaUI.primary,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "$p%",
                                style: KhilonjiyaUI.sub.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: KhilonjiyaUI.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pushNamed(AppRoutes.profileEdit),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                headerName,
                                style: KhilonjiyaUI.body.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Update profile",
                                style: KhilonjiyaUI.sub.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // PRO SECTION (SLIM)
                  if (!_loadingPro)
                    InkWell(
                      onTap: _openSubscription,
                      child: Row(
                        children: [
                          Icon(
                            _isProActive
                                ? Icons.verified_rounded
                                : Icons.workspace_premium_outlined,
                            size: 20,
                            color: _isProActive
                                ? const Color(0xFF16A34A)
                                : KhilonjiyaUI.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isProActive
                                  ? "Khilonjiya Pro Active"
                                  : "Upgrade to Khilonjiya Pro",
                              style: KhilonjiyaUI.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: KhilonjiyaUI.muted,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ================= MENU =================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  _menuItem(Icons.search, "Search jobs",
                      () => _pushPage(const JobSearchPage())),
                  _menuItem(Icons.star_outline, "Recommended jobs",
                      () => _pushPage(const RecommendedJobsPage())),
                  _menuItem(Icons.bookmark_border, "Saved jobs",
                      () => _pushPage(const SavedJobsPage())),
                  _menuItem(Icons.person_outline, "Profile performance",
                      () => _pushPage(const ProfilePerformancePage())),
                  const Divider(),
                  _menuItem(Icons.settings_outlined, "Settings",
                      () => _pushNamed(AppRoutes.settings)),
                  _menuItem(Icons.help_outline, "Help",
                      () => _pushNamed(AppRoutes.contactSupport)),
                  const Divider(),
                  _menuItem(Icons.logout_rounded, "Logout", _logout,
                      titleColor: const Color(0xFFEF4444),
                      iconColor: const Color(0xFFEF4444)),
                ],
              ),
            ),

            // ================= FOOTER =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Finding this app useful?",
                      style: KhilonjiyaUI.sub.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _openPlayStore,
                    icon: const Icon(Icons.thumb_up_outlined, size: 20),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? titleColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? const Color(0xFF334155),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: KhilonjiyaUI.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? KhilonjiyaUI.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}