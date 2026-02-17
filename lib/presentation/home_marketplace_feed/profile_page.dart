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

  // ============================================================
  // LOAD
  // ============================================================

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

  // ============================================================
  // HELPERS
  // ============================================================

  String _s(dynamic v) => (v ?? '').toString().trim();

  int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  bool _b(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
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
    if (skills == null) return "Not set";
    if (skills is List) {
      final list = skills
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isEmpty) return "Not set";
      if (list.length <= 3) return list.join(", ");
      return "${list.take(3).join(", ")} +${list.length - 3} more";
    }
    final s = skills.toString().trim();
    return s.isEmpty ? "Not set" : s;
  }

  String _listText(dynamic v) {
    if (v == null) return "";
    if (v is List) {
      final list = v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      return list.join(", ");
    }
    return v.toString().trim();
  }

  String _locationText() {
    final city = _s(_profile['current_city']);
    final state = _s(_profile['current_state']);
    final locText = _s(_profile['location_text'] ?? _profile['location']);

    if (city.isNotEmpty && state.isNotEmpty) return "$city, $state";
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;
    if (locText.isNotEmpty) return locText;

    return "Not set";
  }

  String _lastUpdatedText() {
    final raw = _s(_profile['last_profile_update']);
    if (raw.isEmpty) return "Updated recently";

    final d = DateTime.tryParse(raw);
    if (d == null) return "Updated recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "Updated just now";
    if (diff.inHours < 24) return "Updated today";
    if (diff.inDays == 1) return "Updated 1d ago";
    if (diff.inDays < 7) return "Updated ${diff.inDays}d ago";
    if (diff.inDays < 30) return "Updated ${(diff.inDays / 7).floor()}w ago";

    return "Updated ${(diff.inDays / 30).floor()}mo ago";
  }

  Future<void> _openUrl(String url) async {
    final u = url.trim();
    if (u.isEmpty) return;

    final uri = Uri.tryParse(u);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open link")),
      );
    }
  }

  // ============================================================
  // NAV
  // ============================================================

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditPage()),
    );

    await _load();
  }

  // ============================================================
  // UI PARTS
  // ============================================================

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final v = value.trim().isEmpty ? "—" : value.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: KhilonjiyaUI.cardDecoration(radius: 18),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: KhilonjiyaUI.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: Icon(icon, color: KhilonjiyaUI.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KhilonjiyaUI.caption),
                  const SizedBox(height: 4),
                  Text(
                    v,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _profileHeader() {
    final fullName = _s(_profile["full_name"]);
    final completion =
        _i(_profile["profile_completion_percentage"]).clamp(0, 100);
    final value = completion / 100;

    final name = fullName.isEmpty ? "Your Profile" : fullName;
    final lastUpdate = _lastUpdatedText();

    final avatarUrl = _s(_profile['avatar_url']);

    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KhilonjiyaUI.primary,
                    ),
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: KhilonjiyaUI.border),
                      ),
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person_outline,
                              color: Color(0xFF64748B))
                          : Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(Icons.person_outline,
                                    color: Color(0xFF64748B));
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.hTitle.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lastUpdate,
                  style: KhilonjiyaUI.sub.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: Text(
                    completion >= 100
                        ? "Profile complete"
                        : "Complete your profile for better matches",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.2,
                      color: completion >= 100
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF0F172A),
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

  Widget _profileTipsCard() {
    final bio = _s(_profile['bio']);
    final skills = _skillsText(_profile['skills']);
    final edu = _s(_profile['highest_education']);
    final salary = _i(_profile['expected_salary_min']);

    final missing = <String>[];

    if (bio.isEmpty) missing.add("Bio");
    if (skills == "Not set") missing.add("Skills");
    if (edu.isEmpty) missing.add("Education");
    if (salary <= 0) missing.add("Expected salary");

    final headline =
        missing.isEmpty ? "Your profile looks strong" : "Improve your profile";

    final sub = missing.isEmpty
        ? "Employers are more likely to shortlist complete profiles."
        : "Add ${missing.take(3).join(", ")} to get better job matches.";

    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: KhilonjiyaUI.hTitle),
          const SizedBox(height: 6),
          Text(sub, style: KhilonjiyaUI.sub),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KhilonjiyaUI.border),
            ),
            child: Row(
              children: [
                Icon(
                  missing.isEmpty
                      ? Icons.verified_outlined
                      : Icons.auto_awesome_rounded,
                  color: missing.isEmpty
                      ? const Color(0xFF16A34A)
                      : KhilonjiyaUI.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    missing.isEmpty
                        ? "You’re ready for better recommendations."
                        : "Tip: Completing profile increases shortlisting chances.",
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.2,
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

  Widget _updateButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _openEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Update Profile",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final salary = _i(_profile['expected_salary_min']);
    final expYears = _i(_profile['total_experience_years']);
    final edu = _s(_profile['highest_education']);
    final notice = _i(_profile['notice_period_days']);

    final jobType = _s(_profile['preferred_job_type']);
    final preferredLocations = _listText(_profile['preferred_locations']);

    final openToWork = _b(_profile['is_open_to_work']);

    final resumeUrl = _s(_profile['resume_url']);
    final resumeHeadline = _s(_profile['resume_headline']);

    final currentJobTitle = _s(_profile['current_job_title']);
    final currentCompany = _s(_profile['current_company']);

    final prefs = <String>[];
    if (jobType.isNotEmpty && jobType != "Any") prefs.add(jobType);
    if (notice > 0) prefs.add("$notice days notice");

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _profileHeader(),
          const SizedBox(height: 14),

          Text(
            "Quick details",
            style: KhilonjiyaUI.hTitle.copyWith(fontSize: 14.8),
          ),
          const SizedBox(height: 10),

          _infoTile(
            icon: Icons.currency_rupee_rounded,
            title: "Expected salary",
            value: _salaryText(salary),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.work_outline_rounded,
            title: "Experience",
            value: _experienceText(expYears),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.school_outlined,
            title: "Highest education",
            value: edu.isEmpty ? "Not set" : edu,
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.location_on_outlined,
            title: "Current location",
            value: _locationText(),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.psychology_alt_outlined,
            title: "Skills",
            value: _skillsText(_profile['skills']),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.tune_rounded,
            title: "Job preferences",
            value: prefs.isEmpty ? "Not set" : prefs.join(" • "),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.my_location_outlined,
            title: "Preferred locations",
            value: preferredLocations.isEmpty ? "Not set" : preferredLocations,
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: openToWork ? Icons.check_circle_outline : Icons.pause_circle_outline,
            title: "Open to work",
            value: openToWork ? "Yes" : "No",
          ),
          const SizedBox(height: 12),

          if (currentJobTitle.isNotEmpty || currentCompany.isNotEmpty) ...[
            _infoTile(
              icon: Icons.badge_outlined,
              title: "Current work",
              value: [
                if (currentJobTitle.isNotEmpty) currentJobTitle,
                if (currentCompany.isNotEmpty) currentCompany,
              ].join(" • "),
            ),
            const SizedBox(height: 12),
          ],

          _infoTile(
            icon: Icons.description_outlined,
            title: "Resume",
            value: resumeUrl.isEmpty ? "Not uploaded" : "Uploaded",
            onTap: resumeUrl.isEmpty ? null : () => _openUrl(resumeUrl),
            trailing: resumeUrl.isEmpty
                ? null
                : const Icon(Icons.open_in_new_rounded, size: 18),
          ),
          const SizedBox(height: 12),

          if (resumeHeadline.isNotEmpty) ...[
            _infoTile(
              icon: Icons.short_text_rounded,
              title: "Resume headline",
              value: resumeHeadline,
            ),
            const SizedBox(height: 12),
          ],

          _infoTile(
            icon: Icons.phone_outlined,
            title: "Mobile number",
            value: _s(_profile['mobile_number']),
          ),
          const SizedBox(height: 12),

          _infoTile(
            icon: Icons.email_outlined,
            title: "Email",
            value: _s(_profile['email']),
          ),

          const SizedBox(height: 16),

          _profileTipsCard(),
          const SizedBox(height: 18),
        ],
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text("Profile", style: KhilonjiyaUI.hTitle),
                  ),
                  IconButton(
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_outlined),
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