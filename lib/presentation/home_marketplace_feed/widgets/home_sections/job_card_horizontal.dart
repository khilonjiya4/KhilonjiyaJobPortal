// File: lib/presentation/common/widgets/cards/job_card_horizontal.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> job;

  // NOTE:
  // Horizontal card: NO save icon (as per final requirement)
  final VoidCallback onTap;

  const JobCardHorizontal({
    Key? key,
    required this.job,
    required this.onTap,
  }) : super(key: key);

  // Keep EXACT same as your earlier horizontal size
  static const double cardWidth = 320;
  static const double cardHeight = 170;

  // Logo should be 30% of card height
  static const double _logoSize = cardHeight * 0.30; // = 51

  // Fixed right column width so logo stays centered on the right side
  static const double _rightColumnWidth = 70;

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------
    final title = (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    // joined companies
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
    // BUSINESS TYPE (Option A)
    // companies.business_types_master (type_name, logo_url)
    // ------------------------------------------------------------
    String businessType = "Business";
    String? businessIconUrl;

    if (companyMap is Map<String, dynamic>) {
      final bt = companyMap['business_types_master'];

      if (bt is Map<String, dynamic>) {
        final name = (bt['type_name'] ?? '').toString().trim();
        if (name.isNotEmpty) businessType = name;

        final url = (bt['logo_url'] ?? '').toString().trim();
        businessIconUrl = url.isEmpty ? null : url;
      }

      // fallback if business_types_master is missing
      if (businessType.trim().isEmpty) {
        final fallback =
            (companyMap['industry'] ?? companyMap['business_type'] ?? '')
                .toString()
                .trim();
        if (fallback.isNotEmpty) businessType = fallback;
      }

      // fallback if logo is stored directly in companies
      if (businessIconUrl == null) {
        final url = (companyMap['logo_url'] ?? '').toString().trim();
        businessIconUrl = url.isEmpty ? null : url;
      }
    }

    if (businessType.trim().isEmpty) businessType = "Business";

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // LEFT CONTENT
            // ============================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JOB TITLE (HIGHEST)
                  Text(
                    title.isEmpty ? "Job" : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.4,
                      fontWeight: FontWeight.w900,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // COMPANY (MEDIUM)
                  Text(
                    company.isEmpty ? "Company" : company,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.body.copyWith(
                      fontSize: 13.1,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF334155),
                      height: 1.10,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LOCATION
                  _plainRow(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2563EB),
                    text: location,
                  ),

                  const SizedBox(height: 8),

                  // SALARY
                  _plainRow(
                    icon: Icons.currency_rupee_rounded,
                    iconColor: const Color(0xFF16A34A),
                    text: salaryText,
                  ),

                  const Spacer(),

                  // POSTED AGO (ALWAYS LAST LINE)
                  Text(
                    _postedAgo(postedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.1,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ============================================================
            // RIGHT SIDE (LOGO CENTERED)
            // ============================================================
            SizedBox(
              width: _rightColumnWidth,
              height: cardHeight - 32, // padding top+bottom = 32
              child: Center(
                child: _BusinessTypeIcon(
                  businessType: businessType,
                  iconUrl: businessIconUrl,
                  size: _logoSize,
                ),
              ),
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
              fontSize: 13.1,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.20,
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
// BUSINESS TYPE ICON (Option A)
// - Uses logo_url if available
// - Else first letter of business type
// ============================================================
class _BusinessTypeIcon extends StatelessWidget {
  final String businessType;
  final String? iconUrl;
  final double size;

  const _BusinessTypeIcon({
    required this.businessType,
    required this.iconUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final t = businessType.trim();
    final letter = t.isNotEmpty ? t[0].toUpperCase() : "B";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (iconUrl == null || iconUrl!.trim().isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.44,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.0,
                ),
              ),
            )
          : Image.network(
              iconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: size * 0.44,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      height: 1.0,
                    ),
                  ),
                );
              },
            ),
    );
  }
}