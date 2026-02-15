// File: lib/presentation/common/widgets/cards/job_card_horizontal.dart

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

  static const double cardWidth = 320;
  static const double cardHeight = 170;

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA
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

    final salaryText = _salaryText(
      salaryMin: salaryMin,
      salaryMax: salaryMax,
    );

    final postedAt = job['created_at']?.toString();

    // ------------------------------------------------------------
    // BUSINESS TYPE LOGO (placeholder for now)
    // Later you will pass:
    // job['business_type'] or job['companies']['industry']
    // ------------------------------------------------------------
    final businessType =
        (job['business_type'] ?? companyMap?['industry'] ?? 'Business')
            .toString()
            .trim();

    // ------------------------------------------------------------
    // UI
    // ------------------------------------------------------------
    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        width: cardWidth,
        height: cardHeight,
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
          children: [
            // ============================================================
            // TOP: TITLE + SAVE + RIGHT LOGO
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // JOB TITLE (1 LINE)
                      Text(
                        title.isEmpty ? "Job" : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.cardTitle.copyWith(
                          fontSize: 15.2,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // COMPANY (1 LINE)
                      Text(
                        company.isEmpty ? "Company" : company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF334155),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // SAVE ICON
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

                const SizedBox(width: 6),

                // RIGHT SIDE LOGO (BUSINESS TYPE)
                _BusinessTypeLogo(
                  businessType: businessType,
                  size: 52,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ============================================================
            // LOCATION
            // ============================================================
            _plainRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF2563EB),
              text: location,
            ),

            const SizedBox(height: 8),

            // ============================================================
            // SALARY
            // ============================================================
            _plainRow(
              icon: Icons.currency_rupee_rounded,
              iconColor: const Color(0xFF16A34A),
              text: salaryText,
            ),

            const Spacer(),

            // ============================================================
            // FOOTER: POSTED AGO (ALWAYS LAST LINE)
            // ============================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    _postedAgo(postedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.2,
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
              fontSize: 13.2,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SALARY
  // ============================================================
  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
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

    if (mn != null && mx != null) return "$mn-$mx per month";
    if (mn != null) return "$mn+ per month";
    return "Up to ${mx!} per month";
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
// BUSINESS TYPE LOGO PLACEHOLDER
// Later replace with actual image mapping
// ============================================================
class _BusinessTypeLogo extends StatelessWidget {
  final String businessType;
  final double size;

  const _BusinessTypeLogo({
    required this.businessType,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final name = businessType.trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'B';

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