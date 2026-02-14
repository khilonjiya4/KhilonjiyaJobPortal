// File: lib/presentation/common/widgets/cards/job_card_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardWidget({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------
    final title = (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    // Prefer joined companies.name if present
    final companyMap = job['companies'];
    final companyName = (companyMap is Map<String, dynamic>)
        ? (companyMap['name'] ?? '').toString().trim()
        : '';

    final company = companyName.isNotEmpty
        ? companyName
        : (job['company_name'] ?? job['company'] ?? 'Company')
            .toString()
            .trim();

    final location = (job['district'] ??
            job['location'] ??
            job['job_address'] ??
            'Location')
        .toString()
        .trim();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];
    final salaryPeriodRaw = (job['salary_period'] ?? 'Monthly').toString();

    final expText = _formatExperience(job);
    final salaryText = _salaryText(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      salaryPeriod: salaryPeriodRaw,
    );

    // Skills + tags
    final skills = _extractSkills(job);
    final isInternship = _isInternship(job);
    final isWalkIn = _isWalkIn(job);

    final postedAt = job['created_at']?.toString();

    // ------------------------------------------------------------
    // UI
    // ------------------------------------------------------------
    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KhilonjiyaUI.r16,
          border: Border.all(color: KhilonjiyaUI.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // ROW 1: TITLE + SAVE
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.2,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onSaveToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                      size: 24,
                      color: isSaved
                          ? KhilonjiyaUI.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ============================================================
            // ROW 2: COMPANY
            // ============================================================
            Text(
              company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),

            const SizedBox(height: 12),

            // ============================================================
            // ROW 3: LOCATION
            // ============================================================
            _plainRow(
              icon: Icons.location_on_outlined,
              text: location,
            ),

            const SizedBox(height: 8),

            // ============================================================
            // ROW 4: EXPERIENCE
            // ============================================================
            _plainRow(
              icon: Icons.work_outline_rounded,
              text: expText,
            ),

            const SizedBox(height: 8),

            // ============================================================
            // ROW 5: SALARY
            // ============================================================
            _plainRow(
              icon: Icons.currency_rupee_rounded,
              text: salaryText,
            ),

            // ============================================================
            // ROW 6: SYSTEMATIC TAGS (BELOW SALARY)
            // ============================================================
            if (isInternship || isWalkIn) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isInternship) _metaTag("Internship"),
                  if (isWalkIn) _metaTag("Walk-in"),
                ],
              ),
            ],

            // ============================================================
            // ROW 7: SKILLS META TAGS (AFTER SYSTEMATIC TAGS)
            // ============================================================
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.take(6).map((s) => _metaTag(s)).toList(),
              ),
            ],

            const SizedBox(height: 14),

            // ============================================================
            // ROW 8: POSTED AGO
            // ============================================================
            Row(
              children: [
                Text(
                  _postedAgo(postedAt),
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.2,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: KhilonjiyaUI.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _plainRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.trim().isEmpty ? "—" : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.body.copyWith(
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      child: Text(
        text,
        style: KhilonjiyaUI.sub.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  // ============================================================
  // EXPERIENCE FORMATTER (2-3 years / 3 years / Fresher)
  // ============================================================

  String _formatExperience(Map<String, dynamic> job) {
    final raw = (job['experience_required'] ??
            job['experience_level'] ??
            job['experience'] ??
            '')
        .toString()
        .trim();

    if (raw.isNotEmpty) {
      final lower = raw.toLowerCase();

      if (lower.contains('fresh')) return "Fresher";

      // Already contains year(s)
      if (lower.contains('year')) {
        final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ');
        return cleaned
            .replaceAll('Years', 'years')
            .replaceAll('Year', 'year');
      }

      // Range: "2-3"
      final range = RegExp(r'^(\d+)\s*-\s*(\d+)$');
      if (range.hasMatch(raw)) {
        return "${raw.replaceAll(' ', '')} years";
      }

      // Single number: "3"
      final single = int.tryParse(raw);
      if (single != null) {
        return single == 1 ? "1 year" : "$single years";
      }

      return raw;
    }

    // Optional support for future fields
    final expMin = job['experience_min'];
    final expMax = job['experience_max'];

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final mn = toInt(expMin);
    final mx = toInt(expMax);

    if (mn == null && mx == null) return "Experience not specified";

    if (mn != null && mx != null) {
      if (mn == 0 && mx == 0) return "Fresher";
      if (mn == mx) return mn == 1 ? "1 year" : "$mn years";
      return "$mn-$mx years";
    }

    if (mn != null) {
      if (mn == 0) return "Fresher";
      return mn == 1 ? "1 year" : "$mn years";
    }

    return "Up to $mx years";
  }

  // ============================================================
  // SALARY (5000 - 10000 per month)
  // ============================================================

  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
    required String salaryPeriod,
  }) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final mn = toInt(salaryMin);
    final mx = toInt(salaryMax);

    if (mn == null && mx == null) return "Not disclosed";

    String range;
    if (mn != null && mx != null) {
      range = "$mn - $mx";
    } else if (mn != null) {
      range = "$mn+";
    } else {
      range = "Up to ${mx!}";
    }

    // Force monthly label
    return "$range per month";
  }

  // ============================================================
  // SKILLS
  // ============================================================

  List<String> _extractSkills(Map<String, dynamic> job) {
    final raw = job['skills_required'];

    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return [];

    final cleaned = s.replaceAll('{', '').replaceAll('}', '');
    return cleaned
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  // ============================================================
  // SYSTEMATIC TAGS
  // ============================================================

  bool _isInternship(Map<String, dynamic> job) {
    final employmentType =
        (job['employment_type'] ?? '').toString().toLowerCase();
    return employmentType.contains('intern');
  }

  bool _isWalkIn(Map<String, dynamic> job) {
    final jobType = (job['job_type'] ?? '').toString().toLowerCase();
    final isWalk = jobType.contains('walk');
    final isWalkInFlag = (job['is_walk_in'] ?? false) == true;
    return isWalk || isWalkInFlag;
  }

  // ============================================================
  // POSTED AGO
  // ============================================================

  String _postedAgo(String? date) {
    if (date == null) return 'Recently';

    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }
}