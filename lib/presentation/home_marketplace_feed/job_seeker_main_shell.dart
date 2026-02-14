import 'package:flutter/material.dart';

import 'widgets/khilonjiya_bottom_nav.dart';

import 'home_jobs_feed.dart';
import 'my_jobs_page.dart';
import 'messages_page.dart';
import 'saved_jobs_page.dart';
import 'profile_page.dart';

class JobSeekerMainShell extends StatefulWidget {
  const JobSeekerMainShell({Key? key}) : super(key: key);

  @override
  State<JobSeekerMainShell> createState() => _JobSeekerMainShellState();
}

class _JobSeekerMainShellState extends State<JobSeekerMainShell> {
  int _index = 0;

  // Keep pages alive (world-class UX)
  late final List<Widget> _pages = const [
    HomeJobsFeed(), // Home
    MyJobsPage(), // My Jobs
    MessagesPage(), // Messages
    SavedJobsPage(), // Saved
    ProfilePage(), // Profile
  ];

  void _onTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: KhilonjiyaBottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),
    );
  }
}