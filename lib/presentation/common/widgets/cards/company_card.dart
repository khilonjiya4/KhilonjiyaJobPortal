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
    final industry = (company['industry'] ?? '').toString().trim();
    final totalJobs = _toInt(company['total_jobs']);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), // ✅ matches job cards
        padding: const EdgeInsets.all(16), // ✅ matches job cards
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
            _CompanyLogo(name: name),
            const SizedBox(width: 14),

            // ------------------------------------------------------------
            // NAME + INDUSTRY
            // ------------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? "Company" : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle.copyWith(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    industry.isEmpty ? "Type of business" : industry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub.copyWith(
                      fontSize: 12.6,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ------------------------------------------------------------
            // JOB COUNT
            // ------------------------------------------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalJobs <= 0 ? "0" : "$totalJobs",
                  style: KhilonjiyaUI.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "jobs",
                  style: KhilonjiyaUI.sub.copyWith(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 6),

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

// ------------------------------------------------------------
// LOGO (LETTER FOR NOW)
// ------------------------------------------------------------
class _CompanyLogo extends StatelessWidget {
  final String name;

  const _CompanyLogo({required this.name});

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
      alignment: Alignment.center,
      child: Text(
        letter,
        style: KhilonjiyaUI.h1.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }
}