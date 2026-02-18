// File: lib/presentation/common/widgets/job_application_form.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/ui/khilonjiya_ui.dart';
import '../../../services/job_seeker_home_service.dart';

class JobApplicationForm extends StatefulWidget {
  final String jobId;

  const JobApplicationForm({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  State<JobApplicationForm> createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final JobSeekerHomeService _service = JobSeekerHomeService();
  final SupabaseClient _db = Supabase.instance.client;

  bool _loading = true;
  bool _submitting = false;

  // ------------------------------------------------------------
  // controllers
  // ------------------------------------------------------------
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _experienceDetails = TextEditingController();
  final _skills = TextEditingController();
  final _expectedSalary = TextEditingController();
  final _additionalInfo = TextEditingController();

  // ------------------------------------------------------------
  // dropdown values
  // ------------------------------------------------------------
  String _district = '';
  String _education = '';
  String _experienceLevel = '';
  String _availability = '';
  String _gender = '';

  // ------------------------------------------------------------
  // masters (dropdown data)
  // ------------------------------------------------------------
  List<String> _districts = [];
  final List<String> _educationOptions = const [
    "Below 10th",
    "10th Pass",
    "12th Pass",
    "ITI",
    "Diploma",
    "Graduate",
    "Post Graduate",
    "PhD",
    "Other",
  ];

  final List<String> _experienceOptions = const [
    "Fresher",
    "0-1 years",
    "1-3 years",
    "3-5 years",
    "5-10 years",
    "10+ years",
  ];

  final List<String> _availabilityOptions = const [
    "Immediate",
    "Within 7 days",
    "Within 15 days",
    "Within 30 days",
    "More than 30 days",
  ];

  final List<String> _genderOptions = const [
    "Male",
    "Female",
    "Other",
    "Prefer not to say",
  ];

  // ------------------------------------------------------------
  // profile attachments (auto)
  // ------------------------------------------------------------
  String _resumeRawPath = '';
  String _photoRawPath = '';
  String _resumeFileName = '';
  String _photoFileName = '';

  // ------------------------------------------------------------
  // focus
  // ------------------------------------------------------------
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _skillsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadPrefill();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _experienceDetails.dispose();
    _skills.dispose();
    _expectedSalary.dispose();
    _additionalInfo.dispose();

    _phoneFocus.dispose();
    _emailFocus.dispose();
    _skillsFocus.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // toast
  // ------------------------------------------------------------
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ------------------------------------------------------------
  // load prefill
  // ------------------------------------------------------------
  Future<void> _loadPrefill() async {
    setState(() => _loading = true);

    try {
      // 1) districts master (Assam)
      try {
        final districtsRes = await _service.fetchAssamDistrictMaster();
        final d = districtsRes
            .map((e) => (e['district_name'] ?? '').toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        d.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        _districts = d;
      } catch (_) {
        _districts = [];
      }

      // 2) profile
      final profile = await _service.fetchMyProfile();

      _name.text = (profile['full_name'] ?? '').toString().trim();
      _phone.text =
          (profile['mobile_number'] ?? profile['phone'] ?? '').toString().trim();
      _email.text = (profile['email'] ?? '').toString().trim();

      // education
      final edu = (profile['highest_education'] ?? '').toString().trim();
      if (edu.isNotEmpty) {
        _education = _pickClosest(_educationOptions, edu);
      }

      // skills
      final skillsRaw = profile['skills'];
      if (skillsRaw is List) {
        _skills.text = skillsRaw.map((e) => e.toString()).join(', ');
      } else {
        _skills.text = (skillsRaw ?? '').toString();
      }

      // district
      final city = (profile['current_city'] ?? '').toString().trim();
      final state = (profile['current_state'] ?? '').toString().trim();
      final loc = (profile['location'] ?? '').toString().trim();

      final suggested = city.isNotEmpty
          ? city
          : (loc.isNotEmpty ? loc : (state.isNotEmpty ? state : ''));

      if (suggested.isNotEmpty) {
        if (_districts.isNotEmpty) {
          _district = _pickClosest(_districts, suggested);
        } else {
          _district = suggested;
        }
      }

      // 3) raw storage paths for attachments
      // fetchMyProfile() returns SIGNED urls.
      // We need RAW paths (resumes/... and photos/...)
      try {
        final raw = await _service.fetchMyProfileRawPaths();

        _resumeRawPath = (raw['resume_url'] ?? '').toString().trim();
        _photoRawPath = (raw['avatar_url'] ?? '').toString().trim();

        if (_resumeRawPath.isNotEmpty) {
          _resumeFileName = _fileNameFromPath(_resumeRawPath);
        }
        if (_photoRawPath.isNotEmpty) {
          _photoFileName = _fileNameFromPath(_photoRawPath);
        }
      } catch (_) {}
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // validation
  // ------------------------------------------------------------
  bool _validate() {
    if (_name.text.trim().isEmpty) {
      _toast("Name is required");
      return false;
    }
    if (_phone.text.trim().isEmpty) {
      _toast("Phone is required");
      return false;
    }
    if (_email.text.trim().isEmpty) {
      _toast("Email is required");
      return false;
    }
    if (_skills.text.trim().isEmpty) {
      _toast("Skills are required");
      return false;
    }
    if (_district.trim().isEmpty) {
      _toast("District is required");
      return false;
    }
    if (_education.trim().isEmpty) {
      _toast("Education is required");
      return false;
    }
    if (_experienceLevel.trim().isEmpty) {
      _toast("Experience level is required");
      return false;
    }
    if (_availability.trim().isEmpty) {
      _toast("Availability is required");
      return false;
    }
    return true;
  }

  // ------------------------------------------------------------
  // submit (REAL APPLY)
  // ------------------------------------------------------------
  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    setState(() => _submitting = true);

    String insertedApplicationId = '';

    try {
      final user = _db.auth.currentUser;
      if (user == null) {
        throw Exception("Session expired. Please login again.");
      }

      final userId = user.id;

      // 1) prevent duplicate apply
      final already = await _db
          .from('job_applications_listings')
          .select('id')
          .eq('user_id', userId)
          .eq('listing_id', widget.jobId)
          .maybeSingle();

      if (already != null) {
        if (!mounted) return;
        _toast("Already applied");
        Navigator.pop(context, false);
        return;
      }

      // 2) insert into job_applications
      final insertedApp = await _db
          .from('job_applications')
          .insert({
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),

            'name': _name.text.trim(),
            'phone': _phone.text.trim(),
            'email': _email.text.trim(),

            'district': _district.trim(),
            'address': _address.text.trim(),

            'gender': _gender.trim().isEmpty ? null : _gender.trim(),

            'education': _education.trim(),

            'experience_level': _experienceLevel.trim(),
            'experience_details': _experienceDetails.text.trim(),

            'skills': _skills.text.trim(),

            'expected_salary': _expectedSalary.text.trim(),
            'availability': _availability.trim(),

            'additional_info': _additionalInfo.text.trim(),

            // attachments
            'resume_file_name': _resumeFileName.trim().isEmpty
                ? null
                : _resumeFileName.trim(),
            'resume_file_url':
                _resumeRawPath.trim().isEmpty ? null : _resumeRawPath.trim(),
            'photo_file_name':
                _photoFileName.trim().isEmpty ? null : _photoFileName.trim(),
            'photo_file_url':
                _photoRawPath.trim().isEmpty ? null : _photoRawPath.trim(),
          })
          .select('id')
          .single();

      insertedApplicationId = (insertedApp['id'] ?? '').toString().trim();
      if (insertedApplicationId.isEmpty) {
        throw Exception("Application insert failed (missing id)");
      }

      // 3) insert into job_applications_listings
      // IMPORTANT:
      // Your schema DOES NOT have pipeline_stage_id.
      // Pipeline is stored in employer_notes tag.
      await _db.from('job_applications_listings').insert({
        'listing_id': widget.jobId,
        'application_id': insertedApplicationId,
        'user_id': userId,
        'applied_at': DateTime.now().toIso8601String(),
        'application_status': 'applied',
      });

      // 4) success
      if (!mounted) return;
      _toast("Application submitted");
      Navigator.pop(context, true);
    } catch (e) {
      // rollback orphan job_applications if listing insert failed
      try {
        if (insertedApplicationId.trim().isNotEmpty) {
          await _db
              .from('job_applications')
              .delete()
              .eq('id', insertedApplicationId);
        }
      } catch (_) {}

      if (!mounted) return;
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: KhilonjiyaUI.text,
        elevation: 1,
        title: const Text("Apply"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      _topCard(),
                      const SizedBox(height: 12),

                      _sectionTitle("Basic Details"),
                      const SizedBox(height: 8),

                      _input(
                        "Full Name *",
                        _name,
                        textInputAction: TextInputAction.next,
                      ),
                      _input(
                        "Phone *",
                        _phone,
                        focusNode: _phoneFocus,
                        keyboard: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      _input(
                        "Email *",
                        _email,
                        focusNode: _emailFocus,
                        keyboard: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 14),
                      _sectionTitle("Location"),
                      const SizedBox(height: 8),

                      _dropdown(
                        label: "District *",
                        value: _district,
                        items: _districts.isEmpty ? ["Other"] : _districts,
                        onChanged: (v) => setState(() => _district = v),
                      ),
                      _input("Address (optional)", _address, maxLines: 2),

                      const SizedBox(height: 14),
                      _sectionTitle("Education & Experience"),
                      const SizedBox(height: 8),

                      _dropdown(
                        label: "Highest Education *",
                        value: _education,
                        items: _educationOptions,
                        onChanged: (v) => setState(() => _education = v),
                      ),
                      _dropdown(
                        label: "Experience Level *",
                        value: _experienceLevel,
                        items: _experienceOptions,
                        onChanged: (v) => setState(() => _experienceLevel = v),
                      ),
                      _input(
                        "Experience Details (optional)",
                        _experienceDetails,
                        maxLines: 2,
                      ),

                      const SizedBox(height: 14),
                      _sectionTitle("Skills & Salary"),
                      const SizedBox(height: 8),

                      _input(
                        "Skills * (comma separated)",
                        _skills,
                        focusNode: _skillsFocus,
                        maxLines: 2,
                        textInputAction: TextInputAction.newline,
                      ),
                      _input(
                        "Expected Salary (optional)",
                        _expectedSalary,
                        keyboard: TextInputType.number,
                      ),
                      _dropdown(
                        label: "Availability *",
                        value: _availability,
                        items: _availabilityOptions,
                        onChanged: (v) => setState(() => _availability = v),
                      ),
                      _dropdown(
                        label: "Gender (optional)",
                        value: _gender,
                        items: _genderOptions,
                        allowEmpty: true,
                        onChanged: (v) => setState(() => _gender = v),
                      ),

                      const SizedBox(height: 14),
                      _sectionTitle("Additional Info"),
                      const SizedBox(height: 8),

                      _input(
                        "Cover Note / Additional Info (optional)",
                        _additionalInfo,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 14),
                      _attachmentsCard(),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KhilonjiyaUI.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Submit Application",
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Tip: Upload resume & profile photo in Profile Edit for a stronger application.",
                        style: KhilonjiyaUI.sub,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // UI widgets
  // ------------------------------------------------------------
  Widget _topCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Apply for this Job", style: KhilonjiyaUI.hTitle),
          const SizedBox(height: 6),
          Text(
            "Fill the details below and submit your application.",
            style: KhilonjiyaUI.body.copyWith(
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: KhilonjiyaUI.body.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _attachmentsCard() {
    final hasResume = _resumeRawPath.trim().isNotEmpty;
    final hasPhoto = _photoRawPath.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attachments (auto)",
            style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _attachRow(
            label: "Resume",
            value: hasResume
                ? (_resumeFileName.isEmpty ? "Attached" : _resumeFileName)
                : "Not uploaded",
            ok: hasResume,
          ),
          const SizedBox(height: 6),
          _attachRow(
            label: "Photo",
            value: hasPhoto
                ? (_photoFileName.isEmpty ? "Attached" : _photoFileName)
                : "Not uploaded",
            ok: hasPhoto,
          ),
        ],
      ),
    );
  }

  Widget _attachRow({
    required String label,
    required String value,
    required bool ok,
  }) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          size: 18,
          color: ok ? const Color(0xFF16A34A) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: ok ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
    FocusNode? focusNode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: TextField(
        controller: c,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboard,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    bool allowEmpty = false,
  }) {
    final cleanItems = items
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final dropdownItems = <DropdownMenuItem<String>>[];

    if (allowEmpty) {
      dropdownItems.add(
        const DropdownMenuItem(
          value: '',
          child: Text("Not selected"),
        ),
      );
    }

    dropdownItems.addAll(
      cleanItems.map(
        (e) => DropdownMenuItem(
          value: e,
          child: Text(e),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: KhilonjiyaUI.r16,
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: DropdownButtonFormField<String>(
        value: allowEmpty
            ? value.trim()
            : (value.trim().isEmpty ? null : value.trim()),
        isExpanded: true,
        items: dropdownItems,
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------
  String _fileNameFromPath(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    final idx = p.lastIndexOf('/');
    if (idx < 0) return p;
    return p.substring(idx + 1);
  }

  String _pickClosest(List<String> options, String raw) {
    final r = raw.trim().toLowerCase();
    if (r.isEmpty) return '';

    for (final o in options) {
      if (o.toLowerCase() == r) return o;
    }

    for (final o in options) {
      if (o.toLowerCase().contains(r)) return o;
    }

    for (final o in options) {
      if (r.contains(o.toLowerCase())) return o;
    }

    return raw.trim();
  }
}