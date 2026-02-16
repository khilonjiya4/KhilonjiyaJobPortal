import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class CompanyCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> company;
  final VoidCallback? onTap;

  const CompanyCardHorizontal({
    Key? key,
    required this.company,
    this.onTap,
  }) : super(key: key);

  // Same width feel as JobCardHorizontal
  static const double cardWidth = 320;
  static const double cardHeight = 120;

  // Logo must be 30% of height
  static const double _logoSize = cardHeight * 0.30; // 36

  @override
  Widget build(BuildContext context) {
    // ------------------------------------------------------------
    // DATA
    // ------------------------------------------------------------
    final name = (company['name'] ?? 'Company').toString().trim();
    final isVerified = (company['is_verified'] ?? false) == true;
    final totalJobs = _toInt(company['total_jobs']);

    // Option A: companies.business_types_master(type_name, logo_url)
    final bt = company['business_types_master'];

    String businessType = '';
    String? businessLogoUrl;

    if (bt is Map<String, dynamic>) {
      businessType = (bt['type_name'] ?? '').toString().trim();
      final url = (bt['logo_url'] ?? '').toString().trim();
      businessLogoUrl = url.isEmpty ? null : url;
    }

    // fallback
    if (businessType.isEmpty) {
      businessType = (company['industry'] ?? 'Business').toString().trim();
    }
    if (businessType.isEmpty) businessType = "Business";

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ============================================================
            // LEFT TEXT
            // ============================================================
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAME + VERIFIED
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? "Company" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KhilonjiyaUI.cardTitle.copyWith(
                            fontSize: 15.4,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // BUSINESS TYPE
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

                  // JOB COUNT (small + clean)
                  Text(
                    totalJobs <= 0 ? "0 jobs posted" : "$totalJobs jobs posted",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B), // light orange
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ============================================================
            // RIGHT LOGO (CENTERED)
            // ============================================================
            _BusinessTypeLogo(
              businessType: businessType,
              logoUrl: businessLogoUrl,
              size: _logoSize,
            ),

            const SizedBox(width: 10),

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

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

// ============================================================
// BUSINESS TYPE LOGO (Option A)
// ============================================================
class _BusinessTypeLogo extends StatelessWidget {
  final String businessType;
  final String? logoUrl;
  final double size;

  const _BusinessTypeLogo({
    required this.businessType,
    required this.logoUrl,
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
      child: (logoUrl == null || logoUrl!.trim().isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  height: 1.0,
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
                    style: TextStyle(
                      fontSize: size * 0.52,
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