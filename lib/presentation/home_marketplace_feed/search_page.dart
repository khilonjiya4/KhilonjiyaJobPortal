import 'dart:async';
import 'package:flutter/material.dart';

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
  List<String> _districts = [];

  String _currentQuery = '';

  String? _selectedDistrict;
  String? _selectedJobType;
  int? _selectedMinSalary;

  @override
  void initState() {
    super.initState();
    _initialize();
    _scroll.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _recent = await _service.getRecentSearches();
    _trending = await _service.getTrendingSearches();
    _districts = await _service.getDistricts();
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
    _debounce =
        Timer(const Duration(milliseconds: 400), () {
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

    final res = await _service.searchJobs(
      query: query,
      page: 0,
      district: _selectedDistrict,
      jobType: _selectedJobType,
      minSalary: _selectedMinSalary,
    );

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

    final res = await _service.searchJobs(
      query: _currentQuery,
      page: _page,
      district: _selectedDistrict,
      jobType: _selectedJobType,
      minSalary: _selectedMinSalary,
    );

    if (res.isEmpty) {
      _hasMore = false;
    } else {
      _results.addAll(res);
    }

    if (!mounted) return;
    setState(() => _loadingMore = false);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        String? district = _selectedDistrict;
        String? jobType = _selectedJobType;
        int? salary = _selectedMinSalary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filters",
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: district,
                    decoration:
                        const InputDecoration(labelText: "District"),
                    items: _districts
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => district = v),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: jobType,
                    decoration:
                        const InputDecoration(labelText: "Job Type"),
                    items: const [
                      DropdownMenuItem(
                          value: "Full-time",
                          child: Text("Full-time")),
                      DropdownMenuItem(
                          value: "Part-time",
                          child: Text("Part-time")),
                      DropdownMenuItem(
                          value: "Internship",
                          child: Text("Internship")),
                      DropdownMenuItem(
                          value: "Contract",
                          child: Text("Contract")),
                    ],
                    onChanged: (v) =>
                        setModalState(() => jobType = v),
                  ),

                  const SizedBox(height: 12),

                  Text("Minimum Salary"),
                  Slider(
                    value: (salary ?? 0).toDouble(),
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    label: salary?.toString(),
                    onChanged: (v) =>
                        setModalState(() => salary = v.toInt()),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDistrict = district;
                          _selectedJobType = jobType;
                          _selectedMinSalary = salary;
                        });
                        Navigator.pop(context);
                        if (_currentQuery.isNotEmpty) {
                          _startSearch(_currentQuery);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KhilonjiyaUI.primary,
                        elevation: 0,
                      ),
                      child: const Text("Apply Filters"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _salaryFormat(int min, int max) {
    if (min <= 0 && max <= 0) return "Salary not disclosed";
    return "₹$min - ₹$max";
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final company = job['companies'] ?? {};
    final verified = company['is_verified'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job['job_title'] ?? '',
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  company['name'] ?? '',
                  style: KhilonjiyaUI.sub.copyWith(
                    fontWeight: FontWeight.w500,
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
            "${job['district'] ?? ''} • ${_salaryFormat(job['salary_min'] ?? 0, job['salary_max'] ?? 0)}",
            style: KhilonjiyaUI.sub,
          ),
        ],
      ),
    );
  }

  Widget _chips(String title, List<String> items) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: KhilonjiyaUI.body.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
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
                      border:
                          Border.all(color: KhilonjiyaUI.border),
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
        ),
        const SizedBox(height: 22),
      ],
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
              padding:
                  const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                        Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        hintText:
                            "Search jobs, companies, skills...",
                        hintStyle:
                            KhilonjiyaUI.sub,
                        filled: true,
                        fillColor:
                            const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  18),
                          borderSide: BorderSide(
                              color:
                                  KhilonjiyaUI.border),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.tune_rounded),
                    onPressed: _openFilters,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator())
                  : _currentQuery.isEmpty
                      ? ListView(
                          padding:
                              const EdgeInsets.all(16),
                          children: [
                            _chips(
                                "Recent Searches",
                                _recent),
                            _chips("Trending",
                                _trending),
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding:
                              const EdgeInsets.all(16),
                          itemCount: _results.length +
                              (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _results.length) {
                              return const Padding(
                                padding:
                                    EdgeInsets.all(16),
                                child: Center(
                                  child:
                                      CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _jobCard(
                                _results[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}