import 'package:flutter/material.dart';

import '../core/auth/user_role.dart';
import '../routes/app_routes.dart';
import '../services/mobile_auth_service.dart';

import '../presentation/home_marketplace_feed/job_seeker_main_shell.dart';
import '../presentation/company/dashboard/company_dashboard.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  late final MobileAuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = MobileAuthService();
  }

  Future<UserRole?> _resolveRoleOrNull() async {
    // 1) Ensure session exists
    final ok = await _auth.refreshSession();
    if (!ok) return null;

    // 2) DB is final truth
    return await _auth.syncRoleFromDbStrict(fallback: UserRole.jobSeeker);
  }

  void _goToRoleSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // Do NOT store the future in initState.
    // We must resolve role again after login.
    return FutureBuilder<UserRole?>(
      future: _resolveRoleOrNull(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snap.data;

        // No session → go RoleSelection
        if (role == null) {
          _goToRoleSelection();
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Role based routing
        if (role == UserRole.employer) {
          return const CompanyDashboard();
        }

        // Job seeker
        return const JobSeekerMainShell();
      },
    );
  }
}