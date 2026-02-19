import 'package:flutter/material.dart';

import '../../../services/employer_dashboard_service.dart';
import 'company_dashboard.dart';
import 'create_organization_screen.dart';

class EmployerOrgGateScreen extends StatefulWidget {
  const EmployerOrgGateScreen({Key? key}) : super(key: key);

  @override
  State<EmployerOrgGateScreen> createState() => _EmployerOrgGateScreenState();
}

class _EmployerOrgGateScreenState extends State<EmployerOrgGateScreen> {
  final EmployerDashboardService _service = EmployerDashboardService();

  bool _loading = true;
  bool _hasOrg = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final companies = await _service.fetchMyCompanies();
      _hasOrg = companies.isNotEmpty;
    } catch (_) {
      _hasOrg = false;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasOrg) {
      return const CompanyDashboard();
    }

    return const CreateOrganizationScreen();
  }
}