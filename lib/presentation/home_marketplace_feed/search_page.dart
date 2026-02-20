import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/search_service.dart';
import '../common/widgets/cards/job_card_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchService _service = SearchService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;

  int _offset = 0;
  static const int _limit = 20;

  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(reset: true);
    });
  }

  Future<void> _search({bool reset = false}) async {
    final keyword = _controller.text.trim();

    if (reset) {
      setState(() {
        _loading = true;
        _offset = 0;
        _results.clear();
        _hasMore = true;
      });
    }

    final data = await _service.searchJobs(
      keyword: keyword,
      limit: _limit,
      offset: _offset,
    );

    if (!mounted) return;

    setState(() {
      if (reset) {
        _results = data;
      } else {
        _results.addAll(data);
      }

      _loading = false;
      _loadingMore = false;
      _offset += data.length;
      if (data.length < _limit) _hasMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() => _loadingMore = true);
    await _search(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _results.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, index) {
                            if (index >= _results.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final job = _results[index];

                            return JobCardWidget(
                              job: job,
                              isSaved: false,
                              onSaveToggle: () {},
                              onTap: () {},
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: KhilonjiyaUI.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Search jobs, skills, district...",
                hintStyle: KhilonjiyaUI.sub,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: KhilonjiyaUI.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: KhilonjiyaUI.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: KhilonjiyaUI.primary.withOpacity(0.6),
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              _search(reset: true);
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.search_rounded,
          size: 46,
          color: Colors.black.withOpacity(0.35),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            "No results found",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            "Try different keywords or check spelling.",
            textAlign: TextAlign.center,
            style: KhilonjiyaUI.sub,
          ),
        ),
      ],
    );
  }
}