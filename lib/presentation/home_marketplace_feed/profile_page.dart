import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  bool _disposed = false;

  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      final p = await _service.fetchMyProfile();
      _profile = p;
    } catch (_) {
      _profile = {};
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  String _salaryText(int v) {
    if (v <= 0) return "Not set";
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L / month";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(0)}k / month";
    return "₹$v / month";
  }

  String _experienceText(int years) {
    if (years <= 0) return "Fresher";
    if (years == 1) return "1 year";
    return "$years years";
  }

  String _skillsText(dynamic skills) {
    if (skills is List) {
      final list = skills
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isEmpty) return "Not set";
      if (list.length <= 3) return list.join(", ");
      return "${list.take(3).join(", ")} +${list.length - 3}";
    }
    return "Not set";
  }

  String _locationText() {
    final city = _s(_profile['current_city']);
    final state = _s(_profile['current_state']);
    if (city.isNotEmpty && state.isNotEmpty) return "$city, $state";
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    return "Not set";
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );
    await _load();
  }

  // ============================================================
  // SLIM TILE (Like Job Card Feel)
  // ============================================================

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: KhilonjiyaUI.cardDecoration(radius: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: KhilonjiyaUI.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KhilonjiyaUI.caption.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value.isEmpty ? "—" : value,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _profileHeader() {
    final fullName = _s(_profile["full_name"]);
    final completion =
        _i(_profile["profile_completion_percentage"]).clamp(0, 100);
    final avatarUrl = _s(_profile['avatar_url']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFF1F5F9),
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person_outline,
                      color: Color(0xFF64748B))
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? "Your Profile" : fullName,
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$completion% complete",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _body() {
    final salary = _i(_profile['expected_salary_min']);
    final expYears = _i(_profile['total_experience_years']);
    final edu = _s(_profile['highest_education']);
    final openToWork = _b(_profile['is_open_to_work']);
    final resumeUrl = _s(_profile['resume_url']);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _profileHeader(),
          const SizedBox(height: 14),

          _infoTile(
            icon: Icons.currency_rupee_rounded,
            title: "Expected salary",
            value: _salaryText(salary),
          ),
          _infoTile(
            icon: Icons.work_outline_rounded,
            title: "Experience",
            value: _experienceText(expYears),
          ),
          _infoTile(
            icon: Icons.school_outlined,
            title: "Highest education",
            value: edu.isEmpty ? "Not set" : edu,
          ),
          _infoTile(
            icon: Icons.location_on_outlined,
            title: "Location",
            value: _locationText(),
          ),
          _infoTile(
            icon: Icons.psychology_alt_outlined,
            title: "Skills",
            value: _skillsText(_profile['skills']),
          ),
          _infoTile(
            icon: Icons.flag_outlined,
            title: "Open to work",
            value: openToWork ? "Yes" : "No",
          ),
          _infoTile(
            icon: Icons.description_outlined,
            title: "Resume",
            value: resumeUrl.isEmpty ? "Not uploaded" : "View resume",
            onTap: resumeUrl.isEmpty ? null : () => _openUrl(resumeUrl),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLIM BUTTON
  // ============================================================

  Widget _updateButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 40, // slimmer
          child: ElevatedButton(
            onPressed: _openEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Update Profile",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text("Profile",
                        style: KhilonjiyaUI.hTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  IconButton(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),
            _updateButton(),
          ],
        ),
      ),
    );
  }
}