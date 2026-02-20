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
    final title =
        (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    // ✅ FIX 1: Proper company name resolution (like horizontal)
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

    final salary = _salaryText(
      salaryMin: job['salary_min'],
      salaryMax: job['salary_max'],
    );

    final exp = _experience(job);

    final postedAt = job['created_at']?.toString();

    final companyLogoUrl =
        (job['companies']?['logo_url'] ?? '').toString().trim();

    // ✅ FIX 2: Business icon resolution like horizontal
    String? businessIconUrl;

    if (companyMap is Map<String, dynamic>) {
      final bt = companyMap['business_types_master'];

      if (bt is Map<String, dynamic>) {
        final url = (bt['logo_url'] ?? '').toString().trim();
        businessIconUrl = url.isEmpty ? null : url;
      }

      if (businessIconUrl == null) {
        final url = (companyMap['logo_url'] ?? '').toString().trim();
        businessIconUrl = url.isEmpty ? null : url;
      }
    }

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
            // ✅ FIX 2: Styled business icon (no faded opacity)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: _BusinessTypeIcon(
                  iconUrl: businessIconUrl,
                  size: _businessIconSize,
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                // ✅ FIX 3: Icons styled like horizontal
                _infoRow(Icons.location_on_outlined,
                    const Color(0xFF2563EB), location),
                const SizedBox(height: 6),
                _infoRow(Icons.work_outline_rounded,
                    const Color(0xFF475569), exp),
                const SizedBox(height: 6),
                _infoRow(Icons.currency_rupee_rounded,
                    const Color(0xFF16A34A), salary),

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

  Widget _infoRow(IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
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
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final mn = toInt(salaryMin);
    final mx = toInt(salaryMax);

    if (mn == null && mx == null) return "Not disclosed";
    if (mn != null && mx != null) return "$mn-$mx per month";
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

class _BusinessTypeIcon extends StatelessWidget {
  final String? iconUrl;
  final double size;

  const _BusinessTypeIcon({
    required this.iconUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: (iconUrl == null || iconUrl!.isEmpty)
          ? const SizedBox()
          : Image.network(
              iconUrl!,
              fit: BoxFit.cover,
            ),
    );
  }
}