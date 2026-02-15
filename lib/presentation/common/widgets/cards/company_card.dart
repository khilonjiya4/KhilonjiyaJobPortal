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

  static const double _cardHeight = 108; // fixed (same feel as job cards)
  static const double _logoSize = _cardHeight * 0.30; // 32.4

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------
    final name = (company['name'] ?? 'Company').toString().trim();

    // Option A: companies.business_types_master(type_name, logo_url)
    final bt = company['business_types_master'];

    String businessType = '';
    String? businessIconUrl;

    if (bt is Map<String, dynamic>) {
      businessType = (bt['type_name'] ?? '').toString().trim();
      final url = (bt['logo_url'] ?? '').toString().trim();
      businessIconUrl = url.isEmpty ? null : url;
    }

    // fallback
    if (businessType.isEmpty) {
      businessType = (company['industry'] ?? 'Business').toString().trim();
    }
    if (businessType.isEmpty) businessType = "Business";

    final isVerified = (company['is_verified'] ?? false) == true;

    final ratingRaw = company['rating'];
    final rating = _toDouble(ratingRaw);

    final companySize = (company['company_size'] ?? '').toString().trim();

    final totalJobs = _toInt(company['total_jobs']);

    // ------------------------------------------------------------
    // UI
    // ------------------------------------------------------------
    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        height: _cardHeight,
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
        child: Row(
          children: [
            // ============================================================
            // LEFT: BUSINESS TYPE LOGO (30% HEIGHT)
            // ============================================================
            _BusinessTypeIcon(
              businessType: businessType,
              iconUrl: businessIconUrl,
              size: _logoSize,
            ),

            const SizedBox(width: 14),

            // ============================================================
            // CENTER: NAME + BUSINESS TYPE + META
            // ============================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // COMPANY NAME (HIGHEST)
                  Text(
                    name.isEmpty ? "Company" : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.4,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // BUSINESS TYPE (SECOND)
                  Text(
                    businessType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      height: 1.05,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // META (clean + minimal)
                  Row(
                    children: [
                      if (isVerified) ...[
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Verified",
                          style: KhilonjiyaUI.sub.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF334155),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: KhilonjiyaUI.sub.copyWith(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF334155),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (companySize.isNotEmpty) ...[
                        const Icon(
                          Icons.groups_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            companySize,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KhilonjiyaUI.sub.copyWith(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ============================================================
            // RIGHT: JOB COUNT (LIGHT ORANGE + SMALLER)
            // ============================================================
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalJobs <= 0 ? "0" : "$totalJobs",
                  style: KhilonjiyaUI.cardTitle.copyWith(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF59E0B),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "jobs",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                    height: 1.0,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: KhilonjiyaUI.muted,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

// ============================================================
// BUSINESS TYPE ICON (Option A)
// - Uses business_types_master.logo_url
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (iconUrl == null || iconUrl!.trim().isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.50,
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
                      fontSize: size * 0.50,
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