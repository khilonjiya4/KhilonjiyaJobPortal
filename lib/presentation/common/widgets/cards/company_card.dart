import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class CompanyCard extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onTap;

  const CompanyCard({
    Key? key,
    required this.company,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = (company['name'] ?? 'Company').toString().trim();
    final logoUrl = (company['logo_url'] ?? '').toString().trim();

    final industry = (company['industry'] ?? '').toString().trim();
    final size = (company['company_size'] ?? '').toString().trim();

    final isVerified = company['is_verified'] == true;

    final totalJobs = _toInt(company['total_jobs']);
    final subtitle = _subtitleText(industry: industry, size: size);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: KhilonjiyaUI.r16,
          border: Border.all(color: KhilonjiyaUI.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // TOP ROW (LOGO + NAME + VERIFIED)
            // ------------------------------------------------------------
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(logoUrl: logoUrl, name: name),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty ? "Company" : name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KhilonjiyaUI.cardTitle.copyWith(
                                fontSize: 14.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: KhilonjiyaUI.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle.isEmpty ? "Company profile" : subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontSize: 12.2,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ------------------------------------------------------------
            // FOOTER (JOBS COUNT)
            // ------------------------------------------------------------
            Row(
              children: [
                Text(
                  totalJobs <= 0 ? "No jobs" : "$totalJobs jobs",
                  style: KhilonjiyaUI.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: KhilonjiyaUI.muted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _subtitleText({
    required String industry,
    required String size,
  }) {
    final parts = <String>[];
    if (industry.trim().isNotEmpty) parts.add(industry.trim());
    if (size.trim().isNotEmpty) parts.add(size.trim());
    return parts.join(" • ");
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ------------------------------------------------------------
// LOGO (AXIS BANK STYLE)
// ------------------------------------------------------------
class _CompanyLogo extends StatelessWidget {
  final String logoUrl;
  final String name;

  const _CompanyLogo({
    required this.logoUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF334155),
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: KhilonjiyaUI.h1.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF334155),
                    ),
                  ),
                );
              },
            ),
    );
  }
}