import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class KhilonjiyaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const KhilonjiyaBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.blue,
          unselectedItemColor: AppTheme.subText,
          selectedFontSize: 11.2,
          unselectedFontSize: 11.2,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: "My Jobs",
            ),

            // ✅ Subscription (replaced Messages)
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: "Subscription",
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              activeIcon: Icon(Icons.bookmark_rounded),
              label: "Saved",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}