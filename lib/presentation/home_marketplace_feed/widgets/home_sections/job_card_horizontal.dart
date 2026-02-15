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

  static const double cardWidth = 300; // keep same
  static const double cardHeight = 210; // keep same

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA (same logic as JobCardWidget)
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
        height: cardHeight,
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
            // HEADER: LOGO + TITLE + SAVE
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // ✅ important
              children: [
                _CompanyLetterLogo(company: company, size: 48),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    title.isEmpty ? "Job" : title,
                    maxLines: 1, // ✅ always 1 line
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 14.6,
                      fontWeight: FontWeight.w900,
                      height: 1.05, // ✅ removes gap
                    ),
                  ),
                ),

                const SizedBox(width: 6),

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

            const SizedBox(height: 3),

            // ============================================================
            // COMPANY: 1 LINE, NO EXTRA GAP
            // ============================================================
            Padding(
              padding: const EdgeInsets.only(left: 58),
              child: Text(
                company.isEmpty ? "Company" : company,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KhilonjiyaUI.sub.copyWith(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                  height: 1.05, // ✅ removes gap
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ============================================================
            // LOCATION / EXP / SALARY
            // ============================================================
            _plainRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF2563EB),
              text: location,
            ),
            const SizedBox(height: 7),
            _plainRow(
              icon: Icons.work_rounded,
              iconColor: const Color(0xFF7C3AED),
              text: expText,
            ),
            const SizedBox(height: 7),
            _plainRow(
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF16A34A),
              text: salaryText,
            ),

            const SizedBox(height: 10),

            // ============================================================
            // TAGS (STRICT HEIGHT, NO OVERFLOW)
            // ============================================================
            _tagsRow(
              isInternship: isInternship,
              isWalkIn: isWalkIn,
              skills: skills,
            ),

            const Spacer(),

            // ============================================================
            // FOOTER (NO OVERLAP GUARANTEED)
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    _postedAgo(postedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.0,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
  // TAG ROW (NO OVERFLOW EVER)
  // ============================================================
  Widget _tagsRow({
    required bool isInternship,
    required bool isWalkIn,
    required List<String> skills,
  }) {
    final tags = <String>[];

    if (isInternship) tags.add("Internship");
    if (isWalkIn) tags.add("Walk-in");

    for (final s in skills.take(4)) {
      if (s.trim().isNotEmpty) tags.add(s.trim());
    }

    // Always reserve exact height so all cards equal
    if (tags.isEmpty) return const SizedBox(height: 28);

    return SizedBox(
      height: 28, // ✅ matches tag height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _metaTag(tags[i]),
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
              height: 1.15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaTag(String text) {
    return Container(
      height: 28, // ✅ fixed height so never overflow
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
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
          height: 1.0,
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
      if (range.hasMatch(raw)) return "${raw.replaceAll(' ', '')} years";

      final single = int.tryParse(raw);
      if (single != null) return single == 1 ? "1 year" : "$single years";

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