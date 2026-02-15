// File: lib/presentation/home_marketplace_feed/expected_salary_edit_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

class ExpectedSalaryEditPage extends StatefulWidget {
  final int initialSalaryPerMonth;

  const ExpectedSalaryEditPage({
    Key? key,
    required this.initialSalaryPerMonth,
  }) : super(key: key);

  @override
  State<ExpectedSalaryEditPage> createState() => _ExpectedSalaryEditPageState();
}

class _ExpectedSalaryEditPageState extends State<ExpectedSalaryEditPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  bool _saving = false;

  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialSalaryPerMonth <= 0
          ? ''
          : widget.initialSalaryPerMonth.toString(),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: KhilonjiyaUI.sub,
      prefixIcon: const Icon(Icons.currency_rupee_rounded),
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

  Future<void> _save() async {
    if (_saving) return;

    final raw = _ctrl.text.trim();
    final v = int.tryParse(raw) ?? 0;

    if (v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid salary amount")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.updateExpectedSalaryPerMonth(v);

      if (!mounted) return;

      // return salary to previous page
      Navigator.pop(context, v);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update expected salary")),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
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
                      "Expected salary",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
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
                            Icons.currency_rupee_rounded,
                            color: KhilonjiyaUI.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Set expected salary",
                                style: KhilonjiyaUI.hTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "We will show jobs with salary equal to or higher than this.",
                                style: KhilonjiyaUI.sub,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "Expected salary per month",
                    style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w900),
                    decoration: _dec("Example: 15000"),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
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
                              "Save",
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}