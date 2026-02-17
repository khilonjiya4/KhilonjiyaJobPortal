// File: lib/presentation/profile/profile_edit_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _loading = true;
  bool _saving = false;
  bool _disposed = false;

  Map<String, dynamic> _profile = {};

  // ------------------------------------------------------------
  // Controllers
  // ------------------------------------------------------------
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _experienceYearsCtrl = TextEditingController();
  final _expectedSalaryMinCtrl = TextEditingController();
  final _noticeDaysCtrl = TextEditingController();

  // ------------------------------------------------------------
  // Dropdown / Select values
  // ------------------------------------------------------------

  // district dropdown (from master)
  List<String> _districtOptions = [];
  String _selectedDistrict = '';

  // state (fixed)
  String _selectedState = 'Assam';

  // education dropdown
  final List<String> _educationOptions = const [
    'No education',
    'Below 10th',
    '10th pass',
    '12th pass',
    'ITI',
    'Diploma',
    'Graduate (BA / BCom / BSc)',
    'BTech / BE',
    'BCA',
    'MCA',
    'MBA',
    'MTech / ME',
    'MA',
    'MCom',
    'MSc',
    'PhD',
    'Other',
  ];
  String _selectedEducation = '';

  // job type (schema: preferred_job_types array)
  final List<String> _jobTypeOptions = const [
    'Any',
    'Full-time',
    'Part-time',
    'Internship',
    'Contract',
    'Walk-in',
  ];
  String _jobType = 'Any';

  // preferred locations (district list)
  final List<String> _preferredDistricts = [];

  // open to work
  bool _openToWork = false;

  // ------------------------------------------------------------
  // Skills
  // ------------------------------------------------------------
  final _skillsCtrl = TextEditingController();
  final List<String> _skills = [];

  // quick suggestions (you can later load from skills_master)
  final List<String> _skillSuggestions = const [
    'Sales',
    'Marketing',
    'Customer support',
    'Delivery',
    'Driver',
    'Data entry',
    'Office assistant',
    'Receptionist',
    'Accountant',
    'Electrician',
    'Plumber',
    'Welder',
    'Carpenter',
    'Mason',
    'Painter',
    'Security guard',
    'Cook',
    'Housekeeping',
    'Teacher',
    'Nurse',
    'Pharmacist',
    'Computer operator',
    'Graphic designer',
    'Video editor',
  ];

  // ------------------------------------------------------------
  // Optional files (UI only)
  // ------------------------------------------------------------
  String _resumeName = '';
  String _photoName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;

    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _expectedSalaryMinCtrl.dispose();
    _noticeDaysCtrl.dispose();

    _skillsCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      // 1) district master
      try {
        final d = await _service.fetchAssamDistrictMaster();
        _districtOptions = d
            .map((e) => (e['district_name'] ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        _districtOptions.sort((a, b) => a.compareTo(b));
      } catch (_) {
        _districtOptions = [];
      }

      // 2) profile
      _profile = await _service.fetchMyProfile();

      // text fields
      _fullNameCtrl.text = (_profile['full_name'] ?? '').toString();
      _phoneCtrl.text = (_profile['mobile_number'] ?? _profile['phone'] ?? '')
          .toString();
      _bioCtrl.text = (_profile['bio'] ?? '').toString();

      _experienceYearsCtrl.text =
          (_profile['total_experience_years'] ?? '').toString();

      _expectedSalaryMinCtrl.text =
          (_profile['expected_salary_min'] ?? '').toString();

      _noticeDaysCtrl.text =
          (_profile['notice_period_days'] ?? '').toString();

      // open to work
      _openToWork = (_profile['is_open_to_work'] ?? false) == true;

      // education
      _selectedEducation =
          (_profile['highest_education'] ?? '').toString().trim();
      if (_selectedEducation.isNotEmpty &&
          !_educationOptions.contains(_selectedEducation)) {
        _selectedEducation = 'Other';
      }

      // location
      _selectedState =
          (_profile['current_state'] ?? 'Assam').toString().trim();
      if (_selectedState.isEmpty) _selectedState = 'Assam';

      _selectedDistrict = (_profile['current_city'] ?? '').toString().trim();
      if (_selectedDistrict.isNotEmpty &&
          _districtOptions.isNotEmpty &&
          !_districtOptions.contains(_selectedDistrict)) {
        _selectedDistrict = '';
      }

      // preferred locations (array)
      _preferredDistricts.clear();
      final pl = _profile['preferred_locations'];
      if (pl is List) {
        for (final x in pl) {
          final v = x.toString().trim();
          if (v.isNotEmpty && !_preferredDistricts.contains(v)) {
            _preferredDistricts.add(v);
          }
        }
      }

      // job type
      _jobType = (_profile['preferred_job_type'] ?? 'Any').toString().trim();
      if (!_jobTypeOptions.contains(_jobType)) _jobType = 'Any';

      // skills
      _skills.clear();
      final rawSkills = _profile['skills'];
      if (rawSkills is List) {
        for (final s in rawSkills) {
          final v = s.toString().trim();
          if (v.isNotEmpty) _skills.add(v);
        }
      }

      // resume (existing)
      final resumeUrl = (_profile['resume_url'] ?? '').toString().trim();
      if (resumeUrl.isNotEmpty) {
        _resumeName = "Resume uploaded";
      }

      final avatar = (_profile['avatar_url'] ?? '').toString().trim();
      if (avatar.isNotEmpty) {
        _photoName = "Photo uploaded";
      }
    } catch (_) {
      _profile = {};
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ============================================================
  // SAVE
  // ============================================================

  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      // profile
      'full_name': _fullNameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),

      // location
      'current_city': _selectedDistrict.trim(),
      'current_state': _selectedState.trim(),
      'location_text': '',

      // education / career
      'highest_education': _selectedEducation.trim(),
      'total_experience_years': _toInt(_experienceYearsCtrl.text),

      // salary
      'expected_salary_min': _toInt(_expectedSalaryMinCtrl.text),
      'notice_period_days': _toInt(_noticeDaysCtrl.text),

      // preferences
      'preferred_job_type': _jobType,
      'preferred_locations': _preferredDistricts,

      // open to work
      'is_open_to_work': _openToWork,

      // skills
      'skills': _skills,
    };

    try {
      await _service.updateMyProfile(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  InputDecoration _dec(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: KhilonjiyaUI.sub,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: KhilonjiyaUI.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: KhilonjiyaUI.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: KhilonjiyaUI.primary.withOpacity(0.6),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle.copyWith(fontSize: 15.5)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub, style: KhilonjiyaUI.sub),
          ],
        ],
      ),
    );
  }

  void _addSkill() {
    final raw = _skillsCtrl.text.trim();
    if (raw.isEmpty) return;

    final parts = raw.split(',');
    bool added = false;

    for (final p in parts) {
      final v = p.trim();
      if (v.isEmpty) continue;
      if (_skills.any((e) => e.toLowerCase() == v.toLowerCase())) continue;
      _skills.add(v);
      added = true;
    }

    if (added) {
      _skillsCtrl.clear();
      setState(() {});
    }
  }

  Widget _chip(String text, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownBox({
    required String value,
    required List<String> options,
    required void Function(String) onChanged,
    IconData? icon,
    String hint = '',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF64748B)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value.isEmpty ? null : value,
                hint: Text(hint, style: KhilonjiyaUI.sub),
                isExpanded: true,
                items: options
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: KhilonjiyaUI.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  Widget _skillsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_skills.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _skills
                  .map((s) => _chip(s, () {
                        _skills.remove(s);
                        setState(() {});
                      }))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skillsCtrl,
                  decoration: _dec("Add skills (comma separated)"),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 52,
                child: ElevatedButton(
                  onPressed: _addSkill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhilonjiyaUI.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Suggestions", style: KhilonjiyaUI.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _skillSuggestions.map((s) {
              final exists = _skills.any((e) => e.toLowerCase() == s.toLowerCase());
              return InkWell(
                onTap: exists
                    ? null
                    : () {
                        _skills.add(s);
                        setState(() {});
                      },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: exists ? const Color(0xFFE2E8F0) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: Text(
                    s,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.2,
                      color: exists ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _preferredLocationsBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Preferred districts", style: KhilonjiyaUI.caption),
          const SizedBox(height: 10),

          if (_preferredDistricts.isNotEmpty) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _preferredDistricts
                  .map((d) => _chip(d, () {
                        _preferredDistricts.remove(d);
                        setState(() {});
                      }))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          _dropdownBox(
            value: '',
            options: _districtOptions,
            hint: "Add district",
            icon: Icons.add_location_alt_outlined,
            onChanged: (v) {
              if (!_preferredDistricts.contains(v)) {
                _preferredDistricts.add(v);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _filePickers() {
    return Column(
      children: [
        Container(
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
                child: const Icon(Icons.description_outlined,
                    color: KhilonjiyaUI.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resume (optional)", style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      _resumeName.isEmpty ? "No file selected" : _resumeName,
                      style: KhilonjiyaUI.sub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  // UI only for now
                  setState(() => _resumeName = "Selected resume");
                },
                child: const Text("Pick"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                child: const Icon(Icons.photo_camera_outlined,
                    color: KhilonjiyaUI.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Profile photo (optional)", style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      _photoName.isEmpty ? "No photo selected" : _photoName,
                      style: KhilonjiyaUI.sub,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  // UI only for now
                  setState(() => _photoName = "Selected photo");
                },
                child: const Text("Pick"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _body() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 130 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header card
          Container(
            decoration: KhilonjiyaUI.cardDecoration(radius: 22),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: KhilonjiyaUI.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: KhilonjiyaUI.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Edit your profile", style: KhilonjiyaUI.hTitle),
                      const SizedBox(height: 4),
                      Text(
                        "Fill only what you want. More details = better matches.",
                        style: KhilonjiyaUI.sub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          _sectionTitle("Mobile number", sub: "This is used for job applications."),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _dec("Mobile number", icon: Icons.phone_outlined),
          ),

          _sectionTitle("Basic details"),
          TextField(
            controller: _fullNameCtrl,
            decoration: _dec("Full name (optional)", icon: Icons.badge_outlined),
          ),

          _sectionTitle("Location", sub: "Choose your district for nearby jobs."),
          if (_districtOptions.isNotEmpty) ...[
            _dropdownBox(
              value: _selectedDistrict,
              options: _districtOptions,
              hint: "Select district",
              icon: Icons.location_on_outlined,
              onChanged: (v) => setState(() => _selectedDistrict = v),
            ),
          ] else ...[
            TextField(
              decoration: _dec("District (optional)", icon: Icons.location_on_outlined),
              onChanged: (v) => _selectedDistrict = v.trim(),
            ),
          ],
          const SizedBox(height: 12),
          _dropdownBox(
            value: _selectedState,
            options: const ['Assam'],
            hint: "Select state",
            icon: Icons.map_outlined,
            onChanged: (v) => setState(() => _selectedState = v),
          ),

          _sectionTitle("Education"),
          _dropdownBox(
            value: _selectedEducation,
            options: _educationOptions,
            hint: "Select highest education",
            icon: Icons.school_outlined,
            onChanged: (v) => setState(() => _selectedEducation = v),
          ),

          _sectionTitle("Career"),
          TextField(
            controller: _experienceYearsCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("Total experience (years)", icon: Icons.work_outline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expectedSalaryMinCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("Expected salary per month", icon: Icons.currency_rupee_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noticeDaysCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("Notice period (days)", icon: Icons.calendar_today_outlined),
          ),

          _sectionTitle("Preferences"),
          _dropdownBox(
            value: _jobType,
            options: _jobTypeOptions,
            hint: "Preferred job type",
            icon: Icons.tune_rounded,
            onChanged: (v) => setState(() => _jobType = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _openToWork,
            onChanged: (v) => setState(() => _openToWork = v),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: const Color(0xFFF8FAFC),
            title: Text("Open to work", style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900)),
            subtitle: Text("Employers can see you as available.", style: KhilonjiyaUI.sub),
          ),

          _sectionTitle("Preferred locations", sub: "Optional. Helps recommendations."),
          _preferredLocationsBox(),

          _sectionTitle("Skills", sub: "Optional but improves recommendations."),
          _skillsBox(),

          _sectionTitle("Resume & Photo", sub: "Optional."),
          _filePickers(),

          _sectionTitle("About you"),
          TextField(
            controller: _bioCtrl,
            maxLines: 5,
            decoration: _dec("Short bio (optional)", icon: Icons.subject_rounded),
          ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Edit profile",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),
          ],
        ),
      ),

      // bottom button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KhilonjiyaUI.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save changes",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}