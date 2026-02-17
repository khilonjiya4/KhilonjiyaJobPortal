// File: lib/presentation/home_marketplace_feed/widgets/home_sections/expected_salary_card.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ExpectedSalaryCard extends StatelessWidget {
  /// Now this card is NOT profile-based.
  /// It is an "on-the-go" feature:
  /// Tap -> open salary input -> show jobs by salary.
  final VoidCallback? onTap;

  const ExpectedSalaryCard({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF7ED), // light orange
            Color(0xFFFFEDD5), // light peach
          ],
        ),
        border: Border.all(color: const Color(0xFFE6E8EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Color(0xFF9A3412),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jobs by salary",
                      style: KhilonjiyaUI.cardTitle.copyWith(
                        fontSize: 14,
                        color: const Color(0xFF7C2D12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Enter expected salary and view matching jobs",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.sub.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}