// File: lib/presentation/common/widgets/cards/company_card.dart

import 'dart:math';
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
    final totalJobs = _toInt(company['total_jobs']);

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ------------------------------------------------------------
            // LOGO (CENTER)
            // ------------------------------------------------------------
            _CompanyLogoMinimal(
              logoUrl: logoUrl,
              name: name,
              size: 58,
            ),

            const Spacer(),

            // ------------------------------------------------------------
            // JOBS COUNT (BOTTOM)
            // ------------------------------------------------------------
            Text(
              totalJobs <= 0 ? "No jobs" : "$totalJobs jobs",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.body.copyWith(
                fontSize: 13.0,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
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
// MINIMAL LOGO WIDGET
// - Uses real logo if available
// - Otherwise first letter
// - Clean, no extra UI
// ============================================================
class _CompanyLogoMinimal extends StatelessWidget {
  final String logoUrl;
  final String name;
  final double size;

  const _CompanyLogoMinimal({
    required this.logoUrl,
    required this.name,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final letter = cleanName.isNotEmpty ? cleanName[0].toUpperCase() : "C";

    // deterministic color per company
    final baseColor = Colors.primaries[
        Random(cleanName.isEmpty ? 7 : cleanName.hashCode)
            .nextInt(Colors.primaries.length)];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KhilonjiyaUI.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: size * 0.40,
                  fontWeight: FontWeight.w900,
                  color: baseColor,
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
                    style: TextStyle(
                      fontSize: size * 0.40,
                      fontWeight: FontWeight.w900,
                      color: baseColor,
                    ),
                  ),
                );
              },
            ),
    );
  }
}