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

  // ✅ FIX: Separate callbacks
  final VoidCallback? onProfileViewAllTap; // left card view all (same as profile)
  final VoidCallback? onJobsPostedTodayViewAllTap; // right card view all

  const ProfileAndSearchCards({
    Key? key,
    required this.profileName,
    required this.profileCompletion,
    required this.lastUpdatedText,
    required this.missingDetails,
    required this.jobsPostedToday,
    this.onProfileTap,
    this.onMissingDetailsTap,
    this.onProfileViewAllTap,
    this.onJobsPostedTodayViewAllTap,
  }) : super(key: key);

  bool _isFakeUserName(String name) {
    final n = name.trim().toLowerCase();

    // empty -> fake
    if (n.isEmpty) return true;

    // user<mobile> -> fake
    // examples: user9876543210, user_9876543210, user 9876543210
    if (n.startsWith("user")) return true;

    // if only digits -> fake
    if (RegExp(r'^\d+$').hasMatch(n)) return true;

    return false;
  }

  String _displayProfileTitle(String rawName) {
    final name = rawName.trim();

    if (_isFakeUserName(name)) {
      return "Your Profile";
    }

    // If name exists, show: Pankaj's Profile
    final firstName = name.split(" ").first.trim();
    if (firstName.isEmpty) return "Your Profile";

    return "$firstName's Profile";
  }

  @override
  Widget build(BuildContext context) {
    final completion = profileCompletion.clamp(0, 100);
    final value = completion / 100.0;

    final profileTitle = _displayProfileTitle(profileName);

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

                  Text(profileTitle, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    lastUpdatedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.sub,
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: onProfileViewAllTap ?? onProfileTap,
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 6),
                Text("Jobs posted today", style: KhilonjiyaUI.cardTitle),
                const SizedBox(height: 4),
                Text(
                  "Active only",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KhilonjiyaUI.sub,
                ),

                const Spacer(),

                InkWell(
                  onTap: onJobsPostedTodayViewAllTap,
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