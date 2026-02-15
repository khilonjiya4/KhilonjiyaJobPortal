// File: lib/presentation/home_marketplace_feed/widgets/home_sections/job_card_horizontal.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardHorizontal({
    Key? key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  }) : super(key: key);

  static const double cardWidth = 300; // ✅ SAME AS BEFORE
  static const double cardHeight = 210; // ✅ SAME AS HOME LIST HEIGHT

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA (SAME AS JobCardWidget)
    // ------------------------------------------------------------
    final title = (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

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

    final isInternship = _isInternship(job);
    final isWalkIn = _isWalkIn(job);

    final skills = _extractSkills(job);

    final postedAt = job['created_at']?.toString();

    // ------------------------------------------------------------
    // UI
    // ------------------------------------------------------------
    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        width: cardWidth,
        height: cardHeight, // ✅ FIXED HEIGHT
        padding: const EdgeInsets.all(14),
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
            // ROW 1: LOGO + TITLE + SAVE
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLetterLogo(company: company, size: 48),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title.isEmpty ? "Job" : title,
                    maxLines: 1, // ✅ FIXED (no gap issue)
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 14.6,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                InkWell(
                  onTap: onSaveToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                      size: 22,
                      color: isSaved
                          ? KhilonjiyaUI.primary
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // ============================================================
            // ROW 2: COMPANY (1 LINE)
            // ============================================================
            Padding(
              padding: const EdgeInsets.only(left: 58), // aligns with title
              child: Text(
                company.isEmpty ? "Company" : company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KhilonjiyaUI.sub.copyWith(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                  height: 1.15,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ============================================================
            // ROW 3: LOCATION
            // ============================================================
            _plainRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF2563EB), // ✅ colorful
              text: location,
            ),

            const SizedBox(height: 7),

            // ============================================================
            // ROW 4: EXPERIENCE
            // ============================================================
            _plainRow(
              icon: Icons.work_rounded,
              iconColor: const Color(0xFF7C3AED), // ✅ colorful
              text: expText,
            ),

            const SizedBox(height: 7),

            // ============================================================
            // ROW 5: SALARY
            // ============================================================
            _plainRow(
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF16A34A), // ✅ colorful
              text: salaryText,
            ),

            const SizedBox(height: 10),

            // ============================================================
            // ROW 6: TAGS (1 LINE ONLY)
            // ============================================================
            if (isInternship || isWalkIn || skills.isNotEmpty)
              SizedBox(
                height: 30, // ✅ fixed height so cards stay equal
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (isInternship) _metaTag("Internship"),
                    if (isInternship) const SizedBox(width: 8),
                    if (isWalkIn) _metaTag("Walk-in"),
                    if (isWalkIn) const SizedBox(width: 8),
                    ...skills.take(4).expand((s) => [
                          _metaTag(s),
                          const SizedBox(width: 8),
                        ]),
                  ],
                ),
              )
            else
              const SizedBox(height: 30), // keeps same height

            const Spacer(),

            // ============================================================
            // FOOTER
            // ============================================================
            Row(
              children: [
                Text(
                  _postedAgo(postedAt),
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.0,
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
    required Color iconColor,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text.trim().isEmpty ? "—" : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.body.copyWith(
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: KhilonjiyaUI.sub.copyWith(
          fontSize: 12.0,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }

  // ============================================================
  // EXPERIENCE FORMATTER
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

      if (lower.contains('year')) {
        final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ');
        return cleaned
            .replaceAll('Years', 'years')
            .replaceAll('Year', 'year');
      }

      final range = RegExp(r'^(\d+)\s*-\s*(\d+)$');
      if (range.hasMatch(raw)) {
        return "${raw.replaceAll(' ', '')} years";
      }

      final single = int.tryParse(raw);
      if (single != null) {
        return single == 1 ? "1 year" : "$single years";
      }

      return raw;
    }

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
  // SALARY
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
      range = "$mn-$mx";
    } else if (mn != null) {
      range = "$mn+";
    } else {
      range = "Up to ${mx!}";
    }

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
  // TAGS
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

// ============================================================
// COMPANY LOGO (FIRST LETTER ONLY)
// ============================================================
class _CompanyLetterLogo extends StatelessWidget {
  final String company;
  final double size;

  const _CompanyLetterLogo({
    required this.company,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final name = company.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    final color = Colors.primaries[
        Random(name.isEmpty ? 1 : name.hashCode).nextInt(Colors.primaries.length)
    ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}