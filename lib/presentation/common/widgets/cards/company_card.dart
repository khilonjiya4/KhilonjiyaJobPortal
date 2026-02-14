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
    final isVerified = company['is_verified'] == true;

    final totalJobs = _toInt(company['total_jobs']);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        child: Column(
          children: [
            // ============================================================
            // LOGO
            // ============================================================
            _CompanyLogo(
              logoUrl: logoUrl,
              name: name,
            ),

            const SizedBox(height: 12),

            // ============================================================
            // COMPANY NAME + VERIFIED
            // ============================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name.isEmpty ? "Company" : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
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

            const SizedBox(height: 8),

            // ============================================================
            // INDUSTRY TAG (OPTIONAL)
            // ============================================================
            if (industry.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                  ),
                ),
                child: Text(
                  industry,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFB45309),
                  ),
                ),
              )
            else
              const SizedBox(height: 26),

            const Spacer(),

            // ============================================================
            // JOBS COUNT
            // ============================================================
            Text(
              totalJobs <= 0 ? "No active jobs" : "$totalJobs active jobs",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KhilonjiyaUI.sub.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 10),

            // ============================================================
            // VIEW JOBS BUTTON (Axis style)
            // ============================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                ),
              ),
              child: Center(
                child: Text(
                  "View jobs",
                  style: KhilonjiyaUI.link.copyWith(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                    color: KhilonjiyaUI.primary,
                  ),
                ),
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
      width: 62,
      height: 62,
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
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF334155),
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.contain,
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