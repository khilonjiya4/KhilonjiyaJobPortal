import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient _client = Supabase.instance.client;

  // ------------------------------------------------------------
  // JOB CONTROLLERS (REAL SCHEMA)
  // ------------------------------------------------------------
  final _jobTitleCtrl = TextEditingController();

  final _jobDescriptionCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _responsibilitiesCtrl = TextEditingController();

  final _educationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();

  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();

  final _addressCtrl = TextEditingController();

  final _openingsCtrl = TextEditingController(text: "1");

  final _skillsCtrl = TextEditingController();
  final _benefitsCtrl = TextEditingController();
  final _additionalInfoCtrl = TextEditingController();

  final _walkInDetailsCtrl = TextEditingController();

  // ------------------------------------------------------------
  // DROPDOWNS
  // ------------------------------------------------------------
  String _jobType = "Full-time";
  String _employmentType = "Permanent";
  String _workMode = "On-site";
  String _salaryPeriod = "Monthly";
  String _hiringUrgency = "Normal";

  bool _isWalkIn = false;

  // ------------------------------------------------------------
  // MASTER TABLES
  // ------------------------------------------------------------
  bool _loadingCategories = true;
  List<String> _categories = [];
  String? _selectedCategory;

  bool _loadingDistricts = true;
  List<String> _districts = [];
  String? _selectedDistrict;

  // ------------------------------------------------------------
  // COMPANY (ORGANIZATION)
  // ------------------------------------------------------------
  bool _loadingCompanies = true;

  // Each item: { id, name }
  List<Map<String, dynamic>> _myCompanies = [];

  String? _selectedCompanyId;
  String? _selectedCompanyName;

  // ------------------------------------------------------------
  // UI STATE
  // ------------------------------------------------------------
  bool _loading = false;
  int _step = 0;

  final List<String> _jobTypes = const [
    "Full-time",
    "Part-time",
    "Internship",
    "Contract",
  ];

  final List<String> _employmentTypes = const [
    "Permanent",
    "Temporary",
    "Freelance",
    "Contract",
  ];

  final List<String> _workModes = const [
    "On-site",
    "Remote",
    "Hybrid",
  ];

  final List<String> _salaryPeriods = const [
    "Monthly",
    "Yearly",
    "Daily",
    "Hourly",
  ];

  final List<String> _urgencies = const [
    "Normal",
    "Urgent",
    "Immediate",
  ];

  // ------------------------------------------------------------
  // FLUENT LIGHT PALETTE
  // ------------------------------------------------------------
  static const _bg = Color(0xFFF6F7FB);
  static const _card = Colors.white;
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _line = Color(0xFFE6EAF2);
  static const _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    await Future.wait([
      _loadCompanies(),
      _loadCategories(),
      _loadDistricts(),
    ]);
  }

  @override
  void dispose() {
    _jobTitleCtrl.dispose();

    _jobDescriptionCtrl.dispose();
    _requirementsCtrl.dispose();
    _responsibilitiesCtrl.dispose();

    _educationCtrl.dispose();
    _experienceCtrl.dispose();

    _salaryMinCtrl.dispose();
    _salaryMaxCtrl.dispose();

    _addressCtrl.dispose();
    _openingsCtrl.dispose();

    _skillsCtrl.dispose();
    _benefitsCtrl.dispose();
    _additionalInfoCtrl.dispose();

    _walkInDetailsCtrl.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // LOAD: COMPANIES WHERE I AM ACTIVE MEMBER
  // ------------------------------------------------------------
  Future<void> _loadCompanies() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _myCompanies = [];
          _selectedCompanyId = null;
          _selectedCompanyName = null;
          _loadingCompanies = false;
        });
        return;
      }

      final res = await _client
          .from("company_members")
          .select("company_id, companies(id, name)")
          .eq("user_id", user.id)
          .eq("status", "active");

      final list = List<Map<String, dynamic>>.from(res);

      final companies = <Map<String, dynamic>>[];

      for (final row in list) {
        final c = row["companies"];
        if (c == null) continue;

        final id = (c["id"] ?? "").toString();
        final name = (c["name"] ?? "").toString();

        if (id.trim().isEmpty || name.trim().isEmpty) continue;

        companies.add({
          "id": id,
          "name": name,
        });
      }

      companies.sort((a, b) => (a["name"] as String)
          .toLowerCase()
          .compareTo((b["name"] as String).toLowerCase()));

      if (!mounted) return;

      setState(() {
        _myCompanies = companies;

        if (companies.isNotEmpty) {
          _selectedCompanyId = companies.first["id"];
          _selectedCompanyName = companies.first["name"];
        } else {
          _selectedCompanyId = null;
          _selectedCompanyName = null;
        }

        _loadingCompanies = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myCompanies = [];
        _selectedCompanyId = null;
        _selectedCompanyName = null;
        _loadingCompanies = false;
      });
    }
  }

  // ------------------------------------------------------------
  // LOAD: CATEGORIES
  // ------------------------------------------------------------
  Future<void> _loadCategories() async {
    try {
      final res = await _client
          .from("job_categories_master")
          .select("category_name")
          .eq("is_active", true)
          .order("category_name", ascending: true);

      final items = List<Map<String, dynamic>>.from(res)
          .map((e) => (e["category_name"] ?? "").toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = items;
        _selectedCategory = items.isNotEmpty ? items.first : null;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _selectedCategory = null;
        _loadingCategories = false;
      });
    }
  }

  // ------------------------------------------------------------
  // LOAD: DISTRICTS
  // ------------------------------------------------------------
  Future<void> _loadDistricts() async {
    try {
      final res = await _client
          .from("assam_districts_master")
          .select("district_name")
          .order("district_name", ascending: true);

      final items = List<Map<String, dynamic>>.from(res)
          .map((e) => (e["district_name"] ?? "").toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() {
        _districts = items;
        _selectedDistrict = items.isNotEmpty ? items.first : null;
        _loadingDistricts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _districts = [];
        _selectedDistrict = null;
        _loadingDistricts = false;
      });
    }
  }

  // ------------------------------------------------------------
  // QUICK CREATE ORGANIZATION (COMPANY)
  // ------------------------------------------------------------
  Future<void> _quickCreateOrganization() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      _showError("Session expired. Please login again.");
      return;
    }

    final nameCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController(text: "Assam");
    final websiteCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    String? selectedBusinessTypeId;

    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<List<Map<String, dynamic>>> loadBusinessTypes() async {
              final res = await _client
                  .from("business_types_master")
                  .select("id, type_name")
                  .eq("is_active", true)
                  .order("type_name", ascending: true);

              return List<Map<String, dynamic>>.from(res);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 4.w,
                right: 4.w,
                top: 2.h,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 2.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Organization",
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Create an organization first, then post jobs under it.",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputDecoration(label: "Organization Name"),
                  ),
                  SizedBox(height: 1.2.h),
                  FutureBuilder(
                    future: loadBusinessTypes(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return _infoBox(
                          text: "Loading business types...",
                          icon: Icons.hourglass_bottom_rounded,
                        );
                      }

                      final items = snap.data as List<Map<String, dynamic>>;

                      if (items.isEmpty) {
                        return _errorBox(
                          text: "No business types found",
                          actionText: "Close",
                          onAction: () => Navigator.pop(ctx),
                        );
                      }

                      selectedBusinessTypeId ??= items.first["id"].toString();

                      return DropdownButtonFormField<String>(
                        value: selectedBusinessTypeId,
                        items: items
                            .map(
                              (e) => DropdownMenuItem(
                                value: e["id"].toString(),
                                child: Text(
                                  (e["type_name"] ?? "").toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _text,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModalState(() => selectedBusinessTypeId = v);
                        },
                        decoration:
                            _inputDecoration(label: "Type of Business"),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      );
                    },
                  ),
                  SizedBox(height: 1.2.h),
                  TextField(
                    controller: cityCtrl,
                    decoration: _inputDecoration(label: "City (optional)"),
                  ),
                  SizedBox(height: 1.2.h),
                  TextField(
                    controller: stateCtrl,
                    decoration: _inputDecoration(label: "State (optional)"),
                  ),
                  SizedBox(height: 1.2.h),
                  TextField(
                    controller: websiteCtrl,
                    decoration: _inputDecoration(label: "Website (optional)"),
                  ),
                  SizedBox(height: 1.2.h),
                  TextField(
                    controller: descCtrl,
                    minLines: 3,
                    maxLines: 6,
                    decoration:
                        _inputDecoration(label: "Description (optional)"),
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) return;

                              if (selectedBusinessTypeId == null ||
                                  selectedBusinessTypeId!.trim().isEmpty) {
                                return;
                              }

                              setModalState(() => saving = true);

                              try {
                                // 1) Create company
                                final inserted = await _client
                                    .from("companies")
                                    .insert({
                                      "name": name,
                                      "headquarters_city": cityCtrl.text.trim()
                                              .isEmpty
                                          ? null
                                          : cityCtrl.text.trim(),
                                      "headquarters_state":
                                          stateCtrl.text.trim().isEmpty
                                              ? null
                                              : stateCtrl.text.trim(),
                                      "website": websiteCtrl.text.trim().isEmpty
                                          ? null
                                          : websiteCtrl.text.trim(),
                                      "description": descCtrl.text.trim().isEmpty
                                          ? null
                                          : descCtrl.text.trim(),
                                      "business_type_id": selectedBusinessTypeId,
                                      "created_by": user.id,
                                    })
                                    .select("id, name")
                                    .single();

                                final companyId = inserted["id"].toString();
                                final companyName =
                                    (inserted["name"] ?? "").toString();

                                // 2) Add creator as active member
                                await _client.from("company_members").insert({
                                  "company_id": companyId,
                                  "user_id": user.id,
                                  "status": "active",
                                  "role": "recruiter",
                                });

                                if (!mounted) return;

                                Navigator.pop(ctx);

                                // refresh list
                                await _loadCompanies();

                                // auto-select new company
                                setState(() {
                                  _selectedCompanyId = companyId;
                                  _selectedCompanyName = companyName;
                                });

                                _showSuccess("Organization created");
                              } catch (_) {
                                _showError("Failed to create organization");
                              }

                              setModalState(() => saving = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              "Create",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SUBMIT JOB (REAL INSERT)
  // ------------------------------------------------------------
  Future<void> _submit() async {
    if (_loading) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    if (_selectedCompanyId == null || _selectedCompanyId!.trim().isEmpty) {
      _showError("Please select an organization");
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.trim().isEmpty) {
      _showError("Please select a job category");
      return;
    }

    if (_selectedDistrict == null || _selectedDistrict!.trim().isEmpty) {
      _showError("Please select a district");
      return;
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      _showError("Session expired. Please login again.");
      return;
    }

    final salaryMin = int.tryParse(_salaryMinCtrl.text.trim());
    final salaryMax = int.tryParse(_salaryMaxCtrl.text.trim());
    final openings = int.tryParse(_openingsCtrl.text.trim()) ?? 1;

    if (salaryMin == null || salaryMax == null) {
      _showError("Salary must be a valid number");
      return;
    }

    if (salaryMin > salaryMax) {
      _showError("Min salary cannot be greater than max salary");
      return;
    }

    if (openings <= 0) {
      _showError("Openings must be at least 1");
      return;
    }

    if (_isWalkIn && _walkInDetailsCtrl.text.trim().isEmpty) {
      _showError("Please enter walk-in details");
      return;
    }

    setState(() => _loading = true);

    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _client.from("job_listings").insert({
        // REQUIRED (REAL)
        "employer_id": user.id,
        "company_id": _selectedCompanyId,

        // REQUIRED (REAL)
        "job_title": _jobTitleCtrl.text.trim(),
        "job_category": _selectedCategory,
        "job_type": _jobType,
        "employment_type": _employmentType,
        "work_mode": _workMode,

        // REQUIRED (REAL)
        "job_description": _jobDescriptionCtrl.text.trim(),
        "requirements": _requirementsCtrl.text.trim(),
        "education_required": _educationCtrl.text.trim(),
        "experience_required": _experienceCtrl.text.trim(),

        // REQUIRED (REAL)
        "salary_min": salaryMin,
        "salary_max": salaryMax,
        "salary_period": _salaryPeriod,
        "salary_currency": "INR",

        // REQUIRED (REAL)
        "district": _selectedDistrict,
        "job_address": _addressCtrl.text.trim(),

        // REQUIRED (REAL)
        "hiring_urgency": _hiringUrgency,

        // OPTIONAL
        "responsibilities": _responsibilitiesCtrl.text.trim().isEmpty
            ? null
            : _responsibilitiesCtrl.text.trim(),
        "benefits":
            _benefitsCtrl.text.trim().isEmpty ? null : _benefitsCtrl.text.trim(),
        "additional_info": _additionalInfoCtrl.text.trim().isEmpty
            ? null
            : _additionalInfoCtrl.text.trim(),

        "skills_required": skills.isEmpty ? null : skills,
        "number_of_openings": openings,

        "is_walk_in": _isWalkIn,
        "walk_in_details": _isWalkIn ? _walkInDetailsCtrl.text.trim() : null,

        // must match enum
        "status": "active",
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _showError("Failed to create job (check RLS + required fields)");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // VALIDATORS
  // ------------------------------------------------------------
  String? _requiredValidator(String? v) {
    final value = (v ?? "").trim();
    if (value.isEmpty) return "Required";
    return null;
  }

  // ------------------------------------------------------------
  // STEP VALIDATION
  // ------------------------------------------------------------
  bool _isStepValid(int step) {
    // step 0: company
    if (step == 0) {
      return _selectedCompanyId != null && _selectedCompanyId!.trim().isNotEmpty;
    }

    // step 1: job
    if (step == 1) {
      return _jobTitleCtrl.text.trim().isNotEmpty &&
          (_selectedCategory ?? '').trim().isNotEmpty;
    }

    // step 2: requirements
    if (step == 2) {
      return _jobDescriptionCtrl.text.trim().isNotEmpty &&
          _requirementsCtrl.text.trim().isNotEmpty &&
          _educationCtrl.text.trim().isNotEmpty &&
          _experienceCtrl.text.trim().isNotEmpty &&
          _salaryMinCtrl.text.trim().isNotEmpty &&
          _salaryMaxCtrl.text.trim().isNotEmpty;
    }

    // step 3: location
    if (step == 3) {
      return (_selectedDistrict ?? '').trim().isNotEmpty &&
          _addressCtrl.text.trim().isNotEmpty;
    }

    return true;
  }

  void _nextStep() {
    if (_step >= 3) return;

    if (!_isStepValid(_step)) {
      _showError("Please complete the required fields to continue.");
      return;
    }

    setState(() => _step++);
  }

  void _prevStep() {
    if (_step <= 0) return;
    setState(() => _step--);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        titleSpacing: 4.w,
        iconTheme: const IconThemeData(color: _text),
        title: const Text(
          "Create Job",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _text,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 14.h),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _topHeader(),
                  SizedBox(height: 2.h),
                  _stepIndicator(),
                  SizedBox(height: 2.2.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _stepBody(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomActionBar(),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  Widget _topHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 2.2.h, 4.w, 2.2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Icon(
              Icons.add_task_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          SizedBox(width: 4.w),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Post a new job",
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: _text,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Select organization, then fill job details.",
                  style: TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                    height: 1.25,
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
  // STEPPER
  // ------------------------------------------------------------
  Widget _stepIndicator() {
    final steps = const [
      ("Organization", Icons.apartment_rounded),
      ("Job", Icons.work_outline_rounded),
      ("Requirements", Icons.rule_rounded),
      ("Location", Icons.location_on_rounded),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 1.6.h, 4.w, 1.6.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final isDone = i < _step;
              final isActive = i == _step;

              final Color dotBg = isDone
                  ? const Color(0xFFDCFCE7)
                  : (isActive
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF1F5F9));

              final Color dotFg = isDone
                  ? const Color(0xFF166534)
                  : (isActive
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF475569));

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: dotBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: dotFg.withOpacity(0.18)),
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : steps[i].$2,
                        size: 18,
                        color: dotFg,
                      ),
                    ),
                    if (i != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDone ? const Color(0xFFBFDBFE) : _line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 1.1.h),
          Row(
            children: List.generate(steps.length, (i) {
              final isActive = i == _step;
              return Expanded(
                child: Text(
                  steps[i].$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? _text : _muted,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // STEP BODY
  // ------------------------------------------------------------
  Widget _stepBody() {
    if (_step == 0) return _stepOrganization();
    if (_step == 1) return _stepJob();
    if (_step == 2) return _stepRequirements();
    return _stepLocation();
  }

  // STEP 0
  Widget _stepOrganization() {
    return _cardSection(
      title: "Organization",
      subtitle: "Select the organization where you want to post this job",
      child: Column(
        children: [
          if (_loadingCompanies)
            _infoBox(
              text: "Loading your organizations...",
              icon: Icons.hourglass_bottom_rounded,
            )
          else if (_myCompanies.isEmpty)
            _errorBox(
              text: "No organization found. Create one first.",
              actionText: "Create",
              onAction: _quickCreateOrganization,
            )
          else
            _companyDropdown(),
          SizedBox(height: 1.2.h),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _quickCreateOrganization,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Create new organization",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _companyDropdown() {
    final selectedId = _selectedCompanyId;

    return DropdownButtonFormField<String>(
      value: selectedId,
      items: _myCompanies
          .map(
            (c) => DropdownMenuItem(
              value: c["id"].toString(),
              child: Text(
                c["name"].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;

        final found =
            _myCompanies.where((e) => e["id"].toString() == v).toList();

        setState(() {
          _selectedCompanyId = v;
          _selectedCompanyName =
              found.isNotEmpty ? found.first["name"].toString() : null;
        });
      },
      decoration: _inputDecoration(label: "Select Organization"),
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  // STEP 1
  Widget _stepJob() {
    return _cardSection(
      title: "Job Details",
      subtitle: "Title, category and working type",
      child: Column(
        children: [
          _field("Job Title", _jobTitleCtrl),
          _categoryDropdown(),
          _dropdown("Job Type", _jobType, _jobTypes, (v) {
            setState(() => _jobType = v);
          }),
          _dropdown(
            "Employment Type",
            _employmentType,
            _employmentTypes,
            (v) => setState(() => _employmentType = v),
          ),
          _dropdown("Work Mode", _workMode, _workModes, (v) {
            setState(() => _workMode = v);
          }),
        ],
      ),
    );
  }

  // STEP 2
  Widget _stepRequirements() {
    return Column(
      children: [
        _cardSection(
          title: "Salary",
          subtitle: "Salary range visible to candidates",
          child: Column(
            children: [
              _rowFields(
                _field(
                  "Min Salary",
                  _salaryMinCtrl,
                  number: true,
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
                _field(
                  "Max Salary",
                  _salaryMaxCtrl,
                  number: true,
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
              ),
              _dropdown(
                "Salary Period",
                _salaryPeriod,
                _salaryPeriods,
                (v) => setState(() => _salaryPeriod = v),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.2.h),
        _cardSection(
          title: "Requirements",
          subtitle: "Describe role and what you need",
          child: Column(
            children: [
              _multilineField("Job Description", _jobDescriptionCtrl),
              _multilineField("Requirements", _requirementsCtrl),
              _multilineField(
                "Responsibilities (optional)",
                _responsibilitiesCtrl,
                required: false,
              ),
              _field("Education Required", _educationCtrl),
              _field("Experience Required", _experienceCtrl),
              _field(
                "Skills (comma separated)",
                _skillsCtrl,
                hint: "Flutter, Firebase, Sales",
                required: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3
  Widget _stepLocation() {
    return Column(
      children: [
        _cardSection(
          title: "Location",
          subtitle: "Where the candidate will work",
          child: Column(
            children: [
              _districtDropdown(),
              _multilineField("Full Job Address", _addressCtrl),
            ],
          ),
        ),
        SizedBox(height: 2.2.h),
        _cardSection(
          title: "Other",
          subtitle: "Openings, urgency and optional details",
          child: Column(
            children: [
              _dropdown(
                "Hiring Urgency",
                _hiringUrgency,
                _urgencies,
                (v) => setState(() => _hiringUrgency = v),
              ),
              _field(
                "Openings",
                _openingsCtrl,
                number: true,
                keyboard: TextInputType.number,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Walk-in interview",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                subtitle: const Text(
                  "Enable if candidates can directly come for interview",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                value: _isWalkIn,
                onChanged: (v) => setState(() => _isWalkIn = v),
              ),
              if (_isWalkIn)
                _multilineField(
                  "Walk-in details",
                  _walkInDetailsCtrl,
                ),
              _multilineField(
                "Benefits (optional)",
                _benefitsCtrl,
                required: false,
              ),
              _multilineField(
                "Additional Info (optional)",
                _additionalInfoCtrl,
                required: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------
  Widget _bottomActionBar() {
    final bool canGoBack = _step > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 1.2.h, 4.w, 2.2.h),
      decoration: BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : (canGoBack ? _prevStep : null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: const BorderSide(color: _line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _loading
                    ? null
                    : (_step == 3 ? _submit : _nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _step == 3 ? "Publish Job" : "Continue",
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DROPDOWNS (CATEGORIES + DISTRICTS)
  // ------------------------------------------------------------
  Widget _categoryDropdown() {
    if (_loadingCategories) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: _infoBox(
          text: "Loading categories...",
          icon: Icons.hourglass_bottom_rounded,
        ),
      );
    }

    if (_categories.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: _errorBox(
          text: "No job categories found in database",
          actionText: "Retry",
          onAction: _loadCategories,
        ),
      );
    }

    return _dropdown(
      "Job Category",
      _selectedCategory!,
      _categories,
      (v) => setState(() => _selectedCategory = v),
    );
  }

  Widget _districtDropdown() {
    if (_loadingDistricts) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: _infoBox(
          text: "Loading districts...",
          icon: Icons.hourglass_bottom_rounded,
        ),
      );
    }

    if (_districts.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: 1.5.h),
        child: _errorBox(
          text: "No districts found in database",
          actionText: "Retry",
          onAction: _loadDistricts,
        ),
      );
    }

    return _dropdown(
      "District",
      _selectedDistrict!,
      _districts,
      (v) => setState(() => _selectedDistrict = v),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _cardSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(4.w, 2.2.h, 4.w, 2.2.h),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _text,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.6,
              color: _muted,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          SizedBox(height: 2.h),
          child,
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    String? hint,
    bool required = true,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextFormField(
        controller: controller,
        keyboardType:
            keyboard ?? (number ? TextInputType.number : TextInputType.text),
        inputFormatters: formatters,
        validator: (v) {
          if (!required) return null;
          return (validator ?? _requiredValidator)(v);
        },
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: _text,
        ),
        decoration: _inputDecoration(label: label, hint: hint),
      ),
    );
  }

  Widget _multilineField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: TextFormField(
        controller: controller,
        minLines: 4,
        maxLines: 10,
        validator: (v) {
          if (!required) return null;
          final value = (v ?? "").trim();
          if (value.isEmpty) return "Required";
          return null;
        },
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: _text,
          height: 1.35,
        ),
        decoration: _inputDecoration(label: label),
      ),
    );
  }

  Widget _rowFields(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: 3.w),
        Expanded(child: right),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          onChanged(v);
        },
        decoration: _inputDecoration(label: label),
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: _muted,
      ),
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFCA5A5)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
    );
  }

  Widget _infoBox({required String text, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF475569)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox({
    required String text,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF9F1239)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF9F1239),
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SNACKS
  // ------------------------------------------------------------
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}