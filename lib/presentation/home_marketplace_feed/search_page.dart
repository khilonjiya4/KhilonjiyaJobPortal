import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/search_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchService _service = SearchService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  Timer? _debounce;

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _page = 0;

  List<Map<String, dynamic>> _results = [];
  List<String> _recent = [];
  List<String> _trending = [];

  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scroll.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    _recent = await _service.getRecentSearches();
    _trending = await _service.getTrendingSearches();
    if (!mounted) return;
    setState(() {});
  }

  void _scrollListener() {
    if (_scroll.position.pixels >=
            _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore &&
        _currentQuery.isNotEmpty) {
      _loadMore();
    }
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _startSearch(value.trim());
    });
  }

  Future<void> _startSearch(String query) async {
    _currentQuery = query;
    _page = 0;
    _hasMore = true;
    _results.clear();

    if (query.isEmpty) {
      setState(() {});
      return;
    }

    setState(() => _loading = true);

    final res = await _service.searchJobs(query: query, page: 0);

    _results = res;
    _hasMore = res.length == 20;

    await _service.saveUserSearch(query);
    await _service.incrementTrend(query);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    _loadingMore = true;
    _page++;

    final res =
        await _service.searchJobs(query: _currentQuery, page: _page);

    if (res.isEmpty) {
      _hasMore = false;
    } else {
      _results.addAll(res);
    }

    if (!mounted) return;
    setState(() {
      _loadingMore = false;
    });
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final company = job['companies'] ?? {};
    final title = job['job_title'] ?? '';
    final district = job['district'] ?? '';
    final salaryMin = job['salary_min'] ?? 0;
    final salaryMax = job['salary_max'] ?? 0;
    final companyName = company['name'] ?? '';
    final verified = company['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  companyName,
                  style: KhilonjiyaUI.sub.copyWith(
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              if (verified)
                const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFF16A34A),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$district • ₹$salaryMin - ₹$salaryMax",
            style: KhilonjiyaUI.sub.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(List<String> items) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (e) => GestureDetector(
              onTap: () {
                _controller.text = e;
                _startSearch(e);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Text(
                  e,
                  style: KhilonjiyaUI.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        hintText: "Search jobs, skills...",
                        hintStyle: KhilonjiyaUI.sub,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                          borderSide:
                              BorderSide(color: KhilonjiyaUI.border),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _currentQuery.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_recent.isNotEmpty) ...[
                              Text("Recent searches",
                                  style: KhilonjiyaUI.body.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              _chips(_recent),
                              const SizedBox(height: 20),
                            ],
                            if (_trending.isNotEmpty) ...[
                              Text("Trending",
                                  style: KhilonjiyaUI.body.copyWith(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              _chips(_trending),
                            ],
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: _results.length +
                              (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _results.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _jobCard(_results[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}