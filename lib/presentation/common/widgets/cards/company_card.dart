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

  static const double _cardHeight = 108; // same feel as job cards
  static const double _logoSize = _cardHeight * 0.30; // 30% height

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
            // LEFT: TEXT BLOCK
            // Company Name + Verified
            // Business Type
            // Jobs Posted
            // ============================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --------------------------------------------------------
                  // Company name + verified icon
                  // --------------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? "Company" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KhilonjiyaUI.cardTitle.copyWith(
                            fontSize: 15.6,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),

                  // --------------------------------------------------------
                  // Business type
                  // --------------------------------------------------------
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

                  // --------------------------------------------------------
                  // Jobs posted
                  // --------------------------------------------------------
                  Text(
                    "${totalJobs <= 0 ? 0 : totalJobs} jobs posted",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF94A3B8),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ============================================================
            // RIGHT: BUSINESS TYPE LOGO
            // ============================================================
            _BusinessTypeIcon(
              businessType: businessType,
              iconUrl: businessIconUrl,
              size: _logoSize,
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