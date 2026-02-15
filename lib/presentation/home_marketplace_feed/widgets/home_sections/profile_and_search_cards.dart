// File: lib/presentation/home_marketplace_feed/widgets/home_sections/profile_and_search_cards.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ProfileAndSearchCards extends StatelessWidget {
  // LEFT CARD
  final String profileName;
  final int profileCompletion;
  final String lastUpdatedText;
  final int missingDetails; // kept for compatibility (not used in UI now)

  // RIGHT CARD
  final int jobsPostedToday;

  // EVENTS
  final VoidCallback? onProfileTap;
  final VoidCallback? onMissingDetailsTap; // kept for compatibility (not used now)
  final VoidCallback? onViewAllTap;

  const ProfileAndSearchCards({
    Key? key,
    required this.profileName,
    required this.profileCompletion,
    required this.lastUpdatedText,
    required this.missingDetails,
    required this.jobsPostedToday,
    this.onProfileTap,
    this.onMissingDetailsTap,
    this.onViewAllTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completion = profileCompletion.clamp(0, 100);
    final value = completion / 100.0;

    return Row(
      children: [
        // LEFT CARD (Profile)
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onProfileTap,
            child: _fixedHeightCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Circle
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 4,
                            backgroundColor: const Color(0xFFEFF2F6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              KhilonjiyaUI.primary,
                            ),
                          ),
                        ),
                        Text(
                          "$completion%",
                          style: KhilonjiyaUI.caption.copyWith(
                            fontWeight: FontWeight.w900,
                            color: KhilonjiyaUI.text,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(profileName, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    lastUpdatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub,
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: onProfileTap,
                    child: Text(
                      "Complete Profile",
                      style: KhilonjiyaUI.link,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // RIGHT CARD (Jobs posted today)
        Expanded(
          child: _fixedHeightCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$jobsPostedToday",
                  style: KhilonjiyaUI.h1.copyWith(
                    fontSize: 26, // smaller than before
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF59E0B), // light orange
                  ),
                ),
                const SizedBox(height: 6),
                Text("Jobs posted today", style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 4),

                // Removed: "All India • Active only"
                Text(
                  "Active only",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.sub,
                ),

                const Spacer(),

                InkWell(
                  onTap: onViewAllTap,
                  child: Text("View all", style: KhilonjiyaUI.link),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // UI HELPERS
  // ------------------------------------------------------------

  Widget _fixedHeightCard({required Widget child}) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      child: child,
    );
  }
}