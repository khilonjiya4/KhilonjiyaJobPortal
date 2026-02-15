import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/job_seeker_home_service.dart';

import '../common/widgets/cards/company_card.dart';

class TopCompaniesPage extends StatefulWidget {
  const TopCompaniesPage({Key? key}) : super(key: key);

  @override
  State<TopCompaniesPage> createState() => _TopCompaniesPageState();
}

class _TopCompaniesPageState extends State<TopCompaniesPage> {
  final JobSeekerHomeService _service = JobSeekerHomeService();

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = true;
  bool _loadingMore = false;
  bool _disposed = false;

  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;

  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();

    _loadInitial();

    _searchCtrl.addListener(_applySearch);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _disposed = true;

    _searchCtrl.removeListener(_applySearch);
    _scrollCtrl.removeListener(_onScroll);

    _searchCtrl.dispose();
    _scrollCtrl.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD INITIAL
  // ============================================================
  Future<void> _loadInitial() async {
    if (!_disposed) {
      setState(() {
        _loading = true;
        _companies = [];
        _filtered = [];
        _offset = 0;
        _hasMore = true;
      });
    }

    try {
      final list = await _service.fetchTopCompaniesPaginated(
        offset: _offset,
        limit: _limit,
      );

      _companies = list;
      _applySearch(); // also sets _filtered

      _offset += list.length;
      _hasMore = list.length == _limit;
    } catch (_) {
      _companies = [];
      _filtered = [];
      _hasMore = false;
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // ============================================================
  // LOAD MORE
  // ============================================================
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (!_hasMore) return;
    if (_loading) return;

    setState(() => _loadingMore = true);

    try {
      final list = await _service.fetchTopCompaniesPaginated(
        offset: _offset,
        limit: _limit,
      );

      if (list.isNotEmpty) {
        _companies.addAll(list);
      }

      _offset += list.length;
      _hasMore = list.length == _limit;

      _applySearch();
    } catch (_) {
      _hasMore = false;
    }

    if (_disposed) return;
    setState(() => _loadingMore = false);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;

    final pos = _scrollCtrl.position;

    // load when 250px near bottom
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      _loadMore();
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================
  void _applySearch() {
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isEmpty) {
      if (!_disposed) setState(() => _filtered = List.from(_companies));
      return;
    }

    final out = _companies.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();

      // Option A business type
      final bt = c['business_types_master'];
      final businessType = (bt is Map<String, dynamic>)
          ? (bt['type_name'] ?? '').toString().toLowerCase()
          : '';

      return name.contains(q) || businessType.contains(q);
    }).toList();

    if (!_disposed) setState(() => _filtered = out);
  }

  // ============================================================
  // UI
  // ============================================================
  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: KhilonjiyaUI.body.copyWith(fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  hintText: "Search companies",
                  hintStyle: KhilonjiyaUI.sub.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
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

  Widget _list() {
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _filtered.length + 1,
        itemBuilder: (_, i) {
          // last loader
          if (i == _filtered.length) {
            if (_loadingMore) {
              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: KhilonjiyaUI.primary.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }

            if (!_hasMore) {
              return const SizedBox(height: 30);
            }

            return const SizedBox(height: 30);
          }

          final c = _filtered[i];

          return CompanyCard(
            company: c,
            onTap: () {
              // later: open company details page
            },
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
            // TOP BAR
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
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
                    onPressed: _loadInitial,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            _searchBar(),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_filtered.isEmpty ? _empty() : _list()),
            ),
          ],
        ),
      ),
    );
  }
}