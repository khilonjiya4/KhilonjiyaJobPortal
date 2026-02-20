// File: lib/presentation/profile/profile_edit_page.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _bioFocus = FocusNode();

  bool _loading = true;
  bool _saving = false;
  bool _disposed = false;

  Map<String, dynamic> _profile = {};

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceYearsCtrl = TextEditingController();
  final _expectedSalaryMinCtrl = TextEditingController();
  final _noticeDaysCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();

  final List<String> _skills = [];
  bool _openToWork = false;

  @override
  void initState() {
    super.initState();
    _load();

    _bioFocus.addListener(() {
      if (_bioFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    _bioFocus.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _experienceYearsCtrl.dispose();
    _expectedSalaryMinCtrl.dispose();
    _noticeDaysCtrl.dispose();
    _skillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      _profile = await _service.fetchMyProfile();

      _fullNameCtrl.text = (_profile['full_name'] ?? '').toString();
      _phoneCtrl.text =
          (_profile['mobile_number'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      _bioCtrl.text = (_profile['bio'] ?? '').toString();
      _experienceYearsCtrl.text =
          (_profile['total_experience_years'] ?? '').toString();
      _expectedSalaryMinCtrl.text =
          (_profile['expected_salary_min'] ?? '').toString();
      _noticeDaysCtrl.text =
          (_profile['notice_period_days'] ?? '').toString();

      _openToWork = (_profile['is_open_to_work'] ?? false) == true;

      final rawSkills = _profile['skills'];
      if (rawSkills is List) {
        _skills.clear();
        for (final s in rawSkills) {
          final v = s.toString().trim();
          if (v.isNotEmpty) _skills.add(v);
        }
      }
    } catch (_) {}

    if (_disposed) return;
    setState(() => _loading = false);
  }

  int _toInt(String s) => int.tryParse(s.trim()) ?? 0;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: KhilonjiyaUI.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: KhilonjiyaUI.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: KhilonjiyaUI.primary.withOpacity(0.6),
          width: 1.2,
        ),
      ),
    );
  }

  void _addSkill() {
    final raw = _skillsCtrl.text.trim();
    if (raw.isEmpty) return;

    if (!_skills.any((e) => e.toLowerCase() == raw.toLowerCase())) {
      _skills.add(raw);
    }

    _skillsCtrl.clear();
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;

    if (_phoneCtrl.text.length != 10) {
      _toast("Mobile number must be 10 digits");
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'full_name': _fullNameCtrl.text.trim(),
      'mobile_number': _phoneCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'total_experience_years': _toInt(_experienceYearsCtrl.text),
      'expected_salary_min': _toInt(_expectedSalaryMinCtrl.text),
      'notice_period_days': _toInt(_noticeDaysCtrl.text),
      'is_open_to_work': _openToWork,
      'skills': _skills,
    };

    try {
      await _service.updateMyProfile(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      _toast("Failed to update profile");
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: KhilonjiyaUI.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _label("Mobile number"),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _dec("Enter 10 digit mobile number"),
          ),

          const SizedBox(height: 18),

          _label("Full name"),
          TextField(
            controller: _fullNameCtrl,
            decoration: _dec("Your full name"),
          ),

          const SizedBox(height: 18),

          Text("Career details",
              style: KhilonjiyaUI.hTitle.copyWith(
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),

          _label("Total experience (years)"),
          TextField(
            controller: _experienceYearsCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("e.g. 2"),
          ),

          const SizedBox(height: 14),

          _label("Expected salary per month (₹)"),
          TextField(
            controller: _expectedSalaryMinCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("e.g. 15000"),
          ),

          const SizedBox(height: 14),

          _label("Notice period (days)"),
          TextField(
            controller: _noticeDaysCtrl,
            keyboardType: TextInputType.number,
            decoration: _dec("e.g. 30"),
          ),

          const SizedBox(height: 18),

          Text("Skills",
              style: KhilonjiyaUI.hTitle.copyWith(
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills
                .map((s) => Chip(
                      label: Text(s),
                      onDeleted: () {
                        _skills.remove(s);
                        setState(() {});
                      },
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _skillsCtrl,
            decoration: _dec("Type skill and press enter"),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addSkill(),
          ),

          const SizedBox(height: 18),

          _label("About you"),
          TextField(
            controller: _bioCtrl,
            focusNode: _bioFocus,
            maxLines: 4,
            decoration: _dec("Short bio"),
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
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _body(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Save changes",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}