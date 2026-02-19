import 'dart:math';
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

  static const double _logoSize = 52;
  static const double _businessLogoSize = 48;

  @override
  Widget build(BuildContext context) {
    final title =
        (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    final companyMap = job['companies'];
    final companyName = (companyMap is Map<String, dynamic>)
        ? (companyMap['name'] ?? '').toString().trim()
        : '';

    final company = companyName.isNotEmpty
        ? companyName
        : (job['company_name'] ?? 'Company').toString().trim();

    final location =
        (job['district'] ?? job['location'] ?? 'Location').toString().trim();

    final salaryMin = job['salary_min'];
    final salaryMax = job['salary_max'];

    final expText = _formatExperience(job);
    final salaryText =
        _salaryText(salaryMin: salaryMin, salaryMax: salaryMax);

    final skills = _extractSkills(job);
    final postedAt = job['created_at']?.toString();

    // Company logo
    String? companyLogoUrl;
    if (companyMap is Map<String, dynamic>) {
      final url = (companyMap['logo_url'] ?? '').toString().trim();
      if (url.isNotEmpty) companyLogoUrl = url;
    }

    // Business type logo
    String? businessIconUrl;
    if (companyMap is Map<String, dynamic>) {
      final bt = companyMap['business_types_master'];
      if (bt is Map<String, dynamic>) {
        final url = (bt['logo_url'] ?? '').toString().trim();
        if (url.isNotEmpty) businessIconUrl = url;
      }
    }

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
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // BUSINESS TYPE LOGO (center right)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _BusinessTypeIcon(
                  iconUrl: businessIconUrl,
                  size: _businessLogoSize,
                ),
              ),
            ),

            // MAIN CONTENT
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP ROW (Logo + Title + Bookmark)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyLogo(
                      companyName: company,
                      logoUrl: companyLogoUrl,
                      size: _logoSize,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500, // slim
                          height: 1.15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onSaveToggle,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline,
                          size: 22,
                          color: isSaved
                              ? KhilonjiyaUI.primary
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Everything below is full width (NO GAP)
                Text(
                  company,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 8),
                _plainRow(Icons.location_on_rounded, location),
                const SizedBox(height: 6),
                _plainRow(Icons.work_rounded, expText),
                const SizedBox(height: 6),
                _plainRow(Icons.currency_rupee_rounded, salaryText),

                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        skills.take(6).map((s) => _orangeTag(s)).toList(),
                  ),
                ],

                const SizedBox(height: 12),

                Text(
                  _postedAgo(postedAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _plainRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orangeTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFE0C2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9A3412),
        ),
      ),
    );
  }

  // EXPERIENCE
  String _formatExperience(Map<String, dynamic> job) {
    final raw = (job['experience_required'] ??
            job['experience_level'] ??
            '')
        .toString()
        .trim();

    if (raw.isNotEmpty) return raw;
    return "Experience not specified";
  }

  // SALARY
  String _salaryText({
    required dynamic salaryMin,
    required dynamic salaryMax,
  }) {
    if (salaryMin == null && salaryMax == null) return "Not disclosed";
    return "$salaryMin-$salaryMax per month";
  }

  List<String> _extractSkills(Map<String, dynamic> job) {
    final raw = job['skills_required'];
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return raw.toString().split(',');
  }

  String _postedAgo(String? date) {
    if (date == null) return 'Recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================
// COMPANY LOGO
// ============================================================

class _CompanyLogo extends StatelessWidget {
  final String companyName;
  final String? logoUrl;
  final double size;

  const _CompanyLogo({
    required this.companyName,
    required this.logoUrl,
    required this.size,
  });

  Color _randomColor(String seed) {
    final colors = [
      const Color(0xFFE0F2FE),
      const Color(0xFFFFEDD5),
      const Color(0xFFDCFCE7),
      const Color(0xFFFCE7F3),
      const Color(0xFFEDE9FE),
    ];
    return colors[seed.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final letter =
        companyName.isNotEmpty ? companyName[0].toUpperCase() : "C";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _randomColor(companyName),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl == null || logoUrl!.isEmpty)
          ? Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            )
          : Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// BUSINESS TYPE ICON
// ============================================================

class _BusinessTypeIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;

  const _BusinessTypeIcon({
    required this.iconUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        iconUrl!,
        fit: BoxFit.cover,
      ),
    );
  }
}