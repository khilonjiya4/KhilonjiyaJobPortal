// lib/presentation/company/dashboard/create_organization_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/employer_dashboard_service.dart';

class CreateOrganizationScreen extends StatefulWidget {
  const CreateOrganizationScreen({Key? key}) : super(key: key);

  @override
  State<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends State<CreateOrganizationScreen> {
  final SupabaseClient _db = Supabase.instance.client;
  final EmployerDashboardService _service = EmployerDashboardService();

  bool _loading = true;
  bool _saving = false;

  // master dropdown data
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _businessTypes = [];

  // form
  final TextEditingController _name = TextEditingController();
  final TextEditingController _website = TextEditingController();
  final TextEditingController _desc = TextEditingController();

  String? _selectedDistrict;
  String? _selectedBusinessType;

  // UI
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadMasters();
  }

  @override
  void dispose() {
    _name.dispose();
    _website.dispose();
    _desc.dispose();
    super.dispose();
  }

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired. Please login again.");
    return u;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadMasters() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // districts (REAL TABLE)
      final dRes = await _db
          .from('assam_districts_master')
          .select('id, district_name')
          .order('district_name', ascending: true);

      _districts = List<Map<String, dynamic>>.from(dRes);

      // business types (REAL TABLE)
      final bRes = await _db
          .from('business_types_master')
          .select('id, type_name')
          .eq('is_active', true)
          .order('type_name', ascending: true);

      _businessTypes = List<Map<String, dynamic>>.from(bRes);
    } catch (e) {
      _districts = [];
      _businessTypes = [];
      _toast("Failed to load dropdowns: $e");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // SAVE ORGANIZATION
  // ------------------------------------------------------------
  Future<void> _create() async {
    _requireUser();

    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast("Organization name required");
      return;
    }

    if ((_selectedBusinessType ?? '').trim().isEmpty) {
      _toast("Business type required");
      return;
    }

    if ((_selectedDistrict ?? '').trim().isEmpty) {
      _toast("District required");
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      // Create organization
      await _service.createOrganization(
        name: name,
        businessType: _selectedBusinessType!,
        district: _selectedDistrict!,
        website: _website.text.trim(),
        description: _desc.text.trim(),
      );

      if (!mounted) return;

      // Return to dashboard and let it reload.
      Navigator.pop(context, true);

      _toast("Organization created");
    } catch (e) {
      _toast("Failed: $e");
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.7,
        title: const Text("Create Organization"),
        foregroundColor: _text,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  24 + keyboardBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title("Organization Details"),
                    const SizedBox(height: 6),
                    _sub(
                      "Create your organization to start posting jobs. "
                      "Your organization will be verified later by the office team.",
                    ),
                    const SizedBox(height: 18),

                    _label("Organization name *"),
                    const SizedBox(height: 8),
                    _input(
                      controller: _name,
                      hint: "Eg. ABC Construction",
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    _label("Business type *"),
                    const SizedBox(height: 8),
                    _dropdown(
                      value: _selectedBusinessType,
                      hint: "Select business type",
                      items: _businessTypes
                          .map((e) => (e['type_name'] ?? '').toString())
                          .where((x) => x.trim().isNotEmpty)
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedBusinessType = v),
                    ),
                    const SizedBox(height: 14),

                    _label("District *"),
                    const SizedBox(height: 8),
                    _dropdown(
                      value: _selectedDistrict,
                      hint: "Select district",
                      items: _districts
                          .map((e) => (e['district_name'] ?? '').toString())
                          .where((x) => x.trim().isNotEmpty)
                          .toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v),
                    ),
                    const SizedBox(height: 14),

                    _label("Website (optional)"),
                    const SizedBox(height: 8),
                    _input(
                      controller: _website,
                      hint: "https://",
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),

                    _label("Description (optional)"),
                    const SizedBox(height: 8),
                    _input(
                      controller: _desc,
                      hint: "Short description about your organization",
                      minLines: 3,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _create,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _saving ? "Creating..." : "Create Organization",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "By creating, you agree to verification by the office team.",
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------
  Widget _title(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: _text,
      ),
    );
  }

  Widget _sub(String t) {
    return Text(
      t,
      style: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    );
  }

  Widget _label(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: _text,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: items
              .map((x) => DropdownMenuItem(value: x, child: Text(x)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}