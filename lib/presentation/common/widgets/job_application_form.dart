import 'package:flutter/material.dart';

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

  bool _loading = true;
  bool _submitting = false;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _education = TextEditingController();
  final _experienceLevel = TextEditingController();
  final _experienceDetails = TextEditingController();
  final _skills = TextEditingController();
  final _expectedSalary = TextEditingController();
  final _availability = TextEditingController();
  final _additionalInfo = TextEditingController();

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
    _district.dispose();
    _address.dispose();
    _education.dispose();
    _experienceLevel.dispose();
    _experienceDetails.dispose();
    _skills.dispose();
    _expectedSalary.dispose();
    _availability.dispose();
    _additionalInfo.dispose();
    super.dispose();
  }

  Future<void> _loadPrefill() async {
    setState(() => _loading = true);

    try {
      final profile = await _service.fetchMyProfile();

      _name.text = (profile['full_name'] ?? '').toString();
      _phone.text = (profile['mobile_number'] ?? profile['phone'] ?? '').toString();
      _email.text = (profile['email'] ?? '').toString();
      _education.text = (profile['highest_education'] ?? '').toString();

      final skillsRaw = profile['skills'];
      if (skillsRaw is List) {
        _skills.text = skillsRaw.map((e) => e.toString()).join(', ');
      } else {
        _skills.text = (skillsRaw ?? '').toString();
      }

      final city = (profile['current_city'] ?? '').toString().trim();
      final state = (profile['current_state'] ?? '').toString().trim();
      final loc = (profile['location'] ?? '').toString().trim();

      if (city.isNotEmpty) {
        _district.text = city;
      } else if (loc.isNotEmpty) {
        _district.text = loc;
      } else if (state.isNotEmpty) {
        _district.text = state;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

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
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    setState(() => _submitting = true);

    try {
      final applied = await _service.applyToJob(
        jobId: widget.jobId,
        form: {
          'name': _name.text.trim(),
          'phone': _phone.text.trim(),
          'email': _email.text.trim(),
          'district': _district.text.trim(),
          'address': _address.text.trim(),
          'education': _education.text.trim(),
          'experience_level': _experienceLevel.text.trim(),
          'experience_details': _experienceDetails.text.trim(),
          'skills': _skills.text.trim(),
          'expected_salary': _expectedSalary.text.trim(),
          'availability': _availability.text.trim(),
          'additional_info': _additionalInfo.text.trim(),
        },
      );

      if (!mounted) return;

      if (!applied) {
        _toast("Already applied");
        Navigator.pop(context, false);
        return;
      }

      _toast("Application submitted");
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast("Failed: ${e.toString()}");
    }

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: KhilonjiyaUI.text,
        elevation: 1,
        title: const Text("Apply"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  title: "Apply for this Job",
                  subtitle: "Fill details and submit your application.",
                ),
                const SizedBox(height: 12),

                _input("Full Name *", _name),
                _input("Phone *", _phone, keyboard: TextInputType.phone),
                _input("Email *", _email, keyboard: TextInputType.emailAddress),

                const SizedBox(height: 12),

                _input("District", _district),
                _input("Address", _address, maxLines: 2),

                const SizedBox(height: 12),

                _input("Highest Education", _education),
                _input("Experience Level (e.g. Fresher / 1-3 years)", _experienceLevel),
                _input("Experience Details", _experienceDetails, maxLines: 2),

                const SizedBox(height: 12),

                _input("Skills * (comma separated)", _skills, maxLines: 2),
                _input("Expected Salary (optional)", _expectedSalary),
                _input("Availability (optional)", _availability),

                const SizedBox(height: 12),

                _input("Additional Info / Cover Note", _additionalInfo, maxLines: 3),

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
                  "Your resume and profile photo will be automatically attached if uploaded in Profile Edit.",
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
    );
  }

  Widget _card({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.hTitle),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: KhilonjiyaUI.body.copyWith(
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController c, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
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
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}