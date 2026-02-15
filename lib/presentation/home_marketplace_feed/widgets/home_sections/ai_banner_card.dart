import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class AIBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;

  /// Later this will open Recommended Jobs listing page.
  /// For now, keep it optional.
  final VoidCallback? onTap;

  const AIBannerCard({
    Key? key,
    this.title = "Welcome to Khilonjiya Job Portal.",
    this.subtitle = "Let’s find your next job. Start now!",
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: KhilonjiyaUI.r20,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F3FF), // same as BoostCard
            Color(0xFFE0E7FF), // same as BoostCard
          ],
        ),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: InkWell(
        borderRadius: KhilonjiyaUI.r20,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: KhilonjiyaUI.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: KhilonjiyaUI.sub.copyWith(
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF4F46E5), // same as BoostCard
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}