import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardWidget({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  });

  static const double _companyLogoSize = 46;
  static const double _businessIconSize = 52;

  @override
  Widget build(BuildContext context) {
    final title = (job['job_title'] ?? 'Job').toString().trim();
    final company = (job['company_name'] ?? 'Company').toString().trim();
    final location = (job['district'] ?? 'Location').toString().trim();

    final salary = _salaryText(
      salaryMin: job['salary_min'],
      salaryMax: job['salary_max'],
    );

    final exp = _experience(job);

    final postedAt = job['created_at']?.toString();

    final companyLogoUrl =
        (job['companies']?['logo_url'] ?? '').toString().trim();

    final businessIconUrl =
        (job['companies']?['business_types_master']?['logo_url'] ?? '')
            .toString()
            .trim();

    final skills = _extractSkills(job);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: KhilonjiyaUI.cardDecoration(),
        child: Stack(
          children: [
            // RIGHT CENTER BUSINESS ICON
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: _BusinessIcon(
                  iconUrl: businessIconUrl,
                  size: _businessIconSize,
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER ROW
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CompanyLogo(
                      name: company,
                      logoUrl: companyLogoUrl,
                      size: _companyLogoSize,
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KhilonjiyaUI.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KhilonjiyaUI.company,
                          ),
                        ],
                      ),
                    ),

                    InkWell(
                      onTap: onSaveToggle,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 22,
                          color: isSaved
                              ? KhilonjiyaUI.primary
                              : KhilonjiyaUI.muted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                _infoRow(Icons.location_on_outlined, location),
                const SizedBox(height: 6),
                _infoRow(Icons.work_outline, exp),
                const SizedBox(height: 6),
                _infoRow(Icons.currency_rupee, salary),

                if (skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: skills
                        .take(4)
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: KhilonjiyaUI.tagDecoration(),
                            child: Text(
                              e,
                              style: KhilonjiyaUI.tagTextStyle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  _postedAgo(postedAt),
                  style: KhilonjiyaUI.sub,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: KhilonjiyaUI.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.body,
          ),
        ),
      ],
    );
  }

  String _salaryText({dynamic salaryMin, dynamic salaryMax}) {
    int? toInt(v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final mn = toInt(salaryMin);
    final mx = toInt(salaryMax);

    if (mn == null && mx == null) return "Not disclosed";

    if (mn != null && mx != null) {
      return "$mn-$mx per month";
    }
    if (mn != null) return "$mn+ per month";
    return "Up to $mx per month";
  }

  String _experience(Map<String, dynamic> job) {
    final exp = (job['experience_required'] ?? '').toString();
    if (exp.isEmpty) return "Experience not specified";
    return exp;
  }

  List<String> _extractSkills(Map<String, dynamic> job) {
    final raw = job['skills_required'];
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return raw.toString().split(',').map((e) => e.trim()).toList();
  }

  String _postedAgo(String? date) {
    if (date == null) return '';
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ============================================================
// COMPANY LOGO
// ============================================================

class _CompanyLogo extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double size;

  const _CompanyLogo({
    required this.name,
    required this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "C";

    final colors = [
      const Color(0xFFE0F2FE),
      const Color(0xFFFCE7F3),
      const Color(0xFFEDE9FE),
      const Color(0xFFDCFCE7),
      const Color(0xFFFFEDD5),
    ];

    final bg = colors[Random().nextInt(colors.length)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// BUSINESS ICON
// ============================================================

class _BusinessIcon extends StatelessWidget {
  final String iconUrl;
  final double size;

  const _BusinessIcon({
    required this.iconUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.15,
      child: iconUrl.isEmpty
          ? const SizedBox()
          : Image.network(
              iconUrl,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
    );
  }
}