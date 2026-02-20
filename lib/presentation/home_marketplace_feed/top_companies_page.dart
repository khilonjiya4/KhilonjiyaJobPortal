// File: lib/presentation/home_marketplace_feed/top_companies_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/company_card.dart';
import 'company_details_page.dart';

class TopCompaniesPage extends StatefulWidget {
  const TopCompaniesPage({Key? key}) : super(key: key);

  @override
  State<TopCompaniesPage> createState() => _TopCompaniesPageState();
}

class _TopCompaniesPageState extends State<TopCompaniesPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  bool _disposed = false;

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    _disposed = true;
    _searchCtrl.removeListener(_applySearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    try {
      final list = await _service.fetchTopCompanies(limit: 80);

      _companies = List<Map<String, dynamic>>.from(list);
      _filtered = List<Map<String, dynamic>>.from(list);
    } catch (_) {
      _companies = [];
      _filtered = [];
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      if (!_disposed) {
        setState(() => _filtered = List.from(_companies));
      }
      return;
    }

    final result = _companies.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final industry = (c['industry'] ?? '').toString().toLowerCase();
      final city =
          (c['headquarters_city'] ?? '').toString().toLowerCase();
      final state =
          (c['headquarters_state'] ?? '').toString().toLowerCase();

      final business =
          c['business_types_master'] as Map<String, dynamic>?;

      final businessType =
          (business?['type_name'] ?? '').toString().toLowerCase();

      return name.contains(q) ||
          industry.contains(q) ||
          businessType.contains(q) ||
          city.contains(q) ||
          state.contains(q);
    }).toList();

    if (!_disposed) setState(() => _filtered = result);
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Future<void> _openCompany(Map<String, dynamic> company) async {
    final companyId = (company['id'] ?? '').toString();
    if (companyId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(companyId: companyId),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: KhilonjiyaUI.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      "Top companies",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            // SEARCH
            Container(
              padding:
                  const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: Colors.white,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search companies",
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No companies found",
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(
                                    16, 16, 16, 120),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final c = _filtered[i];

                              return CompanyCard(
                                company: c,
                                onTap: () =>
                                    _openCompany(c),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}