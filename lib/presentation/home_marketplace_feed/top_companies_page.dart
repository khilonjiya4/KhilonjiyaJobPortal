// File: lib/presentation/home_marketplace_feed/top_companies_page.dart

import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/company_card.dart';
import 'company_details_page.dart'; // ✅ make sure this file exists

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
  // LOAD REAL DATA
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
  // SEARCH (REAL FILTER)
  // ============================================================
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      if (!_disposed) {
        setState(() => _filtered = List.from(_companies));
      }
      return;
    }

    final out = _companies.where((c) {
      final name =
          (c['name'] ?? '').toString().toLowerCase();

      final industry =
          (c['industry'] ?? '').toString().toLowerCase();

      return name.contains(q) || industry.contains(q);
    }).toList();

    if (!_disposed) {
      setState(() => _filtered = out);
    }
  }

  // ============================================================
  // NAVIGATE TO COMPANY DETAILS
  // ============================================================
  Future<void> _openCompany(Map<String, dynamic> company) async {
    final companyId = (company['id'] ?? '').toString().trim();
    if (companyId.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyDetailsPage(
          companyId: companyId,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: KhilonjiyaUI.border),
        ),
      ),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search,
                size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: KhilonjiyaUI.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: "Search companies",
                  hintStyle: KhilonjiyaUI.sub.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
                  isDense: true,
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchCtrl.text.trim().isNotEmpty)
              InkWell(
                onTap: () {
                  _searchCtrl.clear();
                  FocusScope.of(context).unfocus();
                },
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 52,
                color: Colors.black.withOpacity(0.35),
              ),
              const SizedBox(height: 14),
              Text(
                "No companies found",
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Try a different search keyword.",
                style: KhilonjiyaUI.sub,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPANY LIST
  // ============================================================
  Widget _list() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final c = _filtered[i];

          return CompanyCard(
            company: c,
            onTap: () => _openCompany(c),
          );
        },
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
            Container(
              padding:
                  const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom:
                      BorderSide(color: KhilonjiyaUI.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon:
                        const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      "Top companies",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon:
                        const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            _searchBar(),

            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : (_filtered.isEmpty
                      ? _empty()
                      : _list()),
            ),
          ],
        ),
      ),
    );
  }
}