// File: lib/presentation/common/widgets/cards/company_card.dart

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

    final rating = _toDouble(company['rating']);
    final totalReviews = _toInt(company['total_reviews']);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KhilonjiyaUI.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ------------------------------------------------------------
            // LOGO (CENTER)
            // ------------------------------------------------------------
            _CompanyLogoSquare(
              logoUrl: logoUrl,
              name: name,
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------------
            // NAME (CENTER)
            // ------------------------------------------------------------
            Text(
              name.isEmpty ? "Company" : name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.body.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 14.4,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------------
            // RATING ROW (CENTER)
            // ------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 4),
                Text(
                  rating <= 0 ? "New" : rating.toStringAsFixed(1),
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.6,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  totalReviews <= 0 ? "0 reviews" : "$totalReviews reviews",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ------------------------------------------------------------
            // INDUSTRY TAG (CENTER)
            // ------------------------------------------------------------
            if (industry.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  industry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              )
            else
              const SizedBox(height: 28),

            const Spacer(),

            // ------------------------------------------------------------
            // VIEW JOBS (CENTER)
            // ------------------------------------------------------------
            Text(
              "View jobs",
              style: KhilonjiyaUI.link.copyWith(
                fontSize: 13.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------
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

class _CompanyLogoSquare extends StatelessWidget {
  final String logoUrl;
  final String name;

  const _CompanyLogoSquare({
    required this.logoUrl,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: KhilonjiyaUI.h1.copyWith(
                  fontSize: 22,
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
                      fontSize: 22,
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