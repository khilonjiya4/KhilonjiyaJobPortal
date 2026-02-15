import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../routes/app_routes.dart';
import '../../../services/mobile_auth_service.dart';

// Existing pages (your folder)
import '../job_search_page.dart';
import '../recommended_jobs_page.dart';
import '../saved_jobs_page.dart';
import '../profile_performance_page.dart';
import '../profile_edit_page.dart';

// ✅ NEW PAGES
import '../settings_page.dart';
import '../help_page.dart';

class NaukriDrawer extends StatelessWidget {
  final String userName;
  final int profileCompletion;
  final VoidCallback onClose;

  const NaukriDrawer({
    Key? key,
    required this.userName,
    required this.profileCompletion,
    required this.onClose,
  }) : super(key: key);

  // ------------------------------------------------------------
  // NAV HELPERS
  // ------------------------------------------------------------
  void _closeDrawer(BuildContext context) {
    Navigator.pop(context);
  }

  void _openPage(BuildContext context, Widget page) {
    _closeDrawer(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await MobileAuthService().logout();
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.roleSelection,
      (_) => false,
    );
  }

  // ------------------------------------------------------------
  // HEADER ACTIONS
  // ------------------------------------------------------------
  void _openUpdateProfile(BuildContext context) {
    _openPage(context, const ProfileEditPage());
  }

  void _openUpgrade(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Khilonjiya Pro coming soon")),
    );
  }

  // ------------------------------------------------------------
  // MENU ACTIONS
  // ------------------------------------------------------------
  void _openSearch(BuildContext context) {
    _openPage(context, const JobSearchPage());
  }

  void _openRecommended(BuildContext context) {
    _openPage(context, const RecommendedJobsPage());
  }

  void _openSaved(BuildContext context) {
    _openPage(context, const SavedJobsPage());
  }

  void _openProfilePerformance(BuildContext context) {
    _openPage(context, const ProfilePerformancePage());
  }

  // ✅ NEW
  void _openSettings(BuildContext context) {
    _openPage(context, const SettingsPage());
  }

  void _openHelp(BuildContext context) {
    _openPage(context, const HelpPage());
  }

  @override
  Widget build(BuildContext context) {
    final p = profileCompletion.clamp(0, 100);
    final value = p / 100;

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
                          onTap: () => _openUpdateProfile(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName.isEmpty ? "User" : userName,
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
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () => _openUpgrade(context),
                    borderRadius: KhilonjiyaUI.r16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: KhilonjiyaUI.r16,
                        border: Border.all(color: const Color(0xFFDBEAFE)),
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
                            child: const Icon(
                              Icons.workspace_premium_outlined,
                              color: KhilonjiyaUI.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Upgrade to Khilonjiya Pro",
                              style: KhilonjiyaUI.body.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
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
                    context,
                    icon: Icons.search,
                    title: "Search jobs",
                    onTap: () => _openSearch(context),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.star_outline,
                    title: "Recommended jobs",
                    onTap: () => _openRecommended(context),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.bookmark_outline,
                    title: "Saved jobs",
                    onTap: () => _openSaved(context),
                  ),

                  _menuItem(
                    context,
                    icon: Icons.person_outline,
                    title: "Profile performance",
                    onTap: () => _openProfilePerformance(context),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    height: 10,
                    color: const Color(0xFFF7F8FA),
                  ),

                  const SizedBox(height: 8),

                  // ✅ SETTINGS
                  _menuItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () => _openSettings(context),
                  ),

                  // ✅ HELP
                  _menuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: "Help",
                    onTap: () => _openHelp(context),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    height: 10,
                    color: const Color(0xFFF7F8FA),
                  ),

                  const SizedBox(height: 8),

                  // ------------------------------------------------------------
                  // LOGOUT (BOTTOM)
                  // ------------------------------------------------------------
                  _menuItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: "Logout",
                    titleColor: const Color(0xFFEF4444),
                    iconColor: const Color(0xFFEF4444),
                    trailing: const SizedBox.shrink(),
                    onTap: () => _logout(context),
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
                  _feedbackBtn(Icons.thumb_up_outlined),
                  const SizedBox(width: 10),
                  _feedbackBtn(Icons.thumb_down_outlined),
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
  Widget _menuItem(
    BuildContext context, {
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

  Widget _feedbackBtn(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF475569)),
    );
  }
}