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

  static const double cardWidth = 320;
  static const double cardHeight = 120;
  static const double _logoSize = cardHeight * 0.30;

  @override
  Widget build(BuildContext context) {
    final name = (company['name'] ?? '').toString().trim();
    final isVerified = (company['is_verified'] ?? false) == true;
    final totalJobs = _toInt(company['total_jobs']);
    final headquartersCity =
        (company['headquarters_city'] ?? '').toString().trim();

    String businessType = '';
    String? businessLogoUrl;

    final bt = company['business_types_master'];

    if (bt is Map<String, dynamic>) {
      businessType = (bt['type_name'] ?? '').toString().trim();
      final url = (bt['logo_url'] ?? '').toString().trim();
      businessLogoUrl = url.isEmpty ? null : url;
    }

    if (businessType.isEmpty) {
      businessType =
          (company['industry'] ?? '').toString().trim();
    }

    if (businessType.isEmpty) businessType = "Business";

    if (businessLogoUrl == null || businessLogoUrl.isEmpty) {
      final fallback =
          (company['logo_url'] ?? '').toString().trim();
      if (fallback.isNotEmpty) businessLogoUrl = fallback;
    }

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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                            fontSize: 15.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    businessType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                    ),
                  ),

                  if (headquartersCity.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      headquartersCity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.sub.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Text(
                    totalJobs <= 0
                        ? "0 jobs posted"
                        : "$totalJobs jobs posted",
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

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
    final letter =
        businessType.isNotEmpty ? businessType[0].toUpperCase() : "B";

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl == null || logoUrl!.isEmpty)
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
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
                    ),
                  ),
                );
              },
            ),
    );
  }
}